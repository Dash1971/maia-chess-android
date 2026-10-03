#!/usr/bin/env python3
"""Matched-position Stockfish diagnostic: sampling controls separately, never Elo."""
import argparse, collections, hashlib, json, math, platform, sys, time
from pathlib import Path
import chess, chess.engine, numpy as np

HERE=Path(__file__).resolve().parent
STRENGTH=HERE.parent/'strength'
sys.path.insert(0,str(STRENGTH))
from mobile_policy import Policy, MODEL79, distribution, move_index, sha256

PLIES=(24,40,60)
GRID=[('argmax',0.,0.)]+[(f'T{t:g}_P{p:g}',t,p) for t in (.5,.9,1.) for p in (.5,.9,.95,1.)]

def select_positions():
    groups={}; snapshots={}
    for pair in range(3):
        path=STRENGTH/f'79m-pair{pair}'/'games.jsonl'
        rows=sorted([json.loads(x) for x in path.read_text().splitlines()],key=lambda r:r['number'])[:30]
        if len(rows)<30: raise RuntimeError(f'Need first 30 completed games for pair {pair}; currently {len(rows)}')
        snapshot='\n'.join(json.dumps(r,sort_keys=True) for r in rows)+'\n'
        snapshots[str(pair)]={'first_30_games_sha256':hashlib.sha256(snapshot.encode()).hexdigest(),'games':rows}
        for ply in PLIES:
            items=[]
            for row in rows:
                if len(row['moves_uci'])<=ply: continue
                board=chess.Board()
                for uci in row['moves_uci'][:ply]: board.push_uci(uci)
                if board.is_game_over(claim_draw=True): continue
                items.append({'pair':pair,'game_id':row['id'],'game_number':row['number'],'ply':ply,'fen':board.fen(),'source_white':row['white'],'source_black':row['black']})
            groups[pair,ply]=items
    # Round-robin source/ply strata so dedup priority is not one whole source.
    selected=[]; seen=set()
    while any(groups.values()):
        for key in groups:
            if not groups[key]: continue
            item=groups[key].pop(0);identity=' '.join(item['fen'].split()[:4])
            if identity in seen:continue
            seen.add(identity);item['id']=f'pos-{len(selected):03d}';selected.append(item)
    return selected,snapshots

def analyse(engine, item, depth):
    board=chess.Board(item['fen']);legal=list(board.legal_moves)
    infos=engine.analyse(board,chess.engine.Limit(depth=depth),multipv=len(legal),game=(item['id'],depth))
    output={}
    for info in infos:
        move=info['pv'][0];score=info['score'].pov(board.turn)
        output[move.uci()]={'cp':score.score(mate_score=10000),'mate':score.mate(),'depth':info.get('depth'),'seldepth':info.get('seldepth'),'nodes':info.get('nodes'),'time':info.get('time'),'pv_uci':[m.uci() for m in info['pv']]}
    assert set(output)==set(m.uci() for m in legal),(item['id'],len(output),len(legal))
    return output

def metrics(item, logits, scores, depth):
    board=chess.Board(item['fen']);best=max(s['cp'] for s in scores.values());output=[]
    for name,t,p in GRID:
        moves,probs=distribution(board,logits,top_p=p,temperature=t)
        losses=np.array([max(0,best-scores[m.uci()]['cp']) for m in moves],np.float64)
        entropy=float(-np.sum(probs*np.log2(probs)))
        output.append({'position_id':item['id'],'pair':item['pair'],'ply':item['ply'],'depth':depth,'profile':name,'temperature':t,'top_p':p,'legal_moves':len(list(board.legal_moves)),'support':len(moves),'entropy_bits':entropy,'expected_cp_loss':float(np.dot(probs,losses)),'prob_loss_gt100':float(probs[losses>100].sum()),'prob_loss_gt200':float(probs[losses>200].sum()),'best_cp':best,'prob_best_cp':float(probs[losses==0].sum())})
    return output

