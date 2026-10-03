"""Exact human-prefix and independent-sample rollout comparisons for p95."""
import argparse,collections,json,time
from pathlib import Path
import numpy as np
import chess
from conditional import HERE,metrics
from mobile_policy import sha256
SEED=7000004000

def cohorts(human):
    return {'mean1550-1650_blitz':[r for r in human if 1550<=r['mean_elo']<=1650 and r['speed']=='blitz'],
            'mean1550-1650_rapid':[r for r in human if 1550<=r['mean_elo']<=1650 and r['speed']=='rapid'],
            'mean1500-1700_combined':[r for r in human if 1500<=r['mean_elo']<=1700],
            'september2025_mean1500-1700':[r for r in human if 1500<=r['mean_elo']<=1700 and r['date'].startswith('2025-09')]}

def category(r,depth,kind):
    if len(r['moves'])<depth:return None
    return ' '.join(r['moves'][:depth]) if kind=='prefix' else r['labels'][depth-1][kind]

def counts(rows,depth,kind):
    return collections.Counter(k for r in rows if (k:=category(r,depth,kind)) is not None)

def human_boot(rows,depth,kind,keys,bins,rng,nboot):
    blocks=collections.defaultdict(collections.Counter)
    for r in rows:
        k=category(r,depth,kind)
        if k is not None:blocks[r['source_group']][k if bins is None or k in bins else 'OTHER']+=1
    matrix=np.array([[v.get(k,0) for k in keys] for v in blocks.values()]);ids=rng.integers(0,len(matrix),(nboot,len(matrix)))
    samples=matrix[ids].sum(1);return samples/samples.sum(1)[:,None],len(matrix)

def interval(v):return [float(x) for x in np.quantile(v,[.025,.975])]

def actual_two_ply(human):
    exact=json.loads((HERE/'exact-policy95.json').read_text());model=next(iter(exact.values()))['two_ply'];out={}
    for gi,(name,rows) in enumerate(cohorts(human).items()):
        c=counts(rows,2,'prefix');p={k:v/sum(c.values()) for k,v in c.items()};keys=sorted(set(p)|set(model['full']))
        rng=np.random.default_rng(SEED+gi);hs,blocks=human_boot(rows,2,'prefix',keys,None,rng,2000);settings={};tvs={}
        for setting in ('full','full95'):
            q=model[setting];v=np.array([q.get(k,0) for k in keys]);tv=abs(hs-v).sum(1)/2;tvs[setting]=tv
            settings[setting]={**metrics(p,q),'tv_ci95':interval(tv)}
        out[name]={'games':sum(c.values()),'source_blocks':blocks,'human':p,'settings':settings,
                   'p95_minus_full_tv':{'mean':settings['full95']['tv']-settings['full']['tv'],'ci95':interval(tvs['full95']-tvs['full'])},
                   'model_sampling':'exact model probabilities; no model Monte Carlo'}
    return out

