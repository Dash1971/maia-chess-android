#!/usr/bin/env python3
"""Wait for all fixed-N workers to finish, then verify and analyze locally."""
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def complete(shard):
    log = ROOT/f'shard{shard}-progress.log'
    if not log.exists():
        return False
    for line in log.read_text().splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if row.get('shard') == shard and row.get('complete') == 200:
            return True
    return False


def run(script, arguments, log):
    command = [sys.executable, str(ROOT/script), *map(str, arguments)]
    with (ROOT/log).open('w') as file:
        subprocess.run(command, stdout=file, stderr=subprocess.STDOUT, check=True)
    print(json.dumps({'finished': script, 'log': log}), flush=True)


def main():
    while not all(complete(shard) for shard in range(6)):
        time.sleep(30)
    directories = [ROOT/f'shard{shard}' for shard in range(6)]
    inputs = [directory/'games.jsonl' for directory in directories]
    run('verify_results.py', [*directories, '--output', ROOT/'integrity.json'], 'integrity.log')
    run('analyze_results.py', [*inputs, '--output', ROOT/'results-primary.json'], 'results-primary.log')
    run('claim_sensitivity.py', [*inputs, '--output', ROOT/'claim-sensitivity'], 'claim-sensitivity.log')
    run('verify_claim_sensitivity.py', ['--primary', *inputs, '--sensitivity', ROOT/'claim-sensitivity',
                                     '--output', ROOT/'integrity-claim-sensitivity.json'],
        'integrity-claim-sensitivity.log')
    run('analyze_results.py', [ROOT/'claim-sensitivity/games.jsonl', '--output',
                             ROOT/'results-claim-sensitivity.json'], 'results-claim-sensitivity.log')
    print('All fixed-N artifacts verified and analyzed.', flush=True)


if __name__ == '__main__':
    main()