def summarize(items,rows):
    summary={}
    for depth in sorted(set(r['depth'] for r in rows)):
        summary[str(depth)]={}
        for name,_,_ in GRID:
            batch=[r for r in rows if r['depth']==depth and r['profile']==name]
            if not batch:continue
            fields=('support','entropy_bits','expected_cp_loss','prob_loss_gt100','prob_loss_gt200','prob_best_cp')
            means={k:float(np.mean([r[k] for r in batch])) for k in fields}
            baseline={r['position_id']:r for r in rows if r['depth']==depth and r['profile']=='T0.5_P0.9'}
            delta=np.array([r['expected_cp_loss']-baseline[r['position_id']]['expected_cp_loss'] for r in batch])
            rng=np.random.default_rng(20261002)
            bootstrap=np.array([np.mean(rng.choice(delta,len(delta),replace=True)) for _ in range(2000)])
            summary[str(depth)][name]={'n':len(batch),'means':means,'cp_loss_delta_vs_baseline':float(delta.mean()),'position_bootstrap95_delta':[float(x) for x in np.quantile(bootstrap,[.025,.975])]}
    summary['strata_counts']={f'pair{pair}_ply{ply}':sum(x['pair']==pair and x['ply']==ply for x in items) for pair in range(3) for ply in PLIES}
    return summary

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--stockfish',default='/opt/homebrew/bin/stockfish');ap.add_argument('--depth',type=int,default=10);ap.add_argument('--refine-depth',type=int,default=14);ap.add_argument('--refine-per-stratum',type=int,default=2);args=ap.parse_args()
    HERE.mkdir(exist_ok=True)
    if (HERE/'positions.json').exists():items=json.loads((HERE/'positions.json').read_text())
    else:
        items,snapshots=select_positions()
        (HERE/'positions.json').write_text(json.dumps(items,indent=2)+'\n')
        (HERE/'source_first30_games.json').write_text(json.dumps(snapshots,indent=2)+'\n')
    policy=Policy(threads=1);engine=chess.engine.SimpleEngine.popen_uci(args.stockfish);engine.configure({'Threads':1,'Hash':64})
    manifest={'purpose':'secondary matched-position diagnostic; not Elo','depth':args.depth,'refine_depth':args.refine_depth,'refine_per_stratum':args.refine_per_stratum,'position_count':len(items),'plies':PLIES,'grid':GRID,'self_elo':1600,'opponent_elo':1600,'model_sha256':sha256(MODEL79),'stockfish_sha256':sha256(args.stockfish),'engine_id':engine.id,'threads':1,'hash_mb':64,'multipv':'all legal moves','cp_mate_mapping':10000,'dedup':'first four FEN fields','position_selection':'round-robin source-pair and fixed-ply strata from first 30 complete games per pair; exclude finished games at/before ply','all_sampled_positions_white_to_move':True,'input':'Mobile Maia stable25 repeated current board','diagnostic_script_sha256':sha256(__file__),'policy_sha256':sha256(STRENGTH/'mobile_policy.py'),'python':sys.version,'platform':platform.platform()}
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    rawpath=HERE/'raw.jsonl';prior={}
    if rawpath.exists():
        for line in rawpath.read_text().splitlines():
            row=json.loads(line);prior[row['position']['id'],row['depth']]=row
    refined=collections.Counter();refineids=set()
    for item in items:
        key=(item['pair'],item['ply'])
        if refined[key]<args.refine_per_stratum:refineids.add(item['id']);refined[key]+=1
    start=time.time();allrows=[]
    try:
        for number,item in enumerate(items):
            board=chess.Board(item['fen']);logits=policy.logits(board)
            for depth in [args.depth]+([args.refine_depth] if item['id'] in refineids else []):
                key=item['id'],depth
                if key in prior:raw=prior[key]
                else:
                    begin=time.time();scores=analyse(engine,item,depth)
                    raw={'position':item,'depth':depth,'seconds':time.time()-begin,'legal_logits':{m.uci():float(logits[move_index(m,board.turn==chess.BLACK)]) for m in board.legal_moves},'evaluations':scores}
                    with rawpath.open('a') as f:f.write(json.dumps(raw,separators=(',',':'))+'\n');f.flush()
                    prior[key]=raw
                allrows.extend(metrics(item,logits,raw['evaluations'],depth))
            if (number+1)%10==0:print(json.dumps({'positions_done':number+1,'positions_total':len(items),'elapsed_seconds':round(time.time()-start,1)}),flush=True)
    finally:engine.quit()
    (HERE/'metrics.json').write_text(json.dumps(allrows,indent=2)+'\n')
    (HERE/'summary.json').write_text(json.dumps(summarize(items,allrows),indent=2)+'\n')
    print(json.dumps({'complete':True,'positions':len(items),'seconds':time.time()-start}),flush=True)

if __name__=='__main__':main()
