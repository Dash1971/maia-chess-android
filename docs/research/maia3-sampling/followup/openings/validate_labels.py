"""Audit saved seeds, initial support and carry-forward labels; no inference."""
import argparse,collections,csv,json,time
from pathlib import Path
import chess
from conditional import HERE
from mobile_policy import sha256

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--source-study',type=Path,required=True);args=ap.parse_args();source=args.source_study.resolve()/'openings';start=time.time()
    run=json.loads((HERE/'run.json').read_text());tsv=source/'source/lichess_openings.tsv'
    assert sha256(tsv)==run['source_sha256']['opening_labels']
    omap={r['epd']:(r['eco'],r['name'].split(':')[0]) for r in csv.DictReader(tsv.open(),delimiter='\t')}
    new=json.loads((HERE/'rollouts95.json').read_text());old=json.loads((source/'rollouts.json').read_text())
    rows={'full95':new,'full':[r for r in old if r['setting']=='full'],'app_default':[r for r in old if r['setting']=='app_default']}
    exact=json.loads((HERE/'exact-policy95.json').read_text());support=set(next(iter(exact.values()))['first_move']['full95'])
    assert support=={'e2e4','d2d4','c2c4','g1f3','e2e3'};checks=collections.Counter()
    for setting,games in rows.items():
        assert len(games)==2000 and {r['index'] for r in games}==set(range(2000))
        for r in games:
            if setting=='full95':assert r['seed']==7000000000+r['index'] and r['moves'][0] in support
            b=chess.Board();eco='none';family='Unclassified'
            for move,label in zip(r['moves'],r['labels']):
                b.push_uci(move);epd=' '.join(b.fen().split()[:4])
                if epd in omap:eco,family=omap[epd]
                assert label=={'eco':eco,'family':family,'fen':epd},(setting,r['index'],move,label,eco,family)
                checks[setting]+=1
    out={'status':'passed','games_per_setting':{k:len(v) for k,v in rows.items()},'label_checks':dict(checks),
         'expected_new_first_move_support':sorted(support),'observed_new_first_move_counts':dict(collections.Counter(r['moves'][0] for r in new)),
         'new_seed_checks':2000,'opening_tsv_sha256':sha256(tsv),'script_sha256':sha256(Path(__file__)),'seconds':time.time()-start}
    (HERE/'label-seed-validation95.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))

if __name__=='__main__':main()
