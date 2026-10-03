#!/usr/bin/env python3
"""Secondary cached-data sensitivity: best root evaluation is nonmate and within ±300cp."""
import collections, csv, json
from pathlib import Path
import numpy as np
HERE=Path(__file__).resolve().parent
raw=[json.loads(line) for line in (HERE/'raw.jsonl').read_text().splitlines()]
selected=[]
for record in raw:
    best=max(record['evaluations'].values(),key=lambda e:e['cp'])
    if record['depth']==10 and best['mate'] is None and -300<=best['cp']<=300:
        selected.append(record['position']['id'])
ids=set(selected)
rows=[]
for row in csv.DictReader((HERE/'metrics.csv').open()):
    if int(row['depth'])!=10 or row['position_id'] not in ids:continue
    for key in ('pair','ply','depth'):row[key]=int(row[key])
    for key in ('support','entropy_bits','expected_cp_loss','expected_cp_loss_capped1000','prob_loss_gt100','prob_loss_gt200','prob_best_cp','prob_selected_mate_score'):row[key]=float(row[key])
    rows.append(row)
fields=('support','entropy_bits','expected_cp_loss','expected_cp_loss_capped1000','prob_loss_gt100','prob_loss_gt200','prob_best_cp','prob_selected_mate_score')
delta_fields=('expected_cp_loss','expected_cp_loss_capped1000','prob_loss_gt100','prob_loss_gt200')
baseline={r['position_id']:r for r in rows if r['profile']=='T0.5_P0.9'}
strata_counts=collections.Counter((r['pair'],r['ply']) for r in baseline.values())
assert len(strata_counts)==18
summary={'selection':'secondary sensitivity requested after main cohort results: retain depth10 records whose best root evaluation is nonmate and within inclusive [-300,+300]cp from side-to-move perspective; no new Stockfish evaluations; outcome-independent rule applied to all policies on same positions', 'n_positions':len(ids),'coverage_of_main_cohort':len(ids)/453,'position_ids':selected,'strata_counts':{f'pair{pair}_ply{ply}':n for (pair,ply),n in sorted(strata_counts.items())},'weighting':'equal weight to each of eighteen source-pair / fixed-ply strata; game-cluster paired bootstrap within source pair, 2000 attempts; reject replicates emptying any stratum','profiles':{}}
for name in dict.fromkeys(r['profile'] for r in rows):
    batch=[r for r in rows if r['profile']==name]
    strata=collections.defaultdict(list)
    for r in batch:strata[r['pair'],r['ply']].append(r)
    means={field:float(np.mean([np.mean([r[field] for r in bucket]) for bucket in strata.values()])) for field in fields}
    deltas={key:np.array([[r[field]-baseline[r['position_id']][field] for field in delta_fields] for r in bucket]) for key,bucket in strata.items()}
    contributing={pair:sorted(set(r['source_game_id'] for r in batch if r['pair']==pair)) for pair in range(3)}
    rng=np.random.default_rng(20261002);replicates=[]
    for _ in range(2000):
        counts={pair:collections.Counter(rng.choice(games,len(games),replace=True)) for pair,games in contributing.items()};values=[]
        for (pair,ply),bucket in strata.items():
            weights=np.array([counts[pair][r['source_game_id']] for r in bucket])
            if weights.sum():values.append(np.dot(weights,deltas[pair,ply])/weights.sum())
        if len(values)==18:replicates.append(np.mean(values,axis=0))
    reps=np.array(replicates);mean_delta=np.mean([np.mean(x,axis=0) for x in deltas.values()],axis=0)
    summary['profiles'][name]={'equal_stratum_means':means,'paired_differences':{field:{'mean':float(mean_delta[i]),'bootstrap95':[float(x) for x in np.quantile(reps[:,i],[.025,.975])]} for i,field in enumerate(delta_fields)},'bootstrap_valid_replicates':len(replicates)}
(HERE/'summary_close_positions.json').write_text(json.dumps(summary,indent=2)+'\n')
for name in ('argmax','T0.5_P0.9','T1_P1'):
    print(name,json.dumps(summary['profiles'][name]))
print('positions',len(ids),'coverage',len(ids)/453)
