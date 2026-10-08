from study import *
import chess.engine,argparse
p=argparse.ArgumentParser();p.add_argument('--deep',action='store_true');p.add_argument('--offset',type=int,default=0);p.add_argument('--shards',type=int,default=1);a=p.parse_args()
nodes=80000 if a.deep else 20000;dataset='tactical-deep' if a.deep else 'tactical';name=dataset+f'-part{a.offset}';rows=readrows(ROOT/(dataset+'.jsonl'))[a.offset::a.shards];output=ROOT/'results'/(name+'.jsonl')
done={r['id'] for r in readrows(output)} if output.exists() else set();engine=chess.engine.SimpleEngine.popen_uci(str(STOCKFISH));engine.configure({'Threads':1,'Hash':32});engine_id=dict(engine.id);started=time.time()
try:
 with output.open('a') as f:
  for nr,r in enumerate(rows):
   if r['id'] in done:continue
   b=chess.Board(r['history'][-1]);turn=b.turn;vals=[]
   for move in sorted(b.legal_moves,key=lambda m:m.uci()):
    child=b.copy();child.push(move);mate1=child.is_checkmate();stalemate=child.is_stalemate();insufficient=child.is_insufficient_material()
    if mate1:cp=32000;mate=1;depth=0;used=0
    elif stalemate or insufficient:cp=0;mate=None;depth=0;used=0
    else:
     engine.configure({'Clear Hash':None});info=engine.analyse(child,chess.engine.Limit(nodes=nodes));score=info['score'].pov(turn);cp=score.score(mate_score=32000);mate=score.mate();depth=info.get('depth');used=info.get('nodes')
    vals.append({'uci':move.uci(),'cp':cp,'mate':mate,'mate1':mate1,'stalemate':stalemate,'insufficient':insufficient,'depth':depth,'nodes':used})
   out={'id':r['id'],'game':r['game'],'band':r['band'],'color':r['color'],'stage':r['stage'],'played':r['played'],'fen':b.fen(),'values':vals,'budget':nodes}
   f.write(json.dumps(out,separators=(',',':'))+'\n');f.flush()
   if (nr+1)%10==0:print(name,nr+1,'/',len(rows),'seconds',round(time.time()-started,1),flush=True)
finally:engine.quit()
(ROOT/'results'/(name+'-run.json')).write_text(json.dumps({'engine':engine_id,'budget':nodes,'rows':len(rows),'seconds_this_invocation':time.time()-started,'prior_completed_rows':len(done),'executed_original_sha256':digest(ROOT/'source/tactical-executed.py'),'script_sha256':digest(ROOT/'tactical.py'),'engine_sha256':digest(Path(str(STOCKFISH)).resolve()),'dataset_sha256':digest(ROOT/(dataset+'.jsonl'))},indent=2))
