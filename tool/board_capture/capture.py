#!/usr/bin/env python3
"""Explicit local Chessnut capture. No app dependency; replay never contacts BLE."""
import argparse
import asyncio
import json
import os
from pathlib import Path
import re
import time

class CaptureError(ValueError):
    """A fixed, privacy-safe validation message."""


SCHEMA = 'mobile-maia-board-capture-v1'
DEFAULT_DIR = Path(__file__).resolve().parent / 'captures'
MAX_BYTES = 4 * 1024 * 1024
MAX_FRAMES = 10000
MAX_FRAME_BYTES = 512
UUIDS = {
    'data': '1b7e8262-2877-41c3-b46e-cf057c562023',
    'confirm': '1b7e8273-2877-41c3-b46e-cf057c562023',
    'write': '1b7e8272-2877-41c3-b46e-cf057c562023',
}
MODELS = {'go', 'air', 'air-plus', 'pro', 'unspecified'}


def header(model='unspecified', firmware=None):
    result = {'schema': SCHEMA, 'board': 'chessnut', 'model': model}
    if firmware is not None:
        result['firmware'] = firmware
    validate_header(result)
    return result


def validate_header(value):
    if not isinstance(value, dict) or set(value) - {'schema', 'board', 'model', 'firmware'}:
        raise CaptureError('Unexpected metadata fields; remove identifiers before sharing.')
    if value.get('schema') != SCHEMA or value.get('board') != 'chessnut' or value.get('model') not in MODELS:
        raise CaptureError('Unsupported capture schema or board model.')
    firmware = value.get('firmware')
    if firmware is not None and (not isinstance(firmware, str) or
                                not re.fullmatch(r'v?\d{1,3}(?:\.\d{1,3}){1,3}', firmware)):
        raise CaptureError('Firmware must be a numeric version, not a device identifier.')


def validate_frame(value, previous_ms=0):
    if not isinstance(value, dict) or set(value) != {'t_ms', 'direction', 'characteristic', 'hex'}:
        raise CaptureError('Unexpected frame fields; identifiers are not permitted.')
    t = value['t_ms']
    if type(t) is not int or not previous_ms <= t <= 600000:
        raise CaptureError('Invalid or non-monotonic relative timestamp.')
    pair = (value['direction'], value['characteristic'])
    if pair not in {('rx', 'data'), ('rx', 'confirm'), ('tx', 'write')}:
        raise CaptureError('Unsupported characteristic/direction.')
    data = value['hex']
    if not isinstance(data, str) or not re.fullmatch(r'(?:[0-9a-f]{2}){0,512}', data):
        raise CaptureError('Expected bounded lowercase hex bytes.')
    return t


def load_capture(path):
    # Read at most the bound, even if an input file changes after stat().
    with Path(path).open('rb') as stream:
        raw = stream.read(MAX_BYTES + 1)
    if len(raw) > MAX_BYTES:
        raise CaptureError('Capture is too large.')
    lines = raw.decode('utf-8').splitlines()
    if not lines or len(lines) > MAX_FRAMES + 1:
        raise CaptureError('Invalid capture record count.')
    values = [json.loads(line) for line in lines]
    validate_header(values[0])
    previous = 0
    for frame in values[1:]:
        previous = validate_frame(frame, previous)
    return values


def exclusive_file(path):
    # Never overwrite a previous capture or follow a pre-existing symlink.
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    return os.fdopen(fd, 'w', encoding='utf-8')


class Recorder:
    def __init__(self, stream, metadata, clock=time.monotonic):
        self.stream, self.clock = stream, clock
        self.started = clock()
        self.count = 0
        self.bytes = 0
        self.closed = False
        self._write(metadata)

    def _write(self, record):
        line = json.dumps(record, separators=(',', ':'), sort_keys=True) + '\n'
        size = len(line.encode())
        if self.bytes + size > MAX_BYTES:
            self.closed = True
            return False
        self.stream.write(line)
        self.stream.flush()
        self.bytes += size
        return True

    def frame(self, direction, characteristic, payload):
        if self.closed:
            return False
        elapsed = max(0, int((self.clock() - self.started) * 1000))
        if self.count >= MAX_FRAMES or len(payload) > MAX_FRAME_BYTES or elapsed > 600000:
            self.closed = True
            return False
        record = {'t_ms': elapsed, 'direction': direction,
                  'characteristic': characteristic, 'hex': bytes(payload).hex()}
        validate_frame(record)
        if not self._write(record):
            return False
        self.count += 1
        return True


def candidate(advertisement):
    name = (advertisement.local_name or '').lower()
    return 'chessnut' in name or 'smart chess' in name


