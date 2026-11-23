"""Bounded Android UI reads for operator smoke tests; no application hooks.

Compile hardening/android_release/FastDump.java once into task scratch and use
its XML output here. Keep adb/device ownership checks in release_test_preflight.
"""
import re
import time
import xml.etree.ElementTree as ET


def wait_snapshot(read, predicate, *, timeout=30, interval=1, invalid_limit=3,
                  clock=time.monotonic, sleep=time.sleep, diagnostic=None):
    if timeout <= 0 or interval <= 0 or invalid_limit < 1:
        raise ValueError('Use positive, bounded snapshot limits.')
    deadline = clock() + timeout
    invalid = 0
    while clock() < deadline:
        raw = read()  # Transport/process errors propagate; do not disguise them as UI timing.
        try:
            root = ET.fromstring(raw)
            if root.tag != 'hierarchy':
                raise ET.ParseError('Expected Android hierarchy root')
        except ET.ParseError:
            invalid += 1
            if diagnostic:
                diagnostic(raw)
            if invalid >= invalid_limit:
                raise ValueError('Repeated invalid Android UI snapshots; inspect retained diagnostics.')
        else:
            invalid = 0
            if predicate(root):
                return root
        sleep(min(interval, max(0, deadline - clock())))
    raise TimeoutError('Expected Android UI did not appear; inspect focus and screenshot. '
                       'Do not relax app-test timeouts or accept missing evidence.')


def text_field(root):
    fields = []
    for node in root.iter('node'):
        if node.get('editable') != 'true' and node.get('class') != 'android.widget.EditText':
            continue
        bounds = list(map(int, re.findall(r'-?\d+', node.get('bounds', ''))))
        if len(bounds) == 4 and bounds[2] > bounds[0] and bounds[3] > bounds[1]:
            fields.append(node)
    focused = [node for node in fields if node.get('focused') == 'true']
    candidates = focused or fields
    if len(candidates) != 1:
        raise ValueError('No unambiguous editable field. Inspect the current screenshot; '
                         'never assume a fixed screen coordinate or hide a failed assertion.')
    return candidates[0]


def visible_label(root, label, *, fold_case=False):
    """Select an observed, enabled label inside the actual window bounds."""
    def box(node):
        values = list(map(int, re.findall(r'-?\d+', node.get('bounds', ''))))
        return values if len(values) == 4 else None
    window = next((box(n) for n in root.iter('node') if box(n)), None)
    if window is None:
        raise ValueError('Snapshot has no window bounds.')
    wanted = label.casefold() if fold_case else label
    hits = []
    for n in root.iter('node'):
        text = n.get('text') or n.get('content-desc') or ''
        if (text.casefold() if fold_case else text) != wanted:
            continue
        b = box(n)
        if (b and window[0] <= b[0] < b[2] <= window[2]
                and window[1] <= b[1] < b[3] <= window[3]
                and n.get('visible-to-user') != 'false'
                and n.get('enabled') != 'false'):
            hits.append(n)
    if not hits:
        raise ValueError('Label is absent or outside the visible window: ' + label)
    return min(hits, key=lambda n: (box(n)[2] - box(n)[0]) * (box(n)[3] - box(n)[1]))


def checkbox_state(root, label):
    node = visible_label(root, label)
    if node.get('checkable') != 'true' or node.get('checked') not in ('true', 'false'):
        raise ValueError('Checkbox state is unavailable; do not infer it from text.')
    return node, node.get('checked') == 'true'


def receive_share(read, select, *, package, label, receipt, timeout=30, **wait_args):
    """Handle an actual chooser or an already-open sole receiver, without guessing."""
    def received(root):
        return any(n.get('package') == package
                   and (n.get('text') or n.get('content-desc')) == receipt
                   for n in root.iter('node'))
    def chooser(root):
        if any(n.get('package') == package for n in root.iter('node')):
            return False  # A receiver title is not a chooser destination.
        try:
            visible_label(root, label)
            return True
        except ValueError:
            return False
    root = wait_snapshot(read, lambda r: received(r) or chooser(r),
                         timeout=timeout, **wait_args)
    if received(root):
        return root
    select(visible_label(root, label))
    return wait_snapshot(read, received, timeout=timeout, **wait_args)


def normal_background_stop(read_preferences, has_checkpoint, is_running,
                           background, stop, *, timeout=60,
                           clock=time.monotonic, sleep=time.sleep):
    """Wait for normal lifecycle completion; never write/clear recovery preferences.

    The adapter returns None only after an explicit missing-file check. A fresh
    unlaunched installation is accepted only with no checkpoint and no app PID.
    Malformed XML, missing prefs for an existing session, blocked restoration
    and a timeout remain failures, and must never cause a forced stop.
    """
    if timeout <= 0:
        raise ValueError('Use a positive lifecycle deadline.')
    background()
    deadline = clock() + timeout
    while clock() < deadline:
        raw = read_preferences()
        if raw is None:
            if has_checkpoint() or is_running():
                raise ValueError('Missing preferences on an existing/running session.')
            stop()
            return 'fresh-unlaunched'
        try:
            root = ET.fromstring(raw)
        except ET.ParseError as error:
            raise ValueError('Unreadable preferences; retain diagnostics.') from error
        if root.tag != 'map':
            raise ValueError('Unexpected preferences document.')
        prefs = {n.get('name'): n.get('value', n.text) for n in root}
        if prefs.get('flutter.sessionRestoreBlockedV1') == 'true':
            raise ValueError('Restoration is blocked; do not disable the guard.')
        if 'flutter.sessionRestorePendingV1' not in prefs:
            stop()
            return 'normal-background'
        sleep(min(.25, max(0, deadline - clock())))
    raise TimeoutError('Normal background did not finish restoration; retain diagnostics.')


def persisted_snapshot(active, archives, identity, *, phase):
    """Read the requested persistence phase, rather than mistaking an archive for live state."""
    if phase not in ('current', 'archive'):
        raise ValueError('Choose current or archive explicitly.')
    if (phase == 'current' and active and active.get('id') == identity
            and isinstance(active.get('data'), dict)):
        return active
    for record in archives:
        if record.get('id') == identity and isinstance(record.get('data'), dict):
            return record
    raise ValueError('No persisted snapshot for requested identity/phase.')


def fresh_document_name(stem, exists, *, token=None):
    """Give a provider test a unique target and reject any existing output before Save."""
    import uuid
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,80}', stem):
        raise ValueError('Use a simple task-owned document stem.')
    token = uuid.uuid4().hex if token is None else token
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,64}', token):
        raise ValueError('Invalid document token.')
    name = f'{stem}-{token}.pgn'
    if exists(name):
        raise ValueError('Document already exists; never validate stale output.')
    return name
