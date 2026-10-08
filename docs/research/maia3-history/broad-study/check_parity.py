from study import *
refs=readrows(ROOT/'pilot.jsonl')
data=np.load(ROOT/'results/upstream-reference.npz');records=json.loads((ROOT/'results/upstream-reference.json').read_text());model=Model();max_logits=0.;max_p=0.;tensor_mismatches=0
for i,r in enumerate(records):
 t=encode(r['history'],r['mode']=='H');assert np.array_equal(t,data['tokens'][i]);b=chess.Board(r['history'][-1]);assert [index(chess.Move.from_uci(m),b.turn==chess.BLACK) for m in r['ucis']]==r['indices']
 logits=model.session.run(['move_logits'],{'tokens':t[None,:,:],'self_elo':np.array([r['self_elo']],np.int64),'opponent_elo':np.array([r['opponent_elo']],np.int64)})[0][0]
 idx=r['indices'];v=logits[idx].astype(np.float64);v-=v.max();p=np.exp(v);p/=p.sum();max_logits=max(max_logits,float(np.max(np.abs(logits[idx]-data['logits'][i,idx]))));max_p=max(max_p,float(np.max(np.abs(p-np.array(r['probabilities'])))))
 assert np.argmax(p)==np.argmax(r['probabilities'])
assert max_p<1e-4 and max_logits<1e-3
out={'status':'passed','cases':len(records),'tensor_exact_matches':len(records),'maximum_legal_logit_difference':max_logits,'maximum_probability_difference':max_p,'identical_top_moves':len(records),'upstream_commit':'1e13597c42d4858b7cfd7cfdae01e297263364b2','checkpoint_sha256':'3fc6181d5db789b45a15305732148757ae74efa3e0028e81ba335b462dac45c2','onnx_sha256':digest(MODEL)}
(ROOT/'results/parity.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
