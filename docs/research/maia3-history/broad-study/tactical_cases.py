from study import *
import chess.engine
engine=chess.engine.SimpleEngine.popen_uci(str(STOCKFISH));engine.configure({'Threads':1,'Hash':32});rows=[]
try:
 for r in readrows(ROOT/'cases.jsonl'):
  b=chess.Board(r['history'][-1]);vals=[]
  for m in sorted(b.legal_moves,key=lambda m:m.uci()):
   c=b.copy();c.push(m)
   if c.is_checkmate():score=32000;mate=1
   elif c.is_stalemate() or c.is_insufficient_material():score=0;mate=None
   else:
    engine.configure({'Clear Hash':None});info=engine.analyse(c,chess.engine.Limit(nodes=20000));s=info['score'].pov(b.turn);score=s.score(mate_score=32000);mate=s.mate()
   vals.append({'uci':m.uci(),'san':b.san(m),'cp':score,'mate':mate,'stalemate':c.is_stalemate()})
  row={'id':r['id'],'played':r['played'],'best_cp':max(v['cp'] for v in vals),'values':vals};rows.append(row)
finally:engine.quit()
writerows(ROOT/'results/cases-tactical.jsonl',rows)
for r in rows:print(r['id'],'best',r['best_cp'],'played',next(v for v in r['values'] if v['uci']==r['played']))
