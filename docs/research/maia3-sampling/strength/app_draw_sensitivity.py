#!/usr/bin/env python3
"""Continue prospective draw claims using new independent future random streams."""
import argparse,collections,hashlib,json,random,time
from pathlib import Path
import chess,chess.pgn
from mobile_policy import Policy,MODEL79,MODEL5,sha256
from run_strength import PROFILES

def key(board):return ' '.join(board.fen(en_passant='fen').split(' ')[:4])
def app_outcome(board,counts):
 if board.is_checkmate():return ('0-1' if board.turn==chess.WHITE else '1-0','checkmate')
 if board.halfmove_clock>=100:return ('1/2-1/2','fifty_moves_actual')
 if board.is_stalemate():return ('1/2-1/2','stalemate')
 if board.is_insufficient_material():return ('1/2-1/2','insufficient_material')
 if max(counts.values())>=3:return ('1/2-1/2','threefold_repetition_actual')
 return None

def main():
 ap=argparse.ArgumentParser();ap.add_argument('inputs',nargs='+',type=Path);ap.add_argument('--model',choices=['79m','5m'],required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();args.output.mkdir(parents=True,exist_ok=True)
 rows=[]
 for path in args.inputs:rows.extend(json.loads(line) for line in path.read_text().splitlines())
 profiles=dict(PROFILES)
 for path in args.inputs:profiles.update(json.loads((path.parent/'manifest.json').read_text())['profiles'])
 rows.sort(key=lambda r:(r['number'],r['pair_index']));model=MODEL79 if args.model=='79m' else MODEL5
 manifest={'protocol':'app draw timing sensitivity; preserve primary prefixes; replace prospective claim with future independently sampled moves until raw-FEN repetition3/halfmove100/terminal/cap400','model':args.model,'model_sha256':sha256(model),'input_files':[str(p) for p in args.inputs],'input_sha256':[sha256(p) for p in args.inputs],'seed':2026100202,'max_plies':400,'runner_sha256':sha256(__file__),'policy_sha256':sha256(Path(__file__).with_name('mobile_policy.py'))};(args.output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 output=args.output/'games.jsonl';done={}
 if output.exists():done={r['id']:r for r in map(json.loads,output.read_text().splitlines())}
 p=Policy(model,threads=1,cache_limit=15000);continued=0;extra=0;begin=time.time()
 for row in rows:
  if row['id'] in done:continue
  b=chess.Board();counts=collections.Counter({key(b):1})
  for uci in row['moves_uci']:b.push(chess.Move.from_uci(uci));counts[key(b)]+=1
  original_outcome=app_outcome(b,counts)
  is_prospective=row['termination'] in ['threefold_repetition','fifty_moves'] and original_outcome is None
  updated=dict(row);updated['primary_result']=row['result'];updated['primary_termination']=row['termination'];updated['primary_plies']=row['plies'];updated['continued_prospective_claim']=is_prospective;updated['sensitivity_seed_white']=2026100202+1000000*row['pair_index']+2*row['number'];updated['sensitivity_seed_black']=updated['sensitivity_seed_white']+1
  if is_prospective:
   continued+=1;rngs={chess.WHITE:random.Random(updated['sensitivity_seed_white']),chess.BLACK:random.Random(updated['sensitivity_seed_black'])};moves=list(row['moves_uci']);t=time.time()
   while app_outcome(b,counts) is None and b.ply()<400:
    profile=profiles[row['white'] if b.turn==chess.WHITE else row['black']];move=p.move(b,profile['top_p'],profile['temperature'],rngs[b.turn]);assert move in b.legal_moves;moves.append(move.uci());b.push(move);counts[key(b)]+=1;extra+=1
   outcome=app_outcome(b,counts) or ('1/2-1/2','max_plies');updated['result'],updated['termination']=outcome;updated['moves_uci']=moves;updated['plies']=len(moves);updated['final_fen']=b.fen();updated['seconds']=row['seconds']+time.time()-t;scorewhite={'1-0':1.,'0-1':0.,'1/2-1/2':.5}[updated['result']];updated['score_first']=scorewhite if row['white']==row['first'] else 1-scorewhite;updated['movetext_sha256']=hashlib.sha256(' '.join(moves).encode()).hexdigest()
  elif original_outcome:
   updated['result'],updated['termination']=original_outcome
  done[updated['id']]=updated
  with output.open('a') as f:f.write(json.dumps(updated,separators=(',',':'))+'\n');f.flush()
 with (args.output/'games.pgn').open('w') as f:
  for row in rows:
   r=done[row['id']];g=chess.pgn.Game();g.headers.update({'Event':'Mobile Maia app draw sensitivity','Site':'local CPU','Date':'2026.10.02','Round':str(r['number']+1),'White':f"Maia3-{args.model}-{r['white']}",'Black':f"Maia3-{args.model}-{r['black']}",'Result':r['result'],'Termination':r['termination'],'StudyGameId':r['id'],'PrimaryResult':r['primary_result'],'PrimaryPlies':str(r['primary_plies']),'ContinuationWhiteSeed':str(r['sensitivity_seed_white']),'ContinuationBlackSeed':str(r['sensitivity_seed_black'])});node=g
   for u in r['moves_uci']:node=node.add_variation(chess.Move.from_uci(u))
   f.write(str(g)+'\n\n')
 summary={'games':len(rows),'prospective_claim_continuations':sum(r['continued_prospective_claim'] for r in done.values()),'results_changed':sum(r['result']!=r['primary_result'] for r in done.values()),'added_plies':sum(r['plies']-r['primary_plies'] for r in done.values()),'continuation_seconds_this_run':time.time()-begin,'terminations':dict(collections.Counter(r['termination'] for r in done.values()))};(args.output/'continuation-summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary,indent=2))
if __name__=='__main__':main()
