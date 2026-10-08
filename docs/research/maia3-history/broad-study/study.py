from pathlib import Path
import hashlib,json,math,random,time,sys,os,shutil
import chess,numpy as np,onnxruntime as ort
ROOT=Path(__file__).resolve().parent
MODEL=Path(os.environ.get('MAIA_MODEL', str(ROOT.parent/'assets/maia3-79m.onnx')))
STOCKFISH=Path(os.environ.get('STOCKFISH_BIN') or shutil.which('stockfish') or 'stockfish')
MODEL_HASH='3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010'
def digest(path):
 h=hashlib.sha256()
 with open(path,'rb') as f:
  for c in iter(lambda:f.read(1048576),b''):h.update(c)
 return h.hexdigest()
def readrows(path):
 with open(path) as f:return [json.loads(l) for l in f]
def writerows(path,rows):
 with open(path,'w') as f:
  for r in rows:f.write(json.dumps(r,separators=(',',':'))+'\n')
def encode_one(board):
 t=np.zeros((64,12),np.float32);black=board.turn==chess.BLACK
 for s,p in board.piece_map().items():
  sq=chess.square_mirror(s) if black else s
  color=(p.color==chess.WHITE)!=black
  t[sq,p.piece_type-1+(0 if color else 6)]=1
 return t

def encode(fens,history):
 boards=[encode_one(chess.Board(f)) for f in fens[-8:]] if history else [encode_one(chess.Board(fens[-1]))]
 boards=[boards[0]]*(8-len(boards))+boards
 return np.concatenate(boards+[np.zeros((64,1),np.float32)],axis=1)
def index(m,black):
 f,t=m.from_square,m.to_square
 if black:f,t=chess.square_mirror(f),chess.square_mirror(t)
 return 4096+(chess.square_file(f)*8+chess.square_file(t))*4+{5:0,4:1,3:2,2:3}[m.promotion] if m.promotion else f*64+t

def nucleus(p,cutoff=.95):
 order=np.argsort(-p,kind='stable');n=np.searchsorted(np.cumsum(p[order]),cutoff)+1
 q=np.zeros_like(p);q[order[:n]]=p[order[:n]];return q/q.sum()
class Model:
 def __init__(self):
  assert digest(MODEL)==MODEL_HASH
  o=ort.SessionOptions();o.intra_op_num_threads=1;o.inter_op_num_threads=1;o.execution_mode=ort.ExecutionMode.ORT_SEQUENTIAL
  self.session=ort.InferenceSession(str(MODEL),sess_options=o,providers=['CPUExecutionProvider'])
 def both(self,r,equal=False):
  se=r['self_elo'];oe=r['opponent_elo']
  if equal:se=oe=min(2600,max(600,((se+50)//100)*100))
  inp=np.stack([encode(r['history'],False),encode(r['history'],True)])
  logits=self.session.run(['move_logits'],{'tokens':inp,'self_elo':np.array([se,se],np.int64),'opponent_elo':np.array([oe,oe],np.int64)})[0]
  b=chess.Board(r['history'][-1]);moves=sorted(b.legal_moves,key=lambda m:m.uci());ix=[index(m,b.turn==chess.BLACK) for m in moves]
  values=logits[:,ix].astype(np.float64);values-=values.max(axis=1,keepdims=True);p=np.exp(values);p/=p.sum(axis=1,keepdims=True)
  return moves,p

def metrics(r,moves,p):
 ucis=[m.uci() for m in moves];j=ucis.index(r['played']);out={}
 for name,q in zip(['R','H'],p):
  out[name]={'nll':float(-np.log(max(q[j],1e-300))),'accuracy':int(np.argmax(q)==j),'played_p':float(q[j]),'brier':float(np.sum(q*q)-2*q[j]+1),'top':ucis[int(np.argmax(q))],'copy_p':float(q[ucis.index(r['copy'])]) if r.get('copy') in ucis else 0.,'reverse_p':float(q[ucis.index(r['reverse'])]) if r.get('reverse') in ucis else 0.}
 out['tv']=float(np.abs(p[0]-p[1]).sum()/2);return out

def infer(dataset,equal=False,offset=0,shards=1):
 name=dataset+('-equal' if equal else '')+(f'-part{offset}' if shards>1 else '')
 rows=readrows(ROOT/(dataset+'.jsonl'))[offset::shards]
 output=ROOT/'results'/(name+'.jsonl')
 done={r['id'] for r in readrows(output)} if output.exists() else set()
 model=Model();start=time.time();count=0
 with output.open('a') as f:
  for r in rows:
   if r['id'] in done:continue
   moves,p=model.both(r,equal)
   result={k:r[k] for k in ['id','game','band','color','stage','ply','self_elo','opponent_elo','played','copy','reverse']}
   result.update(metrics(r,moves,p));result['ucis']=[m.uci() for m in moves];result['pR']=p[0].tolist();result['pH']=p[1].tolist()
   f.write(json.dumps(result,separators=(',',':'))+'\n');count+=1
   if count%100==0:f.flush();print(name,count,'/',len(rows),'seconds',round(time.time()-start,1),flush=True)
 metadata={'name':name,'rows':len(rows),'computed':count,'seconds':time.time()-start,'source_sha256':digest(ROOT/'study.py'),'protocol_sha256':digest(ROOT/'PROTOCOL.txt'),'dataset_sha256':digest(ROOT/(dataset+'.jsonl')),'model_sha256':digest(MODEL),'onnxruntime':ort.__version__,'numpy':np.__version__}
 (ROOT/'results'/(name+'-run.json')).write_text(json.dumps(metadata,indent=2));print(metadata,flush=True)
if __name__=='__main__':
 import argparse
 a=argparse.ArgumentParser();a.add_argument('dataset');a.add_argument('--equal',action='store_true');a.add_argument('--offset',type=int,default=0);a.add_argument('--shards',type=int,default=1);args=a.parse_args();infer(args.dataset,args.equal,args.offset,args.shards)
