#!/usr/bin/env python3
"""Color-stratified score bootstrap and descriptive logistic Elo differences."""
import argparse,collections,json,math
from pathlib import Path
import numpy as np
from scipy.stats import binomtest

def elo(s):
 if s<=0:return float('-inf')
 if s>=1:return float('inf')
 return 400*math.log10(s/(1-s))

def summarize(rows,bootstraps,rng):
 scores=np.array([r['score_first'] for r in rows]);score=float(scores.mean());groups=[];counts=collections.Counter(scores)
 for white in [True,False]:
  sub=np.array([r['score_first'] for r in rows if (r['white']==r['first'])==white]);c=np.array([(sub==v).sum() for v in [0,.5,1]])
  draws=rng.multinomial(len(sub),c/c.sum(),size=bootstraps)
  groups.append((draws[:,1]*.5+draws[:,2])/len(sub))
 simulated=(groups[0]+groups[1])*.5;low,high=np.quantile(simulated,[.025,.975]);w=int(counts[1.]);d=int(counts[.5]);l=int(counts[0.])
 return {'first':rows[0]['first'],'second':rows[0]['second'],'n':len(rows),'white_first_n':sum(r['white']==r['first'] for r in rows),'black_first_n':sum(r['black']==r['first'] for r in rows),'wins':w,'draws':d,'losses':l,'score':score,'score_95_ci':[float(low),float(high)],'elo_difference':elo(score),'elo_difference_95_ci':[elo(float(low)),elo(float(high))],'two_sided_decisive_binomial_p':float(binomtest(w,w+l,.5).pvalue) if w+l else 1.,'white_first_score':float(np.mean([r['score_first'] for r in rows if r['white']==r['first']])),'black_first_score':float(np.mean([r['score_first'] for r in rows if r['black']==r['first']])),'terminations':dict(collections.Counter(r['termination'] for r in rows)),'unique_movetexts':len(set(r['movetext_sha256'] for r in rows)),'mean_plies':float(np.mean([r['plies'] for r in rows])),'median_plies':float(np.median([r['plies'] for r in rows])),'max_plies':max(r['plies'] for r in rows),'min_plies':min(r['plies'] for r in rows)}

def main():
 ap=argparse.ArgumentParser();ap.add_argument('inputs',nargs='+',type=Path);ap.add_argument('--output',required=True,type=Path);ap.add_argument('--bootstraps',type=int,default=100000);args=ap.parse_args();rows=[]
 for path in args.inputs:
  rows.extend(json.loads(line) for line in path.read_text().splitlines())
 ids=[r['id'] for r in rows];assert len(set(ids))==len(ids),'duplicate ids'
 grouped=collections.defaultdict(list)
 for r in rows:grouped[r['pair_index']].append(r)
 rng=np.random.default_rng(2026100201);pairs=[summarize(v,args.bootstraps,rng) for k,v in sorted(grouped.items())]
 # Holm adjust three pairwise tests; descriptive tests assume independent stochastic streams.
 order=sorted(range(len(pairs)),key=lambda i:pairs[i]['two_sided_decisive_binomial_p']);previous=0
 for rank,i in enumerate(order):
  adjusted=min(1.,max(previous,(len(pairs)-rank)*pairs[i]['two_sided_decisive_binomial_p']));pairs[i]['holm_adjusted_p']=adjusted;previous=adjusted
 standings={}
 for name in sorted(set(r['first'] for r in rows)|set(r['second'] for r in rows)):
  selected=[(r,r['score_first'] if r['first']==name else 1-r['score_first']) for r in rows if name in [r['first'],r['second']]]
  scores=np.array([s for r,s in selected]);standings[name]={'n':len(scores),'wins':int((scores==1).sum()),'draws':int((scores==.5).sum()),'losses':int((scores==0).sum()),'score':float(scores.mean())}
 report={'games':len(rows),'bootstrap_replicates':args.bootstraps,'bootstrap_seed':2026100201,'method':'Resample game scores within each matchup and first-profile color (multinomial equivalent of bootstrap); equally weight colors; transform score using 400*log10(s/(1-s)). CIs marginal 95%; p tests conditional on decisive games, Holm adjusted across 3. Elo is descriptive relative match performance, not human Elo.','pairs':pairs,'standings':standings,'termination_counts':dict(collections.Counter(r['termination'] for r in rows)),'total_game_seconds':sum(r['seconds'] for r in rows),'max_ply_sensitivity':{}}
 for index,v in sorted(grouped.items()):
  caps=[r for r in v if r['termination']=='max_plies'];remaining=[r for r in v if r['termination']!='max_plies']
  report['max_ply_sensitivity'][str(index)]={'cap_games':len(caps),'score_excluding_caps':float(np.mean([r['score_first'] for r in remaining])) if remaining else None,'cap_as_first_win_score':float(np.mean([r['score_first'] if r['termination']!='max_plies' else 1. for r in v])),'cap_as_first_loss_score':float(np.mean([r['score_first'] if r['termination']!='max_plies' else 0. for r in v]))}
 args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
