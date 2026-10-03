#!/usr/bin/env python3
"""Validate archived cohort provenance, legal evaluation coverage, and finite metrics."""
import collections,hashlib,json,math
from pathlib import Path
import chess

HERE=Path(__file__).resolve().parent
items=json.loads((HERE/'positions.json').read_text());frozen=json.loads((HERE/'source_first30_games.json').read_text())
identities=set()
for pair,source in frozen.items():
    assert len(source['games'])==30
    snapshot='\n'.join(json.dumps(r,sort_keys=True) for r in source['games'])+'\n'
    assert hashlib.sha256(snapshot.encode()).hexdigest()==source['first_30_games_sha256']
for item in items:
    game=next(r for r in frozen[str(item['pair'])]['games'] if r['id']==item['game_id'])
    board=chess.Board()
    for uci in game['moves_uci'][:item['ply']]:board.push_uci(uci)
    assert board.fen()==item['fen']
    assert not board.is_game_over(claim_draw=True)
    identity=' '.join(board.fen().split()[:4]);assert identity not in identities;identities.add(identity)
raw=[json.loads(x) for x in (HERE/'raw.jsonl').read_text().splitlines()]
assert len(raw)==len(items)+36
keys=set();depth_counts=collections.Counter();depth_actual=collections.Counter();mate_positions=collections.Counter()
for row in raw:
    key=row['position']['id'],row['depth'];assert key not in keys;keys.add(key)
    board=chess.Board(row['position']['fen']);legal={m.uci() for m in board.legal_moves}
    assert set(row['legal_logits'])==legal==set(row['evaluations'])
    for score in row['evaluations'].values():
        assert isinstance(score['cp'],int)
        assert score['depth']>=row['depth']
        depth_actual[score['depth']]+=1
    depth_counts[row['depth']]+=1
    if any(x['mate'] is not None for x in row['evaluations'].values()):mate_positions[row['depth']]+=1
for item in items:assert (item['id'],10) in keys
report={'passed':True,'positions':len(items),'analyses':len(raw),'requested_depth_counts':dict(depth_counts),'actual_pv_depth_counts':dict(depth_actual),'positions_with_any_mate_score':dict(mate_positions),'side_counts':{'white':sum(chess.Board(x['fen']).turn==chess.WHITE for x in items),'black':sum(chess.Board(x['fen']).turn==chess.BLACK for x in items)}}
(HERE/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
