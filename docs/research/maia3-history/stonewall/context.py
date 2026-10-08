from run import *
from study import STOCKFISH
def main():
 source=ROOT.parent/'broad-study/source/allie-test.jsonl'
 counts={k:{'games':0,'d4':0,'d4d5e3':0,'d4d5e3e6Bd3':0,'mirrored3':0,'white_first3':0} for k in ['600-799','800-1199','1200-2600']};examples=[]
 for line in source.open():
  r=json.loads(line);e=r['black-elo'];key='600-799' if 600<=e<800 else '800-1199' if 800<=e<1200 else '1200-2600' if 1200<=e<=2600 else None
  if key is None:continue
  m=r['moves-uci'].split();c=counts[key];c['games']+=1
  c['d4']+=m[:1]==['d2d4'];c['d4d5e3']+=m[:3]==['d2d4','d7d5','e2e3'];c['d4d5e3e6Bd3']+=m[:5]==['d2d4','d7d5','e2e3','e7e6','f1d3'];c['mirrored3']+=m[:6]==['d2d4','d7d5','e2e3','e7e6','f1d3','f8d6'];c['white_first3']+=m[:6:2]==PLAN[:3]
  if m[:6:2]==PLAN[:3]:examples.append({'game':r['game-id'],'black_elo':e,'white_elo':r['white-elo'],'moves':m[:20]})
 (ROOT/'human-context.json').write_text(json.dumps({'source_sha256':digest(source),'counts':counts,'examples':examples},indent=2));print('HUMAN',json.dumps(counts),flush=True)
 engine=chess.engine.SimpleEngine.popen_uci(str(STOCKFISH));engine.configure({'Threads':1,'Hash':32});engine_id=engine.id;rows=[]
 b=chess.Board()
 for turn,u in enumerate(PLAN,1):
  b.push_uci(u);copy=mirror(chess.Move.from_uci(u));record={'turn':turn,'fen':b.fen(),'mirror':b.san(copy)}
  for name,root_moves in [('best',None),('forced_mirror',[copy])]:
   engine.configure({'Clear Hash':None})
   info=engine.analyse(b,chess.engine.Limit(nodes=100000),root_moves=root_moves)
   record[name]={'cp_black':info['score'].pov(chess.BLACK).score(mate_score=32000),'mate_black':info['score'].pov(chess.BLACK).mate(),'depth':info.get('depth'),'nodes':info['nodes'],'pv':b.variation_san(info['pv'])}
  rows.append(record);b.push(copy);print('ENGINE',json.dumps(record),flush=True)
 engine.quit();(ROOT/'engine-context.json').write_text(json.dumps({'engine':engine_id,'nodes_per_search':100000,'positions':rows},indent=2))
if __name__=='__main__':main()
