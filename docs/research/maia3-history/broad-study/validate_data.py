from study import *
from collections import defaultdict,Counter
names=['pilot','main','opening','equal','tactical','tactical-deep'];samples={n:readrows(ROOT/(n+'.jsonl')) for n in names};allrows={r['id']:r for rows in samples.values() for r in rows};bygame=defaultdict(dict)
for r in allrows.values():bygame[r['game']][r['ply']]=r
checked=0
for g in readrows(ROOT/'source/allie-test.jsonl'):
 if g['game-id'] not in bygame:continue
 b=chess.Board();fens=[b.fen()]
 for ply,u in enumerate(g['moves-uci'].split()):
  if ply in bygame[g['game-id']]:
   r=bygame[g['game-id']][ply];assert r['history']==fens[-8:];assert r['played']==u;assert chess.Move.from_uci(u) in b.legal_moves
   assert r['self_elo']==int(g['white-elo'] if b.turn==chess.WHITE else g['black-elo']);assert r['color']==int(b.turn==chess.BLACK);checked+=1
  b.push_uci(u);fens.append(b.fen())
assert checked==len(allrows)
assert not {r['game'] for r in samples['pilot']} & {r['game'] for r in samples['main']+samples['opening']}
assert all(v==840 for v in Counter((r['band'],r['color'],r['stage']) for r in samples['main']).values())
for n in ['equal','tactical','tactical-deep']:assert {r['id'] for r in samples[n]}<={r['id'] for r in samples['main']}
report={'status':'passed','unique_positions_checked':checked,'unique_games':len(bygame),'pilot_main_game_overlap':0,'main_balanced_cells':24,'main_positions_per_cell':840,'source_hashes':{n:digest(ROOT/(n+'.jsonl')) for n in names}}
(ROOT/'results/data-validation.json').write_text(json.dumps(report,indent=2));print(report)
