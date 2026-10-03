#!/usr/bin/env python3
"""Optional verifier adversarial checks against a supplied real live report.

No engine search. Requires the same Node/python-chess dependencies as verify_live.
Example: python verify_live_selftest.py --report /tmp/live.json --node /path/to/node
The supplied report must contain at least one prior-iteration standout award.
"""
import argparse
from copy import deepcopy
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from verify_live import DEFAULT_FIXTURE, STANDOUT, require, verify


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report',type=Path,required=True)
    parser.add_argument('--fixture',type=Path,default=DEFAULT_FIXTURE)
    parser.add_argument('--node',default='node')
    args = parser.parse_args()
    original = json.loads(args.report.read_text())
    require(verify(args.report,args.node,args.fixture)['ok'], 'input must qualify first')
    candidates = [(r,p) for r,run in enumerate(original['runs'])
                  for p,label in enumerate(run['annotations'],1)
                  if label in STANDOUT and not run['scores'][p-1].get('annotationConfirmation')
                  and run['scores'][p].get('previousLines')]
    require(candidates, 'input needs a prior-iteration award')
    run_index,ply = candidates[0]
    def scalar(data):
        data['runs'][run_index]['scores'][ply-1]['cp'] += 1
    def quality(data):
        data['runs'][run_index]['scores'][ply-1]['quality'] = 'invalid'
    def missing_previous(data):
        data['runs'][run_index]['scores'][ply]['previousLines'] = []
    def unstable_loss(data):
        run = data['runs'][run_index]
        white = run['scores'][ply-1]['fen'].split()[1] == 'w'
        older = run['scores'][ply]['previousLines'][0]
        older.update(cp=-1000 if white else 1000,mate=None)
    mutations = {'scalar-pv':scalar,'wrong-quality':quality,
                 'missing-iteration':missing_previous,'unstable-loss':unstable_loss}
    with TemporaryDirectory(prefix='maia-verifier-') as temp:
        for name,mutation in mutations.items():
            data = deepcopy(original); mutation(data)
            path = Path(temp)/f'{name}.json'; path.write_text(json.dumps(data))
            try:
                verify(path,args.node,args.fixture)
            except ValueError as error:
                print(f'PASS rejected {name}: {error}')
            else:
                raise AssertionError('verifier accepted corrupted '+name)
    print('PASS valid report and four independent corruptions')


if __name__ == '__main__':
    main()
