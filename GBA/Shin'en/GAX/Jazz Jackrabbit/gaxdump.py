#!/usr/bin/env python3
"""gaxdump.py - list and dump Shin'en GAX (v1.99d-3.x) songs from a GBA ROM.
usage: gaxdump.py ROM                 list songs
       gaxdump.py ROM SONG_INDEX      dump song header, instruments and patterns
"""
import sys, gaxlib, re
FXN = {1:'1',2:'2',3:'3',7:'7',10:'A',11:'B',12:'C',13:'D',14:'E',15:'F'}
def cell(row):
    if row is None: return '... .. ...'
    n = gaxlib.note_name(row['note'])
    i = f"{row['ins']:02X}" if row['ins'] else '..'
    e = f"{FXN.get(row['fx'], '?')}{row['prm']:02X}" if row['fx'] else '...'
    return f"{n} {i} {e}"
def main():
    r = gaxlib.Rom(sys.argv[1])
    print(r.verstr)
    songs = sorted(gaxlib.find_songs(r), key=lambda s: s.get('song_at', s['at']))
    if len(sys.argv) < 3:
        for k, si in enumerate(songs):
            _, me = gaxlib.song_patterns(r, si)
            print(f"{k:3} 0x{si.get('song_at', si['at']):07X} ch={si['nch']:2} rows={si['rows']:3} orders={si['npat']:3} loop={si['loop']:3} {gaxlib.read_title(r, me)[:60]}")
        return
    si = songs[int(sys.argv[2])]
    chans, me = gaxlib.song_patterns(r, si)
    print(gaxlib.read_title(r, me)); print({k: v for k, v in si.items() if k not in ('chans', 'mixer')})
    tab = r.off(si['ins'])
    for i in gaxlib.used_instruments(r, si):
        ins = gaxlib.parse_instrument(r, r.off(r.u32(tab + 4*i)), r.version)
        print(f"\nInstrument {i:02X} @0x{ins['at']:07X} waves={ins['waves']} vib(delay,depth,speed)=({ins['vib_delay']},{ins['vib_depth']},{ins['vib_speed']}) seq_speed={ins['seq_speed']}")
        e = ins['envd']; print(f"  env: sus={e['sustain']} loop={e['loopStart']}-{e['loopEnd']} pts={[(x, v) for x, s, v in e['points']]}")
        for k, st in enumerate(ins['seqlist']):
            fx = ' '.join(f"{t:X}{p:02X}" if t else '...' for t, p in st['fx'])
            print(f"  seq{k:02}: note={st['note']:3} fixed={st['fixed']} wave={st['wave']} {fx}")
        for k, w in enumerate(ins['wp']):
            if any(w[x] for x in ('min', 'max', 'tune', 'start', 'mod')): print(f"  wave{k}: {w}")
    for o in range(si['npat']):
        print(f"\n--- order {o:02X} " + ' '.join(f"[{pa[0]:04X}{pa[1]:+d}]" for _, pats in chans for pa in [pats[o]]))
        for row in range(si['rows']):
            print(f"{row:02X} | " + ' | '.join(cell(pats[o][2][row]) for _, pats in chans))
if __name__ == '__main__': main()
