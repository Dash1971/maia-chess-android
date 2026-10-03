#!/usr/bin/env python3
"""Optional offline classification differential/benchmark corpus (python-chess).
Uses an explicitly supplied local Stockfish and pinned Rust/TS reference runners.
No games are downloaded or uploaded. Ordinary Flutter tests replay the fixture.
"""
import argparse
import json
import queue
import random
import re
import subprocess
import threading
import time
from pathlib import Path
import chess

ROOT = Path(__file__).resolve().parent
GAMES = {
    'byrne-fischer-1956': 'Nf3 Nf6 c4 g6 Nc3 Bg7 d4 O-O Bf4 d5 Qb3 dxc4 Qxc4 c6 e4 Nbd7 Rd1 Nb6 Qc5 Bg4 Bg5 Na4 Qa3 Nxc3 bxc3 Nxe4 Bxe7 Qb6 Bc4 Nxc3 Bc5 Rfe8+ Kf1 Be6 Bxb6 Bxc4+ Kg1 Ne2+ Kf1 Nxd4+ Kg1 Ne2+ Kf1 Nc3+ Kg1 axb6 Qb4 Ra4 Qxb6 Nxd1 h3 Rxa2 Kh2 Nxf2 Re1 Rxe1 Qd8+ Bf8 Nxe1 Bd5 Nf3 Ne4 Qb8 b5 h4 h5 Ne5 Kg7 Kg1 Bc5+ Kf1 Ng3+ Ke1 Bb4+ Kd1 Bb3+ Kc1 Ne2+ Kb1 Nc3+ Kc1 Rc2#',
    'opera-1858': 'e4 e5 Nf3 d6 d4 Bg4 dxe5 Bxf3 Qxf3 dxe5 Bc4 Nf6 Qb3 Qe7 Nc3 c6 Bg5 b5 Nxb5 cxb5 Bxb5+ Nbd7 O-O-O Rd8 Rxd7 Rxd7 Rd1 Qe6 Bxd7+ Nxd7 Qb8+ Nxb8 Rd8#',
    'ruy-lopez': 'e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 d6 c3 O-O h3 Nb8 d4 Nbd7 c4 c6 cxb5 axb5 Nc3 Bb7 Bg5 b4 Nb1 h6',
}

def corpus():
    games = []
    for name, sans in GAMES.items():
        board = chess.Board()
        positions, moves = [board.fen()], []
        for san in sans.split():
            move = board.parse_san(san)
            moves.append(move.uci())
            board.push(move)
            positions.append(board.fen())
        games.append(dict(name=name, positions=positions, moves=moves))
    # Seeded ordinary legal play, both colours, non-standard initial positions.
    seeds = [(20261001, chess.STARTING_FEN, 80),
             (20261002, '4k3/P7/8/8/8/8/7p/4K3 w - - 0 1', 20),
             (20261003, '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1', 20)]
    for seed, fen, plies in seeds:
        rng, board = random.Random(seed), chess.Board(fen)
        positions, moves = [board.fen()], []
        for _ in range(plies):
            if board.is_game_over(): break
            move = rng.choice(sorted(board.legal_moves, key=lambda m: m.uci()))
            moves.append(move.uci()); board.push(move); positions.append(board.fen())
        games.append(dict(name=f'seed-{seed}', positions=positions, moves=moves))
    return games

