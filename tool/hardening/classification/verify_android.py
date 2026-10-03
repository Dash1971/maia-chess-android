#!/usr/bin/env python3
"""Replay Android score traces through pinned EC; no live engines or Dart helpers.

python verify_android.py --log /tmp/android.log --node /path/to/node
JSON goes to stdout; malformed traces and semantic mismatches exit nonzero.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
DEFAULT_FIXTURE = ROOT.parents[2] / 'test/fixtures/classification/stockfish18-fast.json'
STANDOUT = {'!', '!!'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def lines(score, key='lines'):
    return [dict(cp=line[0], mate=line[1], moves=line[2])
            if isinstance(line, list) else line for line in score.get(key, [])]


def value(score):
    return dict(type='mate' if score.get('mate') is not None else 'cp',
                value=score['mate'] if score.get('mate') is not None else score['cp'])


def terminal(fen):
    # Fail closed if python-chess is unavailable; only terminal evidence needs it.
    try:
        import chess
    except ImportError as error:
        raise ValueError('python-chess required to verify terminal score: '+fen) from error
    return chess.Board(fen).is_game_over()


def complete(score, fen, context):
    if not lines(score):
        require(terminal(fen), context+': missing PV at nonterminal position')
        return
    require(score.get('complete') is True and lines(score)[0]['moves'],
            context+': incomplete score/PV')


def case(scores, game, ply):
    before, after = scores[ply-1:ply+1]
    return dict(prevprev=value(scores[ply-2]) if ply > 1 else None,
                prev=value(before), next=value(after),
                color='white' if game['positions'][ply-1].split()[1] == 'w' else 'black',
                prevMoves=[dict(score=dict(value=value(line)), sanMoves=line['moves'])
                           for line in lines(before)],
                is_sacrifice=(bool(lines(after)) and
                    game['material'][ply-1] > -game['material'][ply]+100),
                move=game['moves'][ply-1])


def oracle(node, cases):
    return json.loads(subprocess.check_output(
        [node, str(ROOT/'reference/annotate.mjs')], input=json.dumps(cases), text=True))


def parse(path):
    pending, quality, runs = {}, None, []
    for number, text in enumerate(path.read_text().splitlines(), 1):
        match = re.search(r'ANDROID SCORE (fast|balanced|thorough) (\d+) (\{.*\})', text)
        if match:
            mode, index, payload = match.groups(); index = int(index)
            require(quality in (None, mode), f'line {number}: interleaved score modes')
            require(index not in pending, f'line {number}: duplicate score {index}')
            quality = mode; pending[index] = json.loads(payload)
        match = re.search(r'ANDROID RUN (\{.*\})', text)
        if match:
            report = json.loads(match[1])
            require(quality == report['quality'], f'line {number}: score/run mode mismatch')
            require(set(pending) == set(range(83)), f'line {number}: require indexed positions 0..82')
            require(len(report['annotations']) == 82, f'line {number}: require 82 annotations')
            runs.append((report, [pending[i] for i in range(83)]))
            pending, quality = {}, None
    require(not pending, 'truncated score group without ANDROID RUN')
    require(runs, 'no ANDROID RUN records')
    return runs


def verify(log, node, fixture):
    data = json.loads(fixture.read_text())
    game = next(g for g in data['runs'] if g['name'] == 'byrne-fischer-1956')
    require(len(game['positions']) == 83 and len(game['moves']) == 82,
            'fixture must contain complete Byrne–Fischer game')
    summaries, previous = [], {}
    for report, scores in parse(log):
        mode, index = report['quality'], report['runIndex']
        context = f'run {index} {mode}'
        for position, score in enumerate(scores):
            where = f'{context} position {position}'
            require(score['fen'] == game['positions'][position], where+': fixture FEN mismatch')
            complete(score, score['fen'], where)
            if lines(score):
                require(score['quality'] == mode, where+': invalid baseline quality')
                require(score['depth'] > 0, where+': invalid baseline depth')
                require(value(score) == value(lines(score)[0]), where+': scalar/PV mismatch')
            confirmation = score.get('annotationConfirmation')
            if confirmation:
                for key, dependency in [('before', position), ('after', position+1),
                                        ('beforePrevious', position-1)]:
                    candidate = confirmation.get(key)
                    if candidate is None:
                        require(key == 'beforePrevious', where+': missing confirmation '+key)
                        continue
                    require(0 <= dependency < 83, where+': invalid confirmation dependency')
                    complete(candidate, game['positions'][dependency], where+' '+key)
                    if lines(candidate):
                        require(candidate['quality'] == mode, where+': invalid confirmation quality')
                        require(candidate['depth'] >= (scores[dependency].get('depth') or 0),
                                where+': confirmation shallower than baseline')
                        require(value(candidate) == value(lines(candidate)[0]),
                                where+': confirmation scalar/PV mismatch')
        baseline = oracle(node, [case(scores, game, ply) for ply in range(1, 83)])
        labels = report['annotations']; withheld = []; windows = []; window_plies = []
        for ply, (actual, expected) in enumerate(zip(labels, baseline), 1):
            where = f'{context} ply {ply}'
            require(actual == expected or (expected in STANDOUT and actual == ''),
                    where+f': production {actual!r}, EC {expected!r}')
            if actual != expected:
                withheld.append(dict(ply=ply, reference=expected, production=actual))
            if actual not in STANDOUT:
                continue
            window = list(scores); before = scores[ply-1]
            confirmation = before.get('annotationConfirmation')
            dependencies = [ply-1, ply] + ([ply-2] if actual == '!' and ply > 1 else [])
            if confirmation:
                mapped = {ply-1: confirmation['before'], ply: confirmation['after']}
                if ply > 1 and confirmation.get('beforePrevious') is not None:
                    mapped[ply-2] = confirmation['beforePrevious']
                for dependency in dependencies:
                    require(dependency in mapped, where+': missing confirmation dependency')
                    candidate = mapped[dependency]
                    complete(candidate, game['positions'][dependency], where+' confirmation')
                    if lines(candidate):
                        require(candidate['quality'] == mode, where+': invalid confirmation quality')
                        require(candidate['depth'] >= (scores[dependency].get('depth') or 0),
                                where+': confirmation shallower than baseline')
                        require(value(candidate) == value(lines(candidate)[0]),
                                where+': confirmation scalar/PV mismatch')
                    window[dependency] = candidate
            else:
                for dependency in dependencies:
                    original = scores[dependency]; older = lines(original, 'previous')
                    if not older and not lines(original):
                        require(terminal(game['positions'][dependency]), where+': missing previous terminal proof')
                        continue
                    require(older and older[0]['moves'], where+f': missing previous iteration at {dependency}')
                    window[dependency] = dict(cp=older[0]['cp'], mate=older[0]['mate'], lines=older)
            windows.append(case(window, game, ply)); window_plies.append(ply)
        for ply, corroboration in zip(window_plies, oracle(node, windows)):
            require(corroboration == labels[ply-1],
                    f'{context} ply {ply}: confidence window EC {corroboration!r}, award {labels[ply-1]!r}')
        require(labels[22] != '!!', context+': Qa3 falsely Brilliant')
        require(all(labels[ply-1] == '!!' for ply in (22, 34, 38)),
                context+': required Black brilliancies missing at 22/34/38')
        changed = [ply for ply, (a, b) in enumerate(zip(previous.get(mode, labels), labels), 1) if a != b]
        if 'changedLabelPlies' in report:
            require(report['changedLabelPlies'] == changed, context+': incorrect run-order differences')
        previous[mode] = labels
        summaries.append(dict(runIndex=index, quality=mode, scenario=report.get('scenario'),
            positions=83, moves=82, elapsedMs=report.get('elapsedMs'),
            annotationCounts=dict(Counter(label or 'none' for label in labels)),
            verifiedStandouts=len(windows), withheld=withheld, changedLabelPlies=changed))
    return dict(ok=True, reference='En Croissant v0.15.0 pinned annotate.mjs',
                fixture=str(fixture), runs=summaries,
                positions=83*len(summaries), moves=82*len(summaries))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--log', type=Path, required=True)
    parser.add_argument('--node', default='node')
    parser.add_argument('--fixture', type=Path, default=DEFAULT_FIXTURE)
    args = parser.parse_args()
    try:
        result = verify(args.log, args.node, args.fixture)
    except (ValueError, KeyError, TypeError, IndexError, OSError, subprocess.CalledProcessError) as error:
        print(json.dumps(dict(ok=False, error=str(error))), file=sys.stdout)
        return 1
    print(json.dumps(result, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
