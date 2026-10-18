"""Shared verification: classify emulated stream reads against a generator model."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode


def find_de_reads(rom, bank, ranges):
    """addresses of `ld a,[de]` instructions within the traced driver code (model items of kind code)."""
    out = []
    for (s, e, items) in ranges:
        for a, (size, kind) in items.items():
            if kind != 'code' or not (s <= a < e):
                continue
            off = a if a < 0x4000 else bank * 0x4000 + a - 0x4000
            if rom[off] == 0x1A:
                out.append(a)
    return sorted(out)


def report(name, reads, model_reads, allowed_ranges, per_job, parsed_kinds=('main', 'env', 'hdr'), extra_ok=()):
    model = {int(k, 16): v for k, v in model_reads.items()}
    outside = {}
    reads = {a: w for a, w in reads.items() if a < 0x8000}
    for a, who in reads.items():
        if a in model:
            continue
        if any(s <= a < e for s, e in allowed_ranges):
            continue
        if a in extra_ok:
            continue
        outside[a] = who
    parsed = [a for a, v in model.items() if v in parsed_kinds]
    unread = sorted(a for a in parsed if a not in reads)
    lines = ['%s: %d distinct addresses read, %d outside the parse' % (name, len(reads), len(outside))]
    for a in sorted(outside)[:40]:
        lines.append('  OUTSIDE %04X by %s' % (a, sorted(map(str, outside[a]))[:4]))
    lines.append('  parsed stream bytes: %d, read: %d, never read: %d' % (len(parsed), len(parsed) - len(unread), len(unread)))
    return '\n'.join(lines), outside, unread
