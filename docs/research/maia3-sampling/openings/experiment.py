"""Conditional policy calibration and book-free rollout repertoire, Maia3 79M."""
import sys, json, random, time, csv, math, collections, hashlib, argparse
from pathlib import Path
import numpy as np
import chess, chess.polyglot
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'strength'))
from mobile_policy import Policy, MODEL79, distribution, sample, sha256
HERE=Path(__file__).resolve().parent
SETTINGS={'argmax':(0,0),'app_default':(.9,.5),'full':(1,1),'reversed_numbers':(.5,.9)} # TopP, Temperature
SEED=20261002

def key(board):return ' '.join(board.fen().split()[:4])
def book_distribution(reader,board):
    entries=list(reader.find_all(board));total=sum(e.weight for e in entries)
    return {e.move.uci():e.weight/total for e in entries} if total else {}
def draw_dist(d,rng):
    u=rng.random()
    for m,p in d.items():
        u-=p
        if u<=0:return m
    return next(reversed(d))
def metrics(p,q):
    keys=set(p)|set(q);pv=np.array([p.get(k,0) for k in keys]);qv=np.array([q.get(k,0) for k in keys]);mix=(pv+qv)/2
    def entropy(v):return float(-sum(x*math.log2(x) for x in v if x>0))
    return {'tv':float(abs(pv-qv).sum()/2),'js_bits':entropy(mix)-(entropy(pv)+entropy(qv))/2,'human_entropy_bits':entropy(pv),'model_entropy_bits':entropy(qv),'excluded_human_mass':sum(v for k,v in p.items() if q.get(k,0)==0),'human_supported_model_mass':sum(v for k,v in q.items() if p.get(k,0)>0),'human_collision':float(sum(v*v for v in pv)),'model_collision':float(sum(v*v for v in qv))}

def conditional(policy):
    rows=[]
    for bi,name in enumerate(('lichess_1600_blitz_2026-05','lichess_1600_rapid_2026-05','lichess_1600_rapid_2026-07')):
        reader=chess.polyglot.open_reader(str(HERE/'source'/f'{name}.bin'));rng=random.Random(SEED+bi)
        # 150 independent human-book paths, all covered positions along each path.
        # Position visitation reflects book transition frequencies, not a handpicked opening list.
        paths=[]
        for i in range(150):
            b=chess.Board();path=[]
            for ply in range(16):
                human=book_distribution(reader,b)
                if not human:break
                l=policy.logits(b);record={'book':name,'trajectory':i,'ply':ply,'fen':b.fen(),'human':human,'settings':{}}
                for setting,(p,t) in SETTINGS.items():
                    moves,probs=distribution(b,l,p,t);model={m.uci():float(v) for m,v in zip(moves,probs)}
                    record['settings'][setting]={'distribution':model,**metrics(human,model)}
                rows.append(record);path.append(draw_dist(human,rng));b.push_uci(path[-1])
            paths.append(path)
            if i%30==0:print('conditional',name,i,'calls',policy.calls,flush=True)
        (HERE/f'human-book-paths-{name}.json').write_text(json.dumps(paths))
        reader.close()
    (HERE/'conditional.json').write_text(json.dumps(rows))
    return rows

def opening_map():
    rows=csv.DictReader((HERE/'source'/'lichess_openings.tsv').open(),delimiter='\t')
    return {r['epd']:(r['eco'],r['name'].split(':')[0]) for r in rows}

def rollout(policy,n=2000,plies=16):
    omap=opening_map();out=[];book=chess.polyglot.open_reader(str(HERE/'source'/'lichess_1600_blitz_2026-05.bin'))
    for si,(setting,(p,t)) in enumerate(SETTINGS.items()):
        if setting=='reversed_numbers':continue
        count=1 if setting=='argmax' else n
        rng=random.Random(SEED+100+si)
        for i in range(count):
            b=chess.Board();moves=[];labels=[];eco='none';family='Unclassified';support=[];human_surprisal=[]
            for ply in range(plies):
                if b.is_game_over():break
                h=book_distribution(book,b);m=sample(b,policy.logits(b),p,t,rng);moves.append(m.uci())
                support.append(bool(h))
                human_surprisal.append(-math.log2(max(h.get(m.uci(),0),1e-12)) if h else None)
                b.push(m)
                if key(b) in omap:eco,family=omap[key(b)]
                labels.append({'eco':eco,'family':family,'fen':key(b)})
            out.append({'setting':setting,'index':i,'moves':moves,'labels':labels,'book_covered':support,'human_surprisal_bits':human_surprisal})
            if i%100==0:
                print('rollout',setting,i,'calls',policy.calls,'hits',policy.hits,flush=True)
                (HERE/'rollouts.json').write_text(json.dumps(out))
        (HERE/'rollouts.json').write_text(json.dumps(out))
    book.close();return out

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--model',type=Path,default=MODEL79);parser.add_argument('--skip-conditional',action='store_true');parser.add_argument('--rollouts',type=int,default=2000);parser.add_argument('--plies',type=int,default=16);args=parser.parse_args()
    start=time.time();policy=Policy(model=args.model,threads=1,cache_limit=100000)
    if not args.skip_conditional:conditional(policy)
    rollout(policy,args.rollouts,args.plies)
    (HERE/'run.json').write_text(json.dumps({'seed':SEED,'settings':{k:{'top_p':p,'temperature':t} for k,(p,t) in SETTINGS.items() if k!='reversed_numbers'},'rollouts_per_stochastic_setting':args.rollouts,'plies':args.plies,'model':str(args.model),'model_sha256':sha256(args.model),'threads':1,'calls':policy.calls,'cache_hits':policy.hits,'elapsed_seconds':time.time()-start,'source_sha256':{f.name:sha256(f) for f in (HERE/'source').glob('*.bin')}},indent=2))

if __name__=='__main__':main()
