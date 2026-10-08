from pathlib import Path
import sys,json,time,math
import numpy as np
import chess,chess.pgn,chess.engine
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent/'broad-study'))
from study import Model,writerows,digest,MODEL_HASH
PLAN=['d2d4','e2e3','f1d3','f2f4','g1f3','c2c3','b1d2','e1g1','d1e2','f3e5']
def mirror(m):return chess.Move(chess.square_mirror(m.from_square),chess.square_mirror(m.to_square),promotion=m.promotion)
def push(b,h,m):b.push(m);h.append(b.fen())
class Cached:
 def __init__(self):self.model=Model();self.cache={};self.f=(ROOT/'policies.jsonl').open('w')
 def get(self,h,elo):
  key=(elo,tuple(h[-8:]))
  if key not in self.cache:
   moves,p=self.model.both({'history':h[-8:],'self_elo':elo,'opponent_elo':elo})
   row={'id':len(self.cache),'elo':elo,'history':h[-8:],'ucis':[m.uci() for m in moves],'pR':p[0].tolist(),'pH':p[1].tolist()}
   self.f.write(json.dumps(row,separators=(',',':'))+'\n')
   self.cache[key]=(row['id'],moves,p)
  return self.cache[key]
def run():
 start=time.time();c=Cached();fixed=[]
 for elo in [600,700,800,1000,1200]:
  b=chess.Board();h=[b.fen()];joint=np.ones(2)
  for turn,u in enumerate(PLAN,1):
   m=chess.Move.from_uci(u);assert m in b.legal_moves;push(b,h,m)
   cp=mirror(m);assert cp in b.legal_moves
   pid,moves,p=c.get(h,elo);i=moves.index(cp);joint*=p[:,i]
   fixed.append({'elo':elo,'turn':turn,'white':u,'mirror':cp.uci(),'san':b.san(cp),'fen':b.fen(),'policy_id':pid,'pR':float(p[0,i]),'pH':float(p[1,i]),'jointR':float(joint[0]),'jointH':float(joint[1]),'topR':b.san(moves[int(p[0].argmax())]),'topH':b.san(moves[int(p[1].argmax())])})
   push(b,h,cp)
 writerows(ROOT/'fixed.jsonl',fixed)
 print('FIXED',json.dumps(fixed[:10]),flush=True)
 games=[]
 with (ROOT/'games.jsonl').open('w') as f:
  for elo in [600,700]:
   for seed in range(250):
    uniform=np.random.default_rng(2026100907+elo*1000+seed).random(8)
    for mode in range(2):
     b=chess.Board();h=[b.fen()];copies=[];ids=[];stop=None
     for turn,u in enumerate(PLAN[:8]):
      if b.is_game_over(claim_draw=True):stop='terminal';break
      m=chess.Move.from_uci(u)
      if m not in b.legal_moves:stop='script_illegal';break
      push(b,h,m)
      if b.is_game_over(claim_draw=True):stop='terminal_after_white';break
      pid,moves,p=c.get(h,elo);j=min(int(np.searchsorted(np.cumsum(p[mode]),uniform[turn],side='right')),len(moves)-1)
      selected=moves[j];copies.append(selected==mirror(m));ids.append(pid);push(b,h,selected)
     longest=current=0
     for v in copies:current=current+1 if v else 0;longest=max(longest,current)
     r={'elo':elo,'seed':seed,'mode':'RH'[mode],'moves':[m.uci() for m in b.move_stack],'copies':copies,'policy_ids':ids,'stop':stop,'black_turns':len(copies),'copy_count':sum(copies),'longest_run':longest,'first3':len(copies)>=3 and all(copies[:3]),'first6':len(copies)>=6 and all(copies[:6]),'all8':len(copies)==8 and all(copies),'pgn':str(chess.pgn.Game.from_board(b).mainline())}
     games.append(r);f.write(json.dumps(r,separators=(',',':'))+'\n')
    if (seed+1)%50==0:f.flush();c.f.flush();print('ROLLOUT',elo,seed+1,'policies',len(c.cache),'seconds',round(time.time()-start,1),flush=True)
 c.f.close()
 summary={}
 for elo in [600,700]:
  rows={mode:[r for r in games if r['elo']==elo and r['mode']==mode] for mode in 'RH'}
  out={}
  for metric in ['first3','first6','all8','copy_count','longest_run','black_turns']:
   a=np.array([r[metric] for r in rows['R']],float);b=np.array([r[metric] for r in rows['H']],float)
   rng=np.random.default_rng(2026100908);ix=rng.integers(0,len(a),(2000,len(a)));ci=np.quantile((b-a)[ix].mean(axis=1),[.025,.975])
   out[metric]={'R':float(a.mean()),'H':float(b.mean()),'delta':float((b-a).mean()),'ci':ci.tolist()}
  out['stops']={mode:sum(r['stop'] is not None for r in rr) for mode,rr in rows.items()};summary[elo]=out
 (ROOT/'summary.json').write_text(json.dumps(summary,indent=2))
 (ROOT/'run-metadata.json').write_text(json.dumps({'model_sha256':MODEL_HASH,'script_sha256':digest(__file__),'encoder_sha256':digest(ROOT.parent/'broad-study/study.py'),'protocol_sha256':digest(ROOT/'PROTOCOL.txt'),'seconds':time.time()-start,'games':len(games),'policies':len(c.cache)},indent=2))
 print('SUMMARY',json.dumps(summary),flush=True)
if __name__=='__main__':run()
