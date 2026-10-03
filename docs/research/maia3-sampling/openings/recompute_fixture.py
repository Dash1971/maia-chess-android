"""Recompute archived comparison fixtures without the source opening books.

Example: python recompute_fixture.py --model /path/to/maia3-79m.onnx
The archived human frequencies and trajectory/FEN selection remain fixed.
"""
import argparse,json,time
from pathlib import Path
import chess
from experiment import HERE,Policy,SETTINGS,distribution,metrics,sha256

def joint(policy,setting):
    p,t=SETTINGS[setting];root=chess.Board();moves,probs=distribution(root,policy.logits(root),p,t);first={m.uci():float(v) for m,v in zip(moves,probs)};out={}
    for move in root.legal_moves:
        board=root.copy();board.push(move);replies,values=distribution(board,policy.logits(board),p,t)
        for reply,value in zip(replies,values):out[move.uci()+' '+reply.uci()]=first.get(move.uci(),0)*float(value)
    return out

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model',type=Path,required=True)
    parser.add_argument('--fixture',type=Path,default=HERE/'conditional.json')
    parser.add_argument('--output',type=Path,default=HERE/'recomputed-fixture.json')
    parser.add_argument('--two-ply-fixture',type=Path,default=HERE/'exact-two-ply.json')
    parser.add_argument('--expected-sha256')
    parser.add_argument('--limit',type=int,help='Optional smoke-check subset; omit for complete reproduction.')
    args=parser.parse_args();digest=sha256(args.model)
    if args.expected_sha256 and digest!=args.expected_sha256:parser.error('Model SHA-256 does not match --expected-sha256')
    start=time.time();policy=Policy(args.model,threads=1);source=json.loads(args.fixture.read_text());rows=[];max_delta=0
    for i,original in enumerate(source[:args.limit] if args.limit else source):
        board=chess.Board(original['fen']);logits=policy.logits(board);record={k:v for k,v in original.items() if k!='settings'};record['settings']={}
        for setting in ('argmax','app_default','full'):
            p,t=SETTINGS[setting];moves,probs=distribution(board,logits,p,t);q={m.uci():float(v) for m,v in zip(moves,probs)}
            record['settings'][setting]={'distribution':q,**metrics(record['human'],q)}
            old=original['settings'][setting]['distribution'];max_delta=max(max_delta,max(abs(q.get(k,0)-old.get(k,0)) for k in set(q)|set(old)))
        rows.append(record)
        if i%500==0:print('recomputed',i,'model calls',policy.calls,flush=True)
    two={}
    if args.two_ply_fixture.exists():
        archive=json.loads(args.two_ply_fixture.read_text());model={s:joint(policy,s) for s in ('argmax','app_default','full')}
        for name,r in archive.items():
            h=r['human_distribution'];two[name]={'human_distribution':h,'settings':{s:{'distribution':q,**metrics(h,q)} for s,q in model.items()}}
    output={'metadata':{'model_sha256':digest,'source_fixture':args.fixture.name,'observations':len(rows),'model_calls':policy.calls,'threads':1,'seconds':time.time()-start,'maximum_probability_delta_from_source':max_delta,'same_model_required_for_probability_delta_interpretation':True},'conditional':rows,'exact_two_ply':two}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(output));print(json.dumps(output['metadata'],indent=2))

if __name__=='__main__':main()
