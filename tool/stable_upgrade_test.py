import copy
import unittest

import chess.pgn

from verify_release_upgrade import (check_baseline, check_restored, legacy_semantics,
                                    parse_pgn, seed_record, semantics)


def old_checkpoint(seed):
    record = copy.deepcopy(seed)
    record['data']['pgn'] = parse_pgn(seed['data']['pgn']).accept(
        chess.pgn.StringExporter(headers=True, variations=False, comments=False))
    return record


class StableUpgradeTest(unittest.TestCase):
    def test_legacy_forced_result_can_only_clear_for_the_same_natural_outcome(self):
        before = seed_record('1. f3 e5 2. g4 Qh4# 0-1', True)
        after = copy.deepcopy(before)
        after['data']['forcedResult'] = None
        self.assertTrue(check_restored(before, after, True)['natural_result_normalized'])
        with self.assertRaisesRegex(ValueError, 'forcedResult'):
            check_restored(before, after)
        after['data']['forcedResult'] = '1-0'
        with self.assertRaisesRegex(ValueError, 'forcedResult'):
            check_restored(before, after, True)
        unfinished = seed_record('1. e4 e5 1-0', True)
        after = copy.deepcopy(unfinished)
        after['data']['forcedResult'] = None
        with self.assertRaisesRegex(ValueError, 'forcedResult'):
            check_restored(unfinished, after, True)

    def test_legacy_branches_notes_nags_and_nested_forks_survive(self):
        pgn = '1. e4 ({Alternative} 1. d4 {Queen pawn} $1 d5 (1... Nf6 {Indian} $2) 2. c4) e5 1-0'
        fixture = seed_record(pgn, True)
        before = old_checkpoint(fixture)
        self.assertNotIn('Queen pawn', before['data']['pgn'])
        self.assertEqual(legacy_semantics(before), semantics(pgn))
        check_baseline(fixture, before, True)
        self.assertEqual(check_restored(before, fixture, True)['distinct_complete_lines'], 3)
        for source, replacement in [('Queen pawn', 'Lost'), ('$2', ''), ('Nf6 {Indian} $2', 'e6')]:
            after = copy.deepcopy(fixture)
            after['data']['pgn'] = pgn.replace(source, replacement)
            with self.assertRaises(ValueError):
                check_restored(before, after, True)
        broken = copy.deepcopy(before)
        broken['data']['variations'] = []
        with self.assertRaises(ValueError):
            check_baseline(fixture, broken, True)
        broken = copy.deepcopy(before)
        broken['data']['variations'][0]['baseFen'] = before['data']['positions'][-1]
        with self.assertRaisesRegex(ValueError, 'base FEN'):
            legacy_semantics(broken)

    def test_legacy_black_to_move_and_duplicate_branches(self):
        pgn = ('[SetUp "1"]\n[FEN "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"]\n'
               '\n1... e5 (1... c5 {Sicilian}) (1... c5 {Sicilian}) 2. Nf3 *')
        fixture = seed_record(pgn, True)
        before = old_checkpoint(fixture)
        self.assertEqual(legacy_semantics(before), semantics(pgn))
        after = copy.deepcopy(fixture)
        after['data']['pgn'] = pgn.replace(' (1... c5 {Sicilian})', '', 1)
        result = check_restored(before, after, True)
        self.assertEqual(result['duplicate_lines_before'], 1)
        self.assertEqual(result['duplicate_lines_after'], 0)
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            check_restored(before, fixture, True)

    def test_baseline_must_retain_the_fixture_not_silently_drop_annotations(self):
        fixture = seed_record('1. e4 (1. d4 {Note} d5) e5 1-0')
        with self.assertRaises(ValueError):
            check_baseline(fixture, old_checkpoint(fixture))
        with self.assertRaisesRegex(ValueError, 'played main line'):
            seed_record('1. e4 {A note old live games do not store} e5 *', True)

    def test_added_clocks_are_checked_against_history_not_ignored(self):
        before = seed_record('1. e4 {Keep me} (1. d4 {Alternative} d5) e5 1-0')
        after = copy.deepcopy(before)
        after['data']['pgn'] = ('1. e4 {Keep me} {[%clk 0:14:59.863]} '
                                '(1. d4 {Alternative} d5) e5 {[%clk 0:14:59.852]} 1-0')
        self.assertEqual(check_restored(before, after)['validated_new_clock_annotations'], 2)
        check_baseline(before, after)
        for source, replacement in [('59.863', '59.864'), ('59.852', '59.863'),
                                    ('{Keep me}', ''), ('{Alternative}', '{Alternative} {[%clk 0:14:59.863]}')]:
            broken = copy.deepcopy(after)
            broken['data']['pgn'] = after['data']['pgn'].replace(source, replacement)
            with self.assertRaises(ValueError):
                check_restored(before, broken)
        unlimited = copy.deepcopy(before)
        unlimited['data']['timePreset'] = 'unlimited'
        with self.assertRaises(ValueError):
            check_restored(unlimited, after)
        missing_existing_clock = copy.deepcopy(after)
        missing_existing_clock['data']['pgn'] = before['data']['pgn']
        with self.assertRaises(ValueError):
            check_restored(after, missing_existing_clock)


if __name__ == '__main__':
    unittest.main()
