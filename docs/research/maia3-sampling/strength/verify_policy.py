import json,re,time
from pathlib import Path
import chess,numpy as np
from mobile_policy import *
text=(ROOT/'stable25-review/integration_test/fixtures/maia3_reference.dart').read_text();p=Policy();rows=[]
for block in text.split('  Maia3ReferenceCase(')[1:]:
 name=re.search("name: '([^']+)'",block)[1];fen=re.search("fen: '([^']+)'",block)[1];selfelo=int(re.search(r'selfElo: (\d+)',block)[1]);oppelo=int(re.search(r'opponentElo: (\d+)',block)[1]);top=re.search("topMove: '([^']+)'",block)[1];board=chess.Board(fen);logits=p.logits(board,selfelo,oppelo)
 expected=dict((m,float(l)) for m,l in re.findall(r"'([a-h][1-8][a-h][1-8][qrbn]?)': ([\d.]+)",block));errors={m:float(logits[move_index(chess.Move.from_uci(m),board.turn==chess.BLACK)])-l for m,l in expected.items()};actual=sample(board,logits,0,0).uci();assert actual==top;assert max(abs(e) for e in errors.values())<.0001
 rows.append({'name':name,'moves_checked':len(errors),'top_move':actual,'max_abs_error':max(abs(e) for e in errors.values())})
# Crossing move and zero TopP are required app semantics.
b=chess.Board();l=np.full(4352,-100.,np.float32);ms=list(b.legal_moves);l[move_index(ms[0])]=np.log(.55);l[move_index(ms[1])]=np.log(.3);l[move_index(ms[2])]=np.log(.15)
assert len(distribution(b,l,.6,1)[0])==2
assert len(distribution(b,l,0,1)[0])==1
print(json.dumps({'official_reference_parity':rows,'sampler_boundary_checks':'passed','model_sha256':sha256(MODEL79)},indent=2))
