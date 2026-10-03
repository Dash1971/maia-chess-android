"""New T=1, inclusive TopP=.95 self-play openings; local only."""
import argparse,csv,json,random,sys,time,platform,importlib.metadata
from pathlib import Path
import chess,chess.polyglot
from mobile_policy import Policy,sha256,sample

HERE=Path(__file__).resolve().parent
SEED=7000000000

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--model',type=Path,required=True)
    ap.add_argument('--source-study',type=Path,required=True)
    args=ap.parse_args();source=args.source_study.resolve();args.model=args.model.resolve()
    files={'conditional':source/'openings/conditional.json','human':source/'openings/human-sample.json',
           'old_rollouts':source/'openings/rollouts.json','opening_labels':source/'openings/source/lichess_openings.tsv',
           'book':source/'openings/source/lichess_1600_blitz_2026-05.bin','model':args.model,
           'rollout_source':Path(__file__),'helper':HERE/'mobile_policy.py'}
    meta={'status':'running','temperature':1.,'top_p':.95,'cutoff':'include crossing move',
          'self_elo':1600,'opponent_elo':1600,'games':2000,'plies':16,'threads':1,
          'seed_start':SEED,'seed_rule':'random.Random(seed_start + game_index), independent game streams',
          'source_study':str(source),'model':str(args.model),
          'source_sha256':{k:sha256(v) for k,v in files.items()},'python':platform.python_version(),
          'packages':{k:importlib.metadata.version(k) for k in ('onnxruntime','numpy','python-chess')}}
    (HERE/'run-start.json').write_text(json.dumps(meta,indent=2))
    omap={r['epd']:(r['eco'],r['name'].split(':')[0]) for r in csv.DictReader(files['opening_labels'].open(),delimiter='\t')}
    book=chess.polyglot.open_reader(str(files['book']));policy=Policy(model=args.model,threads=1,cache_limit=100000)
    out=[];start=time.time()
    for i in range(2000):
        b=chess.Board();rng=random.Random(SEED+i);moves=[];labels=[];support=[];eco='none';family='Unclassified'
        for ply in range(16):
            if b.is_game_over():break
            support.append(any(book.find_all(b)))
            move=sample(b,policy.logits(b,1600,1600),.95,1.,rng);moves.append(move.uci());b.push(move)
            epd=' '.join(b.fen().split()[:4])
            if epd in omap:eco,family=omap[epd]
            labels.append({'eco':eco,'family':family,'fen':epd})
        out.append({'setting':'full95','index':i,'seed':SEED+i,'moves':moves,'labels':labels,'book_covered':support})
        if (i+1)%100==0:
            progress={'completed':i+1,'target':2000,'calls':policy.calls,'cache_hits':policy.hits,'seconds':time.time()-start}
            (HERE/'rollouts95.json').write_text(json.dumps(out));(HERE/'progress.json').write_text(json.dumps(progress,indent=2))
            print(json.dumps(progress),flush=True)
    book.close();meta.update(status='complete',completed=len(out),calls=policy.calls,cache_hits=policy.hits,seconds=time.time()-start)
    (HERE/'rollouts95.json').write_text(json.dumps(out));(HERE/'run.json').write_text(json.dumps(meta,indent=2))
    print('COMPLETE',json.dumps(meta),flush=True)

if __name__=='__main__':main()
