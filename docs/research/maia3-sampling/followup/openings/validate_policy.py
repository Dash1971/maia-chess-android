"""Verify fixed-fixture transformations and six fresh inference inputs."""
import argparse,json,collections,time
from pathlib import Path
import numpy as np
import chess
from mobile_policy import Policy,distribution,sha256
from conditional import HERE,nucleus,metrics

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--model',required=True,type=Path);args=ap.parse_args();start=time.time()
    rows=json.loads((HERE/'conditional95.json').read_text());max_error=0.;metric_error=0.
    for r in rows:
        b=chess.Board(r['fen']);legal={m.uci() for m in b.legal_moves};q=r['settings']['full']['distribution'];p95=r['settings']['full95']['distribution']
        assert set(q)<=legal and set(p95)<=legal and set(r['human'])<=legal
        assert abs(sum(q.values())-1)<1e-12 and abs(sum(p95.values())-1)<1e-12
        # Independently form a normalized cumulative-prefix cutoff.
        keys=sorted(q,key=q.get,reverse=True);cum=0.;keep=[]
        for k in keys:
            keep.append(k);cum+=q[k]
            if cum>=.95:break
        expected={k:q[k]/cum for k in keep};assert set(expected)==set(p95)
        max_error=max(max_error,max(abs(expected[k]-p95[k]) for k in expected))
        recalc=metrics(r['human'],p95);metric_error=max(metric_error,max(abs(v-r['settings']['full95'][k]) for k,v in recalc.items()))
    exact=json.loads((HERE/'exact-policy95.json').read_text());fixed=next(iter(exact.values()));expected_first=fixed['first_move']['full95'];expected_joint=fixed['two_ply']['full95']
    model=Policy(args.model,threads=1);b=chess.Board();moves,prob=distribution(b,model.logits(b),.95,1.);first={m.uci():float(p) for m,p in zip(moves,prob)}
    assert set(first)==set(expected_first);fresh_error=max(abs(first[k]-expected_first[k]) for k in first);joint={}
    for a,pa in first.items():
        b=chess.Board();b.push_uci(a);moves,prob=distribution(b,model.logits(b),.95,1.)
        for move,p in zip(moves,prob):joint[a+' '+move.uci()]=pa*float(p)
    assert set(joint)==set(expected_joint);fresh_error=max(fresh_error,max(abs(joint[k]-expected_joint[k]) for k in joint))
    assert max(max_error,metric_error,fresh_error)<1e-12
    out={'status':'passed','observations':len(rows),'legal_support_and_probability_sums':len(rows),
         'independent_cutoff_max_difference':max_error,'metric_max_difference':metric_error,
         'fresh_first_two_ply_max_probability_difference':fresh_error,'fresh_model_calls':model.calls,
         'model_sha256':sha256(args.model),'seconds':time.time()-start,'script_sha256':sha256(Path(__file__))}
    (HERE/'policy-validation95.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))

if __name__=='__main__':main()
