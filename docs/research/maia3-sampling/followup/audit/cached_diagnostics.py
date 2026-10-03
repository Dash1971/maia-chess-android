#!/usr/bin/env python3
"""Cached paired T1/P.95 versus T1/P1 evaluation diagnostic and opening-cutoff audit."""
import collections, csv, hashlib, json, platform, sys
from pathlib import Path
import numpy as np
HERE=Path(__file__).resolve().parent
OLD=HERE.parents[1]/'sampling-research-20261002'
P=.95
SEED=2026100301
REPLICATES=10000

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def write(name,value):(HERE/name).write_text(json.dumps(value,indent=2)+'\n')
def nucleus(q,inclusive=True):
    ordered=sorted(q,key=lambda move:-q[move]);cumulative=np.cumsum([q[m]for m in ordered])
    n=int(np.searchsorted(cumulative,P,side='left'))+1 if inclusive else max(1,int(np.sum(cumulative<=P)))
    moves=ordered[:n];mass=sum(q[m]for m in moves)
    return {m:q[m]/mass for m in moves},1-mass

def tv(p,q):return .5*sum(abs(p.get(k,0)-q.get(k,0))for k in set(p)|set(q))
def entropy(q):return -sum(p*np.log2(p)for p in q.values()if p>0)
def eval_metrics(q,scores):
    best=max(v['cp']for v in scores.values());loss={m:max(0,best-v['cp'])for m,v in scores.items()}
    return {'support':len(q),'entropy_bits':entropy(q),
            'expected_cp_loss':sum(p*loss[m]for m,p in q.items()),
            'expected_cp_loss_capped1000':sum(p*min(1000,loss[m])for m,p in q.items()),
            'prob_loss_gt100':sum(p for m,p in q.items()if loss[m]>100),
            'prob_loss_gt200':sum(p for m,p in q.items()if loss[m]>200)},loss

def paired_summary(rows):
    strata=collections.defaultdict(list)
    for r in rows:strata[r['pair'],r['ply']].append(r)
    fields=list(rows[0]['full']);extra=list(rows[0]['removed'])
    means={profile:{field:float(np.mean([np.mean([r[profile][field]for r in bucket])for bucket in strata.values()]))for field in fields}for profile in ('full','p95')}
    removed={field:float(np.mean([np.mean([r['removed'][field]for r in bucket])for bucket in strata.values()]))for field in extra}
    deltas={k:np.array([[r['p95'][field]-r['full'][field]for field in fields]+[r['removed'][field]for field in extra]for r in bucket])for k,bucket in strata.items()}
    means_delta=np.mean([np.mean(d,axis=0)for d in deltas.values()],axis=0)
    contributing={pair:sorted({r['game_id']for r in rows if r['pair']==pair})for pair in range(3)}
    rng=np.random.default_rng(SEED);replicates=[]
    for _ in range(REPLICATES):
        counts={pair:collections.Counter(rng.choice(games,len(games),replace=True))for pair,games in contributing.items()};values=[]
        for (pair,ply),bucket in strata.items():
            weights=np.array([counts[pair][r['game_id']]for r in bucket])
            if weights.sum():values.append(np.dot(weights,deltas[pair,ply])/weights.sum())
        if len(values)==len(strata):replicates.append(np.mean(values,axis=0))
    reps=np.array(replicates)
    return {'positions':len(rows),'strata':{f'pair{k[0]}_ply{k[1]}':len(v)for k,v in strata.items()},'means':means,
            'p95_minus_full':{field:{'mean':float(means_delta[i]),'game_cluster95_ci':[float(x)for x in np.quantile(reps[:,i],[.025,.975])]}for i,field in enumerate(fields)},
            'removed_full_policy_mass':removed,
            'removed_mass_game_cluster95_ci':{field:[float(x)for x in np.quantile(reps[:,len(fields)+i],[.025,.975])]for i,field in enumerate(extra)},
            'position_direction_counts':{field:{'p95_lower':sum(r['p95'][field]<r['full'][field]-1e-12 for r in rows),'p95_higher':sum(r['p95'][field]>r['full'][field]+1e-12 for r in rows),'equal_within1e12':sum(abs(r['p95'][field]-r['full'][field])<=1e-12 for r in rows)}for field in ('expected_cp_loss_capped1000','prob_loss_gt100','prob_loss_gt200')},
            'fraction_removed_mass_with_loss_gt100':removed['full_mass_loss_gt100_removed']/removed['model_probability_mass_removed'],
            'fraction_removed_mass_with_loss_gt200':removed['full_mass_loss_gt200_removed']/removed['model_probability_mass_removed'],
            'bootstrap_valid_replicates':len(reps)}

raw=[json.loads(x)for x in(OLD/'diagnostics/raw.jsonl').read_text().splitlines()]
original={(r['position_id'],int(r['depth']),r['profile']):r for r in csv.DictReader((OLD/'diagnostics/metrics.csv').open())}
rows=[]
for record in raw:
    item=record['position'];values=record['legal_logits'];peak=max(values.values());q={m:float(np.exp(v-peak))for m,v in values.items()};z=sum(q.values());q={m:p/z for m,p in q.items()}
    nq,mass_removed=nucleus(q)
    full,loss=eval_metrics(q,record['evaluations']);narrow,_=eval_metrics(nq,record['evaluations'])
    for name,computed in [('T1_P1',full),('T1_P0.95',narrow)]:
        old=original[item['id'],record['depth'],name]
        assert all(abs(float(old[field])-value)<1e-10 for field,value in computed.items())
    removed={'model_probability_mass_removed':mass_removed,
             'full_mass_loss_gt100_removed':sum(p for m,p in q.items()if m not in nq and loss[m]>100),
             'full_mass_loss_gt200_removed':sum(p for m,p in q.items()if m not in nq and loss[m]>200),
             'full_mass_loss_le100_removed':sum(p for m,p in q.items()if m not in nq and loss[m]<=100)}
    rows.append({'id':item['id'],'pair':item['pair'],'ply':item['ply'],'game_id':item['game_id'],'fen':item['fen'],'depth':record['depth'],
                 'full':full,'p95':narrow,'removed':removed,'full_distribution':q,'p95_distribution':nq})
