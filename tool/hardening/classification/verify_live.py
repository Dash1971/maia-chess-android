#!/usr/bin/env python3
"""Independently replay live JSON baselines and every standout confidence window.

Uses the pinned EC Node oracle and corpus Rust material, without Dart helpers or
live engines. Supports any corpus game and old reports lacking proof records.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import subprocess
import sys

from verify_android import (DEFAULT_FIXTURE, STANDOUT, case, complete, lines,
                            oracle, require, terminal, value)


def verify(path, node, fixture, game_name=None):
    corpus = json.loads(fixture.read_text())['runs']
    reports = json.loads(path.read_text())['runs']
    summaries, previous = [], {}
    require(reports, 'empty live report')
    for report in reports:
        name = report.get('name', game_name or corpus[0]['name'])
        game = next(g for g in corpus if g['name'] == name)
        scores = report['scores']; labels = report['annotations']
        mode = report['quality']; context = f'{name} {mode} run {report.get("runIndex")}'
        count = len(game['moves'])
        require(len(scores) == count + 1 and len(labels) == count, context+': truncated data')
        for position, score in enumerate(scores):
            where = f'{context} position {position}'
            require(score['fen'] == game['positions'][position], where+': FEN mismatch')
            complete(score, score['fen'], where)
            if lines(score):
                require(score['quality'] == mode and score['depth'] > 0,
                        where+': invalid baseline quality/depth')
                require(value(score) == value(lines(score)[0]), where+': scalar/PV mismatch')
            confirmation = score.get('annotationConfirmation')
            if confirmation:
                for key, dependency in [('before',position), ('after',position+1),
                                        ('beforePrevious',position-1)]:
                    checked = confirmation.get(key)
                    if checked is None:
                        require(key == 'beforePrevious', where+': missing '+key)
                        continue
                    require(0 <= dependency <= count, where+': invalid dependency')
                    complete(checked, game['positions'][dependency], where+' '+key)
                    if lines(checked):
                        require(checked['quality'] == mode, where+': confirmation quality mismatch')
                        require(checked['depth'] >= (scores[dependency].get('depth') or 0),
                                where+': confirmation shallower than baseline')
                        require(value(checked) == value(lines(checked)[0]),
                                where+': confirmation scalar/PV mismatch')
        baseline = oracle(node, [case(scores, game, p) for p in range(1,count+1)])
        if 'oracleAnnotations' in report:
            require(report['oracleAnnotations'] == baseline, context+': saved oracle differs')
        windows, proofs, withheld = [], [], []
        for ply, (actual, expected) in enumerate(zip(labels, baseline),1):
            where = f'{context} ply {ply}'
            require(actual == expected or (expected in STANDOUT and actual == ''),
                    where+f': production {actual!r}, EC {expected!r}')
            if actual != expected: withheld.append(dict(ply=ply, reference=expected))
            if actual not in STANDOUT: continue
            window = list(scores); confirmation = scores[ply-1].get('annotationConfirmation')
            dependencies = [ply-1,ply]+([ply-2] if actual == '!' and ply > 1 else [])
            kind = 'independent' if confirmation else 'prior-iteration'
            mapping = {ply-1: confirmation['before'], ply: confirmation['after']} if confirmation else {}
            if confirmation and confirmation.get('beforePrevious') is not None:
                mapping[ply-2] = confirmation['beforePrevious']
            for dependency in dependencies:
                if confirmation:
                    require(dependency in mapping, where+': missing confirmation dependency')
                    window[dependency] = mapping[dependency]
                else:
                    older = lines(scores[dependency], 'previousLines')
                    if not older and not lines(scores[dependency]):
                        require(terminal(game['positions'][dependency]), where+': nonterminal missing previous')
                        continue
                    require(older and older[0]['moves'], where+': missing previous iteration')
                    window[dependency] = dict(cp=older[0]['cp'],mate=older[0]['mate'],lines=older)
            windows.append(case(window,game,ply))
            proofs.append(dict(ply=ply,kind=kind,dependencies=[
                dict(position=d,fen=game['positions'][d],cp=window[d]['cp'],
                     mate=window[d].get('mate'),lines=lines(window[d])) for d in dependencies]))
        for proof, symbol in zip(proofs, oracle(node,windows)):
            require(symbol == labels[proof['ply']-1],
                    context+f': confidence window EC mismatch at ply {proof["ply"]}')
            proof['symbol'] = symbol
        # New reports retain each proof; verify both coverage and exact scores.
        saved = report.get('confirmationOracles', [])
        if saved and all('kind' in proof for proof in saved):
            require(len(saved) == len(proofs), context+': proof coverage mismatch')
            for a,b in zip(saved,proofs):
                require((a['ply'],a['kind'],a['symbol']) == (b['ply'],b['kind'],b['symbol']),
                        context+': saved proof identity mismatch')
                require([{k:d[k] for k in ('position','fen','cp','mate','lines')}
                         for d in a['dependencies']] == b['dependencies'],
                        context+': saved proof window mismatch')
        key = (name,mode)
        changed = [p for p,(a,b) in enumerate(zip(previous.get(key,labels),labels),1) if a != b]
        if 'changedLabelPlies' in report:
            require(changed == report['changedLabelPlies'], context+': incorrect order observations')
        previous[key] = labels
        summaries.append(dict(name=name,quality=mode,scenario=report.get('scenario'),
            runIndex=report.get('runIndex'),positions=count+1,moves=count,
            annotationCounts=dict(Counter(s or 'none' for s in labels)),
            withheld=withheld,changedLabelPlies=changed,confidenceWindows=proofs))
    return dict(ok=True,reference='En Croissant v0.15.0 pinned annotate.mjs',runs=summaries)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report',type=Path,required=True)
    parser.add_argument('--fixture',type=Path,default=DEFAULT_FIXTURE)
    parser.add_argument('--game',help='game name for legacy reports without name')
    parser.add_argument('--node',default='node')
    args = parser.parse_args()
    try:
        result = verify(args.report,args.node,args.fixture,args.game)
    except (ValueError,KeyError,TypeError,IndexError,StopIteration,OSError,subprocess.CalledProcessError) as error:
        print(json.dumps(dict(ok=False,error=str(error))))
        return 1
    print(json.dumps(result,indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
