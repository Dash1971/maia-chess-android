#!/usr/bin/env python3
"""Generate independent legal PGN trees, including duplicate legacy branches."""

import argparse
import copy
import json
import random
from pathlib import Path

import chess
import chess.pgn


STARTS = [
    chess.STARTING_FEN,
    "r3k2r/ppp2ppp/2n5/3pp3/3PP3/2N5/PPP2PPP/R3K2R w KQkq - 0 1",
    "4k3/P6p/8/8/8/8/p6P/4K3 w - - 0 30",
    "4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 20",
    "4k3/8/8/8/3Pp3/8/8/4K3 b - d3 0 20",
]


def generate_case(rng, index):
    game = chess.pgn.Game()
    game.setup(chess.Board(STARTS[index % len(STARTS)]))
    game.headers["Event"] = f"Variation oracle {index}"
    game.headers["Result"] = "*"
    counter = 0

    def extend(parent, length):
        nonlocal counter
        board = parent.board()
        for _ in range(length):
            legal = sorted(board.legal_moves, key=lambda move: move.uci())
            if not legal:
                break
            unused = [move for move in legal if not parent.has_variation(move)]
            if not unused:
                break
            move = rng.choice(unused)
            parent = parent.add_variation(move)
            board.push(move)
            counter += 1
            parent.comment = f"Note {index}-{counter}"
            parent.nags.add(1 + counter % 6)
        return parent

    extend(game, 8 + index % 9)
    # Add genuine alternatives at multiple depths, including inside variations.
    for _ in range(10):
        nodes = [game]
        for node in nodes:
            nodes.extend(node.variations)
        extend(rng.choice(nodes), rng.randint(1, 6))

    mainline = [move.uci() for move in game.mainline_moves()]
    end = game.end().board().fen()
    expected = {}
    leaves = []

    def inspect(node, prefix):
        for child in node.variations:
            path = (*prefix, child.move.uci())
            expected[" ".join(path)] = {
                "comments": [child.comment] if child.comment else [],
                "nags": sorted(child.nags),
            }
            if not child.variations:
                leaves.append(" ".join(path))
            inspect(child, path)

    inspect(game, ())
    # Clone whole abandoned lines as older saves did. The expected result above
    # is computed before duplication and is independent of Dart's tree model.
    nodes = [game]
    for node in nodes:
        nodes.extend(node.variations)
    candidates = [node for node in nodes if len(node.variations) > 1]

    def clone(source, parent):
        target = parent.add_variation(source.move)
        target.comment = source.comment
        target.nags = copy.copy(source.nags)
        for child in source.variations:
            clone(child, target)

    for parent in rng.sample(candidates, min(4, len(candidates))):
        clone(parent.variations[1], parent)
    return {
        "pgn": game.accept(chess.pgn.StringExporter(columns=None)),
        "mainline": mainline,
        "endFen": end,
        "nodes": expected,
        "leaves": sorted(leaves),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cases", type=int, default=32)
    parser.add_argument("--seed", type=int, default=20260910)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.cases < 1:
        parser.error("--cases must be positive")
    rng = random.Random(args.seed)
    corpus = {
        "seed": args.seed,
        "generator": f"python-chess {chess.__version__}",
        "cases": [generate_case(rng, index) for index in range(args.cases)],
    }
    args.output.write_text(json.dumps(corpus, separators=(",", ":")) + "\n")
    print(f"Wrote {args.cases} variation trees to {args.output}")


if __name__ == "__main__":
    main()
