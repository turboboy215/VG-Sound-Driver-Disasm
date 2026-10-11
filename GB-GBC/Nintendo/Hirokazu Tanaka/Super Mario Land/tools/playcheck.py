"""Play every song and effect of a rebuilt Tanaka-family driver in a test ROM (PyBoy) and check
that every data read the driver makes falls inside the structures the generator parsed.

cfg keys:
  rom, bank, model (json from the generator)
  pat_pc     : PC of the pattern-byte read (ld a,[bc] in ReadPtrByte)        -> address in BC
  list_pc    : PC of the list read (ld a,[bc] in CopyWordIndirect)           -> address in BC
  hl_pcs     : PCs where hl points at SFX/wave/table data being read
  song_req, song_play, stop_value, songs (count), warmup
  sfx        : [(name, request address, count)]
  allow_list_in_pat : pattern reads that land on list words are list loop targets (same routine)
"""
import json
from pyboy import PyBoy

def run_check(cfg, frames_song=3600, frames_sfx=600, coverage_frames=0):
    model = json.load(open(cfg['model']))
    pat = [tuple(v) for v in model['patterns'].values()]
    listw = set(model['list_words'])
    data = [(a, b) for a, b, *_ in model['sfxdata']] + [tuple(x) for x in model.get('extra_data', [])]
    def in_pat(x): return any(a <= x < b for a, b in pat)
    def in_data(x): return any(a <= x < b for a, b in data)
    pb = PyBoy(cfg['rom'], window='null', sound_emulated=False)
    rf = pb.register_file
    reads = {'pat': [], 'list': [], 'data': []}
    bank = cfg['bank']
    if cfg.get('pat_pc'): pb.hook_register(bank, cfg['pat_pc'], lambda _: reads['pat'].append(rf.B << 8 | rf.C), None)
    if cfg.get('list_pc'): pb.hook_register(bank, cfg['list_pc'], lambda _: reads['list'].append(rf.B << 8 | rf.C), None)
    for pc in cfg['hl_pcs']:
        pb.hook_register(bank, pc, lambda _: reads['data'].append(rf.HL), None)
    for a, v in cfg.get('init_writes', {}).items(): pb.memory[a] = v
    for _ in range(cfg.get('warmup', 600)): pb.tick()
    def run(addr, val, frames):
        for k in reads: reads[k].clear()
        pb.memory[addr] = val
        for _ in range(frames): pb.tick()
        pb.memory[cfg['song_req']] = cfg['stop_value']
        for _ in range(3): pb.tick()
        return {k: list(v) for k, v in reads.items()}
    out = []; bad = 0; seen = set()
    tot = {'pat': 0, 'list': 0}
    out.append('song  pattern-reads  outside  list-reads  outside')
    song_ids = cfg.get('song_ids') or list(range(1, cfg['songs']+1))
    for s in song_ids:
        r = run(cfg['song_req'], s, frames_song)
        op = [x for x in r['pat'] if not in_pat(x) and x not in listw]
        ol = [x for x in r['list'] if x not in listw and x >= 2]      # $0000/$0001: unused channel
        bad += len(op) + len(ol); seen |= set(r['pat'])
        tot['pat'] += len(r['pat']); tot['list'] += len(r['list'])
        out.append(f'{s:4x}  {len(r["pat"]):13d}  {len(op):7d}  {len(r["list"]):10d}  {len(ol):7d}  ' + ' '.join(hex(x) for x in (op+ol)[:6]))
    out.append(f'total pattern reads {tot["pat"]}, list reads {tot["list"]}')
    for name, req, n in cfg['sfx']:
        sub = 0; subbad = 0
        for i in (range(1, n+1) if isinstance(n, int) else n):
            r = run(req, i, frames_sfx)
            od = [x for x in r['data'] if not in_data(x) and not (cfg.get('rom_only') and x >= 0x8000)]
            sub += len(r['data']); subbad += len(od); bad += len(od)
            if od: out.append(f'  {name} {i}: {len(od)} reads outside: ' + ' '.join(hex(x) for x in od[:6]))
        out.append(f'{name} 1-{n}: {sub} data reads, {subbad} outside')
    if coverage_frames:
        for s in song_ids:
            reads['pat'].clear()
            pb.memory[cfg['song_req']] = s
            for _ in range(coverage_frames): pb.tick()
            seen |= set(reads['pat'])
        unread = sorted(set(x for a, b in pat for x in range(a, b) if x not in seen))
        spans = []
        for x in unread:
            if spans and x == spans[-1][1]: spans[-1][1] = x+1
            else: spans.append([x, x+1])
        out.append(f'unread pattern bytes after {coverage_frames} frames/song: {len(unread)} ' + str([(hex(a), b-a) for a, b in spans][:80]))
    out.append(f'TOTAL problems: {bad}')
    pb.stop()
    return '\n'.join(out), bad