def rollout_comparisons(human,rollouts):
    out={};repertoire={}
    for gi,(name,hrows) in enumerate(cohorts(human).items()):
        out[name]={'games':len(hrows),'comparisons':{}}
        for oi,(depth,kind) in enumerate(((1,'prefix'),(2,'prefix'),(4,'prefix'),(8,'family'),(12,'family'),(16,'family'),(12,'eco'))):
            hc=counts(hrows,depth,kind);hn=sum(hc.values());bins={k for k,v in hc.items() if v/hn>=.005}
            def coarsen(c):
                z=collections.Counter()
                for k,v in c.items():z[k if k in bins else 'OTHER']+=v
                return z
            h=coarsen(hc);ms={s:coarsen(counts(rs,depth,kind)) for s,rs in rollouts.items()}
            keys=sorted(set(h)|set().union(*(set(z) for z in ms.values())))
            p={k:h.get(k,0)/hn for k in keys};rng=np.random.default_rng(SEED+100+gi*20+oi)
            hs,blocks=human_boot(hrows,depth,kind,keys,bins,rng,1000);settings={};boot={}
            for setting in ('app_default','full','full95'):
                c=ms[setting];n=sum(c.values());q={k:c.get(k,0)/n for k in keys}
                # The historical full and new p95 samples are independently resampled, not paired games.
                samples=rng.multinomial(n,np.array([q[k] for k in keys]),size=1000)/n
                tv=abs(hs-samples).sum(1)/2;boot[setting]=tv
                settings[setting]={**metrics(p,q),'tv_ci95':interval(tv),'human_n':hn,'model_n':n,'human':p,'model':q,'bins':len(bins)+1}
            delta=boot['full95']-boot['full'];denom=boot['app_default']-boot['full'];ratio=(boot['app_default']-boot['full95'])/denom
            out[name]['comparisons'][f'{depth}ply_{kind}']={'settings':settings,'source_blocks':blocks,
                'p95_minus_full_tv':{'mean':settings['full95']['tv']-settings['full']['tv'],'ci95':interval(delta)},
                'old_default_improvement_retained':{'ratio_of_mean_improvements':(settings['app_default']['tv']-settings['full95']['tv'])/(settings['app_default']['tv']-settings['full']['tv']),'ci95':interval(ratio)}}
    for setting,rs in rollouts.items():
        fam=counts(rs,12,'family');repertoire[setting]={'games':len(rs),'survivors_by_ply':{str(p):sum(len(r['moves'])>=p for r in rs) for p in (2,4,8,12,16)},
           'distinct_prefixes':{str(p):len(counts(rs,p,'prefix')) for p in (2,4,8,12,16)},
           'book_membership_by_ply':{str(p):sum(len(r['book_covered'])>p and r['book_covered'][p] for r in rs)/len(rs) for p in range(16)},
           'effective_families_12ply':2**metrics({}, {k:v/sum(fam.values()) for k,v in fam.items()})['model_entropy_bits']}
    return {'cohorts':out,'repertoire':repertoire}

def validate_rollouts(rows):
    n=0;start=time.time()
    assert len(rows)==2000 and len({r['index'] for r in rows})==2000
    for r in rows:
        assert r['seed']==7000000000+r['index'];b=chess.Board()
        assert len(r['moves'])==len(r['labels'])==len(r['book_covered'])
        for move,label in zip(r['moves'],r['labels']):
            m=chess.Move.from_uci(move);assert m in b.legal_moves;b.push(m);n+=1
            assert label['fen']==' '.join(b.fen().split()[:4])
    return {'status':'passed','games':len(rows),'legal_plies_replayed':n,'label_fen_checks':n,'seconds':time.time()-start}

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--source-study',type=Path,required=True);ap.add_argument('--exact-only',action='store_true');args=ap.parse_args();source=args.source_study.resolve()
    humanfile=source/'openings/human-sample.json';human=json.loads(humanfile.read_text())
    actual=actual_two_ply(human);(HERE/'actual-two-ply95.json').write_text(json.dumps(actual,indent=2))
    if args.exact_only:
        for name,d in actual.items():print(name,json.dumps({k:d[k] for k in ('games','p95_minus_full_tv')}))
        return
    run=json.loads((HERE/'run.json').read_text());assert run['status']=='complete' and run['completed']==2000
    new=json.loads((HERE/'rollouts95.json').read_text());oldfile=source/'openings/rollouts.json';old=json.loads(oldfile.read_text());validation=validate_rollouts(new)
    (HERE/'rollout-validation95.json').write_text(json.dumps(validation,indent=2))
    rs={s:[r for r in old if r['setting']==s] for s in ('full','app_default')};rs['full95']=new
    assert len(rs['full'])==len(rs['app_default'])==2000
    summary={'status':'complete','run':run,'references':'Historical full/default samples reused; not paired games or new independent data.',
             'bootstrap_seed':SEED,'human_sha256':sha256(humanfile),'old_rollout_sha256':sha256(oldfile),'analysis_source_sha256':sha256(Path(__file__)),
             'conditional':json.loads((HERE/'conditional-summary95.json').read_text()),'actual_two_ply':actual,'rollout':rollout_comparisons(human,rs),'validation':validation}
    (HERE/'summary95.json').write_text(json.dumps(summary,indent=2));print('COMPLETE',json.dumps(validation))

if __name__=='__main__':main()
