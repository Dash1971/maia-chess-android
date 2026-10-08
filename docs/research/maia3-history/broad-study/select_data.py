from study import *
from collections import defaultdict,Counter
rng=random.Random(2026100901);pool=defaultdict(list);opening=defaultdict(list);pilot=[];counts=Counter();seen_ids=set();seen_sequences=set()
def band(e):return 0 if e<1200 else 1 if e<1600 else 2 if e<2000 else 3
for n,g in enumerate(readrows(ROOT/'source/allie-test.jsonl')):
 gid=g['game-id'];seq=g['moves-uci'];moves=seq.split();times=g['moves-seconds'];es=[int(g['white-elo']),int(g['black-elo'])]
 if gid in seen_ids or seq in seen_sequences:counts['duplicate']+=1;continue
 seen_ids.add(gid);seen_sequences.add(seq)
 if not all(600<=e<=2600 for e in es):counts['rating_excluded_games']+=1;continue
 if len(moves)!=len(times) or any(not isinstance(x,(int,float)) or x<0 for x in times):counts['invalid_times_games']+=1;continue
 try:base,inc=map(int,g['time-control'].split('+'))
 except:counts['invalid_tc_games']+=1;continue
 ispilot=int(hashlib.sha256(gid.encode()).hexdigest()[:8],16)%100<5
 b=chess.Board();history=[b.fen()];clocks=[base,base];local=defaultdict(list);local_open=defaultdict(list);eligible=True;valid=True
 for ply,(u,t) in enumerate(zip(moves,times)):
  side=ply%2;mv=chess.Move.from_uci(u)
  if mv not in b.legal_moves:valid=False;break
  if min(clocks)<30 or clocks[side]-t<30:eligible=False
  if eligible:
   full=ply//2+1;st=0 if full<=20 else 1 if full<=40 else 2;ba=band(es[side]);key=(ba,side,st)
   copy=None;reverse=None
   if ply:
    prev=chess.Move.from_uci(moves[ply-1]);cm=chess.Move(chess.square_mirror(prev.from_square),chess.square_mirror(prev.to_square),promotion=prev.promotion)
    if cm in b.legal_moves:copy=cm.uci()
   if ply>=2:
    prev=chess.Move.from_uci(moves[ply-2]);rev=chess.Move(prev.to_square,prev.from_square)
    if not prev.promotion and rev in b.legal_moves:reverse=rev.uci()
   row={'id':gid.rsplit('/',1)[-1]+f'-{ply}','game':gid,'ply':ply,'history':history[-8:],'played':u,'self_elo':es[side],'opponent_elo':es[1-side],'band':ba,'color':side,'stage':st,'copy':copy,'reverse':reverse,'priority':rng.random()}
   if full>10:local[key].append(row)
   elif not ispilot:local_open[(ba,side)].append(row)
  clocks[side]=clocks[side]-t+inc;b.push(mv);history.append(b.fen())
 if not valid:counts['illegal_games']+=1;continue
 counts['eligible_pilot_games' if ispilot else 'eligible_main_games']+=1
 for key,rows in local.items():
  chosen=sorted(rows,key=lambda r:r['priority'])[:2]
  if ispilot:pilot.extend(chosen)
  else:pool[key].extend(chosen)
 for key,rows in local_open.items():opening[key].extend(sorted(rows,key=lambda r:r['priority'])[:2])
 if n%2000==0:print('parsed',n,flush=True)
main=[];opening_rows=[];coverage={}
for key in sorted(pool):
 rows=sorted(pool[key],key=lambda r:r['priority']);chosen=rows[:840];main.extend(chosen);coverage[str(key)]={'available':len(rows),'selected':len(chosen)}
for key in sorted(opening):
 rows=sorted(opening[key],key=lambda r:r['priority']);opening_rows.extend(rows[:500]);coverage['opening'+str(key)]={'available':len(rows),'selected':len(rows[:500])}
pilot=sorted(pilot,key=lambda r:r['priority'])[:1000]
for name,rows in [('pilot',pilot),('main',main),('opening',opening_rows)]:
 for r in rows:r.pop('priority')
 rows.sort(key=lambda r:r['id']);writerows(ROOT/(name+'.jsonl'),rows)
 assert len(rows)==len({r['id'] for r in rows})
assert not ({r['game'] for r in pilot}&{r['game'] for r in main})
rng2=random.Random(2026100903);tactical=[];sensitivity=[];equal=[]
for key in sorted(pool):
 rows=[r for r in main if (r['band'],r['color'],r['stage'])==key];rng2.shuffle(rows)
 tactical.extend(rows[:16]);sensitivity.extend(rows[:2]);equal.extend(rows[:100])
for name,rows in [('tactical',tactical),('tactical-deep',sensitivity),('equal',equal)]:writerows(ROOT/(name+'.jsonl'),rows)
report={'counts':dict(counts),'coverage':coverage,'sizes':{k:len(v) for k,v in [('pilot',pilot),('main',main),('opening',opening_rows),('tactical',tactical),('equal',equal)]},'source_sha256':digest(ROOT/'source/allie-test.jsonl'),'protocol_sha256':digest(ROOT/'PROTOCOL.txt'),'selector_sha256':digest(ROOT/'select_data.py'),'source_games':n+1}
(ROOT/'selection.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
