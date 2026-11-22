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
