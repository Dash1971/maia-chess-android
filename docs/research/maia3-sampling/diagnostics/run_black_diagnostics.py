#!/usr/bin/env python3
"""Add fixed odd-ply cohort from the same frozen first30-game source snapshot."""
import collections,json,time
import chess,chess.engine,numpy as np
from run_diagnostics import HERE,STRENGTH,GRID,Policy,MODEL79,sha256,analyse,metrics

def main():
    items=json.loads((HERE/'positions.json').read_text())
    assert all(x['ply'] in (24,40,60) for x in items),'Only run append once'
    white_raw=[json.loads(x) for x in (HERE/'raw.jsonl').read_text().splitlines()]
    assert len(white_raw)==len(items)+18,'Wait for original white cohort completion'
    frozen=json.loads((HERE/'source_first30_games.json').read_text())
    groups={};seen={' '.join(x['fen'].split()[:4]) for x in items}
    for pair in range(3):
        for ply in (25,41,61):
            bucket=[]
            for row in frozen[str(pair)]['games']:
                if len(row['moves_uci'])<=ply:continue
                board=chess.Board()
                for uci in row['moves_uci'][:ply]:board.push_uci(uci)
                if board.is_game_over(claim_draw=True):continue
                bucket.append({'pair':pair,'game_id':row['id'],'game_number':row['number'],'ply':ply,'fen':board.fen(),'source_white':row['white'],'source_black':row['black']})
            groups[pair,ply]=bucket
    extra=[]
    while any(groups.values()):
        for key in groups:
            if not groups[key]:continue
            item=groups[key].pop(0);identity=' '.join(item['fen'].split()[:4])
            if identity in seen:continue
            seen.add(identity);item['id']=f'black-pos-{len(extra):03d}';extra.append(item)
    (HERE/'positions_white.json').write_text(json.dumps(items,indent=2)+'\n')
    (HERE/'positions_black.json').write_text(json.dumps(extra,indent=2)+'\n')
    (HERE/'positions.json').write_text(json.dumps(items+extra,indent=2)+'\n')
    policy=Policy(threads=1);engine=chess.engine.SimpleEngine.popen_uci('/opt/homebrew/bin/stockfish');engine.configure({'Threads':1,'Hash':64})
    manifest=json.loads((HERE/'manifest.json').read_text());manifest.update({'combined_position_count':len(items)+len(extra),'additional_odd_plies':[25,41,61],'all_sampled_positions_white_to_move':False,'stratum_count':18,'black_append_script_sha256':sha256(__file__),'depth14_position_count':36})
    (HERE/'manifest_combined.json').write_text(json.dumps(manifest,indent=2)+'\n')
    refined=collections.Counter();refineids=set()
    for item in extra:
        key=item['pair'],item['ply']
        if refined[key]<2:refineids.add(item['id']);refined[key]+=1
    start=time.time()
    try:
        for number,item in enumerate(extra):
            board=chess.Board(item['fen']);logits=policy.logits(board)
            for depth in [10]+([14] if item['id'] in refineids else []):
                begin=time.time();scores=analyse(engine,item,depth)
                from run_diagnostics import move_index
                record={'position':item,'depth':depth,'seconds':time.time()-begin,'legal_logits':{m.uci():float(logits[move_index(m,board.turn==chess.BLACK)]) for m in board.legal_moves},'evaluations':scores}
                with (HERE/'raw.jsonl').open('a') as f:f.write(json.dumps(record,separators=(',',':'))+'\n');f.flush()
            if (number+1)%20==0:print(json.dumps({'black_positions_done':number+1,'black_total':len(extra),'elapsed_seconds':round(time.time()-start,1)}),flush=True)
    finally:engine.quit()
    print(json.dumps({'black_complete':True,'white_positions':len(items),'black_positions':len(extra),'seconds':time.time()-start}),flush=True)

if __name__=='__main__':main()