class Engine:
    def __init__(self, path, threads):
        self.process = subprocess.Popen([path], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                        stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.output = queue.Queue()
        def read():
            for line in self.process.stdout: self.output.put(line.strip())
            self.output.put(None)
        self.reader = threading.Thread(target=read, daemon=True); self.reader.start()
        self.send('uci'); self.identity = self.until('uciok')
        for option in [f'Threads value {threads}', 'Hash value 64', 'MultiPV value 2']:
            self.send('setoption name ' + option)
        self.ready()
    def send(self, command):
        self.process.stdin.write(command+'\n'); self.process.stdin.flush()
    def until(self, token):
        lines = []
        while True:
            line = self.output.get(timeout=30)
            if line is None: raise RuntimeError('engine exited')
            lines.append(line)
            if line.startswith(token): return lines
    def ready(self): self.send('isready'); self.until('readyok')
    def reset(self): self.send('ucinewgame'); self.ready()
    def search(self, fen, quality):
        board = chess.Board(fen)
        if board.is_game_over():
            mate = (-1 if board.turn else 1) if board.is_checkmate() else None
            return dict(raw=[], cp=0, mate=mate, lines=[], depth=0, nodes=0, timeMs=0)
        self.send('position fen '+fen)
        depth, ms = {'fast': (12,500), 'balanced': (14,1000), 'thorough':(16,1500)}[quality]
        self.send(f'go depth {depth} movetime {ms}')
        raw = self.until('bestmove ')
        # Independent EC-style ordered complete-iteration reference collector.
        pending, completed, completed_depth = [], None, -1
        for text in raw:
            if not text.startswith('info '): continue
            def num(field):
                match = re.search(r' '+field+r' (-?\d+)', text)
                return int(match[1]) if match else None
            d, rank, cp, mate = num('depth'), num('multipv') or 1, num('score cp'), num('score mate')
            pv = text.split(' pv ')[1].split() if ' pv ' in text else []
            if d is None or not pv or (cp is None and mate is None): continue
            if 'bound' in text: continue
            if rank != len(pending)+1: pending = []
            if rank != len(pending)+1: continue
            sign = 1 if board.turn else -1
            pending.append(dict(depth=d, cp=(cp or 0)*sign,
                                mate=mate*sign if mate is not None else None, moves=pv,
                                nodes=num('nodes'), timeMs=num('time')))
            if rank == min(2, board.legal_moves.count()):
                if all(p['depth']==d for p in pending) and d >= completed_depth:
                    completed, completed_depth = pending, d
                pending = []
        if not completed: raise RuntimeError('No complete iteration at '+fen)
        # Retain last two completed depths and any unfinished next iteration.
        retained = [s for s in raw if not s.startswith('info ') or
                    (re.search(r' depth (\d+)',s) and int(re.search(r' depth (\d+)',s)[1]) >= completed_depth-1)]
        return dict(raw=retained, cp=completed[0]['cp'], mate=completed[0]['mate'],
                    lines=completed, depth=completed_depth,
                    nodes=completed[0]['nodes'], timeMs=completed[0]['timeMs'],
                    quality=quality, complete=True)
    def close(self):
        self.send('quit'); self.process.wait(timeout=10); self.reader.join(timeout=2)
        self.process.stdin.close(); self.process.stdout.close()

def annotate(game, material, node):
    cases=[]
    def score(s): return dict(type='mate' if s['mate'] is not None else 'cp', value=s['mate'] if s['mate'] is not None else s['cp'])
    for ply, move in enumerate(game['moves'], 1):
        before, after = game['scores'][ply-1:ply+1]
        # Upstream skips terminal positions when making sacrifice flags. Keep
        # final mate on Mobile Maia's graph, but do not award it as a sacrifice.
        sacrifice = not chess.Board(game['positions'][ply]).is_game_over() and material[ply-1] > -material[ply]+100
        cases.append(dict(prevprev=score(game['scores'][ply-2]) if ply>1 else None,
            prev=score(before), next=score(after),
            color='white' if chess.Board(game['positions'][ply-1]).turn else 'black',
            prevMoves=[dict(score=dict(value=score(line)),sanMoves=line['moves']) for line in before['lines']],
            is_sacrifice=sacrifice,move=move))
    return json.loads(subprocess.check_output([node,str(ROOT/'reference/annotate.mjs')], input=json.dumps(cases), text=True))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--stockfish',required=True); parser.add_argument('--reference',required=True)
    parser.add_argument('--node',default='node'); parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--threads',type=int,default=1)
    parser.add_argument('--sequence', default='fast,balanced,thorough,fast',
                        help='ordered qualities; repeated modes expose run-order variation')
    parser.add_argument('--fresh-process', action='store_true',
                        help='start a fresh engine for each run (stronger than a hash reset)')
    parser.add_argument('--warm',action='store_true',help='omit run-boundary reset to reproduce old behaviour')
    parser.add_argument('--game',help='run only a named game'); parser.add_argument('--reverse',action='store_true')
    args=parser.parse_args(); games=corpus()
    sequence=args.sequence.split(',')
    if not sequence or any(q not in ('fast', 'balanced', 'thorough') for q in sequence):
        parser.error('--sequence must contain fast, balanced or thorough')
    if args.fresh_process and args.warm:
        parser.error('--fresh-process and --warm are mutually exclusive')
    if args.game:
        games=[g for g in games if g['name']==args.game]
        if not games: parser.error('unknown --game')
    if args.reverse: games.reverse()
    for game in games:
        # Terminal Rust MIN sentinel is kept in the reference data and compared
        # separately; Dart intentionally returns a finite terminal material.
        raw=subprocess.check_output([args.reference],input='\n'.join(game['positions'])+'\n',text=True)
        game['material']=[int(v) for v in raw.splitlines()]
    engine=Engine(args.stockfish,args.threads); runs=[]
    try:
        for sequence_index, quality in enumerate(sequence):
            for original in games:
                if args.fresh_process and runs:
                    engine.close(); engine=Engine(args.stockfish,args.threads)
                game=dict(original,quality=quality,sequenceIndex=sequence_index,
                          scenario='fresh-process' if args.fresh_process else 'warm' if args.warm else 'cold')
                if not args.warm: engine.reset()
                start=time.monotonic()
                game['scores']=[engine.search(fen,quality) for fen in game['positions']]
                game['wallSeconds']=round(time.monotonic()-start,3)
                game['annotations']=annotate(game,game['material'],args.node)
                runs.append(game)
                print(game['name'],quality,game['wallSeconds'],[(i+1,a) for i,a in enumerate(game['annotations']) if a],flush=True)
    finally: engine.close()
    args.output.parent.mkdir(parents=True,exist_ok=True)
    observations=[]
    for index, run in enumerate(runs):
        previous=next((r for r in reversed(runs[:index])
                       if r['name']==run['name'] and r['quality']==run['quality']), None)
        if previous is not None:
            observations.append(dict(name=run['name'], quality=run['quality'],
                sequenceIndex=run['sequenceIndex'],
                changedLabels=[i+1 for i,(a,b) in enumerate(zip(previous['annotations'],run['annotations'])) if a!=b],
                changedScores=[i for i,(a,b) in enumerate(zip(previous['scores'],run['scores']))
                               if (a['cp'],a['mate'],[(l['cp'],l['mate'],l['moves']) for l in a['lines']]) !=
                                  (b['cp'],b['mate'],[(l['cp'],l['mate'],l['moves']) for l in b['lines']])]))
    args.output.write_text(json.dumps(dict(reference='En Croissant v0.15.0', engine=engine.identity,
        threads=args.threads,hashMiB=64,reset=not args.warm,
        freshProcess=args.fresh_process,sequence=sequence,observations=observations,runs=runs),indent=2)+'\n')
if __name__=='__main__': main()