async def capture(args):
    # Optional dependency imported only for explicit capture, never for tests/replay.
    from bleak import BleakClient, BleakScanner
    import logging
    logging.disable(logging.CRITICAL)  # Third-party debug logs can contain identities.
    print('Scanning for Chessnut boards. Close other board apps first.')
    devices = await BleakScanner.discover(timeout=4, return_adv=True)
    boards = [d for d, adv in devices.values() if candidate(adv)]
    if not boards:
        raise CaptureError('No candidate Chessnut board found.')
    if args.board_index is None and len(boards) != 1:
        raise CaptureError(f'Found {len(boards)} candidates. Turn off other boards, or select --board-index 1..{len(boards)} on a new scan. Scan order is not persistent.')
    index = 1 if args.board_index is None else args.board_index
    if not 1 <= index <= len(boards):
        raise CaptureError('Selected board index was not found.')
    DEFAULT_DIR.mkdir(parents=True, exist_ok=True, mode=0o700)
    # A random local filename, not a device identifier or absolute path in output.
    import secrets
    path = DEFAULT_DIR / f'capture-{secrets.token_hex(4)}.jsonl'
    disconnected = asyncio.Event()
    async with BleakClient(boards[index - 1], disconnected_callback=lambda _: disconnected.set(), timeout=15) as client:
        chars = {c.uuid.lower(): c for s in client.services for c in s.characteristics}
        if not all(uuid in chars for uuid in UUIDS.values()):
            raise CaptureError('Candidate does not expose the required Chessnut characteristics.')
        with exclusive_file(path) as stream:
            recorder = Recorder(stream, header(args.model, args.firmware))
            def notify(characteristic):
                def receive(_, data):
                    try:
                        accepted = recorder.frame('rx', characteristic, data)
                    except Exception:
                        recorder.closed = True
                        accepted = False
                        print('Capture storage failed; stopped. The partial file may be incomplete.')
                    if not accepted:
                        disconnected.set()
                return receive
            try:
                await asyncio.wait_for(client.start_notify(UUIDS['data'], notify('data')), 10)
                await asyncio.wait_for(client.start_notify(UUIDS['confirm'], notify('confirm')), 10)
                for command in (bytes.fromhex('210100'), bytes.fromhex('290100')):
                    await asyncio.wait_for(client.write_gatt_char(UUIDS['write'], command, response=True), 10)
                    recorder.frame('tx', 'write', command)
                    await asyncio.sleep(.1)
                print('Recording board notifications locally. Ctrl+C stops. No LEDs, sound or motion commands are sent.')
                try:
                    await asyncio.wait_for(disconnected.wait(), args.seconds)
                except asyncio.TimeoutError:
                    pass
            finally:
                recorder.closed = True
                print(f'Stopped. {recorder.count} frames retained in captures/{path.name}. Review before sharing; frames contain board positions.')
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    cap = sub.add_parser('capture')
    cap.add_argument('--seconds', type=int, choices=range(1, 601), default=120, metavar='1..600')
    cap.add_argument('--board-index', type=int)
    cap.add_argument('--model', choices=sorted(MODELS), default='unspecified')
    cap.add_argument('--firmware')
    review = sub.add_parser('review')
    review.add_argument('input', type=Path)
    review.add_argument('--export', type=Path)
    review.add_argument('--reviewed-board-state', action='store_true',
                        help='Confirm all retained board positions/bytes are suitable for sharing.')
    args = parser.parse_args()
    try:
        if args.command == 'capture':
            header(args.model, args.firmware)
            asyncio.run(capture(args))
        else:
            records = load_capture(args.input)
            counts = {key: sum(r['characteristic'] == key for r in records[1:]) for key in UUIDS}
            print(json.dumps({'frames': len(records)-1, 'characteristics': counts}, sort_keys=True))
            if args.export:
                if not args.reviewed_board_state:
                    raise CaptureError('Review the raw bytes/positions locally before exporting; use --reviewed-board-state afterward.')
                with exclusive_file(args.export) as stream:
                    for record in records:
                        stream.write(json.dumps(record, sort_keys=True, separators=(',', ':')) + '\n')
                print('Validated fixture exported. No identifiers or unrecognized metadata fields were accepted.')
    except KeyboardInterrupt:
        print('Capture stopped.')
    except CaptureError as error:
        print(str(error))
        return 1
    except Exception:
        # BLE/library exceptions may include MAC addresses and local paths.
        print('Operation failed. Check permissions, board availability and the documented capture format. No exception details exported.')
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
