#!/usr/bin/env python3
"""Fixed-N color-balanced no-book Mobile Maia policy round robin. Durable resume."""
import argparse,csv,datetime,hashlib,itertools,json,platform,random,sys,time
from pathlib import Path
import chess,chess.pgn,numpy as np,onnxruntime as ort
from mobile_policy import Policy,MODEL79,MODEL5,sha256
PROFILES={'temp_only':{'temperature':.5,'top_p':1.},'topp_only':{'temperature':1.,'top_p':.9},'full':{'temperature':1.,'top_p':1.}}
PAIRS=list(itertools.combinations(PROFILES,2))

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--model',choices=['79m','5m'],default='79m');ap.add_argument('--games-per-pair',type=int,default=600);ap.add_argument('--seed',type=int,default=20261002);ap.add_argument('--max-plies',type=int,default=400);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--threads',type=int,default=1);ap.add_argument('--pair-index',type=int,choices=[0,1,2],default=None);args=ap.parse_args()
 assert args.games_per_pair%2==0
 args.output.mkdir(parents=True,exist_ok=True); model=MODEL79 if args.model=='79m' else MODEL5
 config={'pair_index':args.pair_index,'model':args.model,'model_sha256':sha256(model),'profiles':PROFILES,'games_per_pair':args.games_per_pair,'seed':args.seed,'max_plies':args.max_plies,'threads':args.threads,'self_elo':1600,'opponent_elo':1600,'opening':'standard chess starting position; no book or forced moves','history':'current board repeated in 8 slots','claim_draw':True,'provider':'CPUExecutionProvider','python':sys.version,'numpy':np.__version__,'onnxruntime':ort.__version__,'chess':chess.__version__,'platform':platform.platform(),'runner_sha256':sha256(__file__),'policy_sha256':sha256(Path(__file__).with_name('mobile_policy.py'))}
 manifest=args.output/'manifest.json'
 if manifest.exists():
  old=json.loads(manifest.read_text()); assert old==config,'Manifest mismatch, use fresh output'
 else:manifest.write_text(json.dumps(config,indent=2)+'\n')
 data=args.output/'games.jsonl';completed={}
 if data.exists():
  for line in data.read_text().splitlines():
   row=json.loads(line);completed[row['id']]=row
 p=Policy(model,threads=args.threads,cache_limit=15000);start=time.time();new=0
 for number in range(args.games_per_pair):
  for pair_index,(a,b) in enumerate(PAIRS):
   if args.pair_index is not None and pair_index!=args.pair_index:continue
   gid=f'{pair_index}-{number}'
   if gid in completed:continue
   white,black=(a,b) if number%2==0 else (b,a)
   # Every game/color owns an independent explicit random stream.
   seed_white=args.seed+1000000*pair_index+number*2;seed_black=seed_white+1
   rngs={chess.WHITE:random.Random(seed_white),chess.BLACK:random.Random(seed_black)}
   board=chess.Board();game=chess.pgn.Game();game.headers.update({'Event':'Mobile Maia sampling 1600 no-book study','Site':'local CPU','Date':datetime.datetime.now().strftime('%Y.%m.%d'),'Round':str(number+1),'White':f'Maia3-{args.model}-{white}','Black':f'Maia3-{args.model}-{black}','WhiteConditioningElo':'1600','BlackConditioningElo':'1600','WhiteSeed':str(seed_white),'BlackSeed':str(seed_black),'StudyGameId':gid});node=game;begin=time.time();ucis=[]
   while not board.is_game_over(claim_draw=True) and board.ply()<args.max_plies:
    profile=PROFILES[white if board.turn==chess.WHITE else black]
    move=p.move(board,profile['top_p'],profile['temperature'],rngs[board.turn]);assert move in board.legal_moves
    ucis.append(move.uci());board.push(move);node=node.add_variation(move)
   outcome=board.outcome(claim_draw=True)
   result=outcome.result() if outcome else '1/2-1/2';termination=outcome.termination.name.lower() if outcome else 'max_plies';game.headers['Result']=result;game.headers['Termination']=termination
   score_white={'1-0':1.,'1/2-1/2':.5,'0-1':0.}[result]
   row={'id':gid,'pair_index':pair_index,'number':number,'first':a,'second':b,'white':white,'black':black,'seed_white':seed_white,'seed_black':seed_black,'result':result,'score_first':score_white if white==a else 1-score_white,'termination':termination,'plies':len(ucis),'moves_uci':ucis,'seconds':time.time()-begin,'final_fen':board.fen(),'movetext_sha256':hashlib.sha256(' '.join(ucis).encode()).hexdigest()}
   # PGN first, JSON authoritative completion second; any interrupted orphan PGN regenerated after run.
   with (args.output/'games.pgn').open('a') as f:f.write(str(game)+'\n\n');f.flush()
   with data.open('a') as f:f.write(json.dumps(row,separators=(',',':'))+'\n');f.flush()
   completed[gid]=row;new+=1
   if new%15==0:print(json.dumps({'completed':len(completed),'target':args.games_per_pair*(3 if args.pair_index is None else 1),'new':new,'elapsed_seconds':round(time.time()-start,1),'games_per_hour':round(new*3600/(time.time()-start),1),'inference_calls':p.calls,'cache_hits':p.hits}),flush=True)
 print('complete',len(completed),flush=True)
 # Normalize PGN from authoritative rows, removing possible interrupted orphan entries.
 with (args.output/'games.pgn').open('w') as f:
  for row in sorted(completed.values(),key=lambda r:(r['number'],r['pair_index'])):
   game=chess.pgn.Game();game.headers.update({'Event':'Mobile Maia sampling 1600 no-book study','Site':'local CPU','Date':'2026.10.02','Round':str(row['number']+1),'White':f"Maia3-{args.model}-{row['white']}",'Black':f"Maia3-{args.model}-{row['black']}",'WhiteConditioningElo':'1600','BlackConditioningElo':'1600','WhiteSeed':str(row['seed_white']),'BlackSeed':str(row['seed_black']),'StudyGameId':row['id'],'Result':row['result'],'Termination':row['termination']});node=game
   for uci in row['moves_uci']:node=node.add_variation(chess.Move.from_uci(uci))
   f.write(str(game)+'\n\n')
if __name__=='__main__':main()
