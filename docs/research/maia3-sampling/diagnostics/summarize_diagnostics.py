#!/usr/bin/env python3
"""Equal-stratum summaries, game-cluster bootstrap, and mate-score sensitivity."""
import collections, csv, json
from pathlib import Path
import numpy as np, chess
from run_diagnostics import HERE, GRID, metrics, distribution, move_index

def main():
    raw=[json.loads(x) for x in (HERE/'raw.jsonl').read_text().splitlines()]
    items=json.loads((HERE/'positions.json').read_text())
    expected=len(items)+36
    assert len(raw)==expected,(len(raw),expected)
    rows=[]
    for record in raw:
        item=record['position'];board=chess.Board(item['fen']);logits=np.full(4352,-np.inf,np.float64)
        for uci,value in record['legal_logits'].items():logits[move_index(chess.Move.from_uci(uci),board.turn==chess.BLACK)]=value
        batch=metrics(item,logits,record['evaluations'],record['depth'])
        best=max(x['cp'] for x in record['evaluations'].values())
        for row in batch:
            moves,probs=distribution(board,logits,row['top_p'],row['temperature'])
            losses=np.array([max(0,best-record['evaluations'][m.uci()]['cp']) for m in moves])
            row['expected_cp_loss_capped1000']=float(np.dot(probs,np.minimum(losses,1000)))
            row['prob_selected_mate_score']=float(sum(p for m,p in zip(moves,probs) if record['evaluations'][m.uci()]['mate'] is not None))
            row['source_game_id']=item['game_id'];rows.append(row)
    fields=('support','entropy_bits','expected_cp_loss','expected_cp_loss_capped1000','prob_loss_gt100','prob_loss_gt200','prob_best_cp','prob_selected_mate_score')
    summary={'method':'equal weight for each of eighteen source-pair / fixed-ply strata; paired differences; resample contributing games from the original first30 independently within each sourcepair, retaining their sampled positions; 2000 bootstrap replicates; refinement uses its own contributing game clusters','strata_counts':{f'pair{pair}_ply{ply}':sum(x['pair']==pair and x['ply']==ply for x in items) for pair in range(3) for ply in (24,25,40,41,60,61)},'depths':{}}
    for depth in sorted(set(r['depth'] for r in rows)):
        summary['depths'][str(depth)]={}
        for name,_,_ in GRID:
            batch=[r for r in rows if r['depth']==depth and r['profile']==name]
            if not batch:continue
            strata=collections.defaultdict(list)
            for r in batch:strata[r['pair'],r['ply']].append(r)
            means={k:float(np.mean([np.mean([r[k] for r in bucket]) for bucket in strata.values()])) for k in fields}
            baseline={r['position_id']:r for r in rows if r['depth']==depth and r['profile']=='T0.5_P0.9'}
            delta_fields=('expected_cp_loss','expected_cp_loss_capped1000','prob_loss_gt100','prob_loss_gt200')
            deltas={key:np.array([[r[field]-baseline[r['position_id']][field] for field in delta_fields] for r in bucket]) for key,bucket in strata.items()}
            rng=np.random.default_rng(20261002);replicates=[]
            # The depth14 set intentionally covers two selected positions per stratum.
            # A game-cluster bootstrap of only those selected contributors is more informative than resampling unobserved games.
            contributing={pair:sorted(set(r['source_game_id'] for r in batch if r['pair']==pair)) for pair in range(3)}
            for _ in range(2000):
                counts={pair:collections.Counter(rng.choice(ids,len(ids),replace=True)) for pair,ids in contributing.items()}
                values=[]
                for (pair,ply),bucket in strata.items():
                    weights=np.array([counts[pair][r['source_game_id']] for r in bucket]);d=deltas[pair,ply]
                    if weights.sum():values.append(np.dot(weights,d)/weights.sum())
                if len(values)==len(strata):replicates.append(np.mean(values,axis=0))
            reps=np.array(replicates);mean_delta=np.mean([np.mean(x,axis=0) for x in deltas.values()],axis=0)
            summary['depths'][str(depth)][name]={'n_positions':len(batch),'equal_stratum_means':means,'cp_loss_delta_vs_baseline':float(mean_delta[0]),'capped1000_cp_loss_delta_vs_baseline':float(mean_delta[1]),'game_cluster_bootstrap95_delta':[float(x) for x in np.quantile(reps[:,0],[.025,.975])],'paired_differences':{field:{'mean':float(mean_delta[i]),'bootstrap95':[float(x) for x in np.quantile(reps[:,i],[.025,.975])]} for i,field in enumerate(delta_fields)},'bootstrap_valid_replicates':len(replicates)}
    (HERE/'summary_balanced.json').write_text(json.dumps(summary,indent=2)+'\n')
    with (HERE/'metrics.csv').open('w') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    print(json.dumps(summary,indent=2))

if __name__=='__main__':main()