with(HERE/'position-metrics.jsonl').open('w')as f:
    for row in rows:f.write(json.dumps(row,separators=(',',':'))+'\n')
summary={'comparison':'Temperature1, TopP.95 inclusive crossing move versus Temperature1, TopP1',
         'method':'exact expected evaluation gaps on same frozen positions; equal source-pair/ply stratum means; paired game-cluster bootstrap within each sourcepair; cached Stockfish18 alllegal MultiPV at depths10/14; mates mapped±10000cp, individual losses capped1000cp sensitivity',
         'bootstrap_seed':SEED,'bootstrap_replicates':REPLICATES,
         'depths':{str(depth):paired_summary([r for r in rows if r['depth']==depth])for depth in (10,14)}}
write('diagnostic-summary.json',summary)

bookrows=json.loads((OLD/'openings/conditional.json').read_text())
opening=[]
for r in bookrows:
    q=r['settings']['full']['distribution'];inclusive,removed=nucleus(q);exclusive,exremoved=nucleus(q,False);h=r['human']
    stats={'tv_full':tv(q,h),'tv_p95_inclusive':tv(inclusive,h),'tv_p95_upstream':tv(exclusive,h),
           'inclusive_minus_full_tv':tv(inclusive,h)-tv(q,h),'upstream_minus_inclusive_tv':tv(exclusive,h)-tv(inclusive,h),
           'sampler_tv_inclusive_upstream':tv(inclusive,exclusive),'different_cutoff':float(set(inclusive)!=set(exclusive)),
           'inclusive_model_mass_removed':removed,'upstream_model_mass_removed':exremoved,
           'inclusive_human_mass_removed':sum(p for m,p in h.items()if m not in inclusive),
           'upstream_human_mass_removed':sum(p for m,p in h.items()if m not in exclusive),
           'inclusive_entropy_bits':entropy(inclusive),'upstream_entropy_bits':entropy(exclusive),'full_entropy_bits':entropy(q)}
    opening.append({'book':r['book'],'trajectory':r['trajectory'],'ply':r['ply'],'fen':r['fen'],'metrics':stats,
                    'inclusive_distribution':inclusive,'upstream_distribution':exclusive})
with(HERE/'opening-cutoff-rows.jsonl').open('w')as f:
    for row in opening:f.write(json.dumps(row,separators=(',',':'))+'\n')
books={};first={}
for name in dict.fromkeys(r['book']for r in opening):
    batch=[r for r in opening if r['book']==name];fields=list(batch[0]['metrics']);buckets=collections.defaultdict(list)
    for r in batch:buckets[r['trajectory']].append(r)
    totals=np.array([[sum(r['metrics'][field]for r in bucket)for field in fields]for bucket in buckets.values()]);lengths=np.array([len(bucket)for bucket in buckets.values()]);rng=np.random.default_rng(SEED)
    indexes=rng.integers(0,len(buckets),(2000,len(buckets)));reps=totals[indexes].sum(axis=1)/lengths[indexes].sum(axis=1)[:,None]
    books[name]={'observations':len(batch),'trajectories':len(buckets),
                 'means':{field:float(np.mean([r['metrics'][field]for r in batch]))for field in fields},
                 'trajectory95_ci':{field:[float(x)for x in np.quantile(reps[:,i],[.025,.975])]for i,field in enumerate(fields)},
                 'coverage_at_ply15':sum(r['ply']==15 for r in batch)/len(buckets)}
    initial=next(r for r in batch if r['ply']==0);source=next(r for r in bookrows if r['book']==name and r['ply']==0)
    first[name]={'full_distribution':source['settings']['full']['distribution'],
                 'inclusive_distribution':initial['inclusive_distribution'],'upstream_distribution':initial['upstream_distribution'],
                 'human_distribution':source['human'],'metrics':initial['metrics']}
write('opening-cutoff-summary.json',{'temperature':1,'top_p':P,'method':'same4581 cached human-book observations; observation-weighted means and2000 whole-trajectory bootstrapreplicates, fixed frozen reference; no newinference; inclusive contains threshold crossing move, upstream cumulative<=P plusfirstfallback','bootstrap_seed':SEED,'books':books,'first_position':first})
write('manifest.json',{'cached_only':True,'source_files':{str(path.relative_to(OLD)):sha(path)for path in [OLD/'diagnostics/raw.jsonl',OLD/'diagnostics/metrics.csv',OLD/'openings/conditional.json']},'script_sha256':sha(Path(__file__)),'python':sys.version,'platform':platform.platform(),'numpy':np.__version__,'temperature':1,'top_p_narrow':P,'top_p_reference':1,'diagnostic_requests':len(rows),'depth10_positions':sum(r['depth']==10 for r in rows),'opening_observations':len(opening)})
print(json.dumps({'diagnostic':summary['depths']['10'],'opening':{name:v['means']for name,v in books.items()}},indent=2))
