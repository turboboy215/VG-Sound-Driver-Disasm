"""Extract Colin McRae Rally's 4-bit PCM samples: pcm/PcmXX.bin (raw, as stored),
wav/PcmXX.wav (8-bit, 8192 Hz) and ColinMcRae_PCM.inc (SECTIONs that INCBIN them).

usage: cmrpcm.py <outdir>"""
import os
import struct
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtparse import Data

out = sys.argv[1]
D = Data('cmr')
D.run()
rom = D.rom
os.makedirs(os.path.join(out, 'pcm'), exist_ok=True)
os.makedirs(os.path.join(out, 'wav'), exist_ok=True)

bybank = {}
for p in D.pcm:
    bybank.setdefault(p['bank'], []).append(p)

L = ['; Colin McRae Rally - PCM samples played by the timer interrupt (see ColinMcRae_Home.asm)',
     '; 4-bit unsigned, two samples per byte (high nibble first), 16-byte blocks,',
     '; 8192 Hz (one 32-sample wave-RAM load per timer interrupt, 256 Hz in double speed).',
     '; Each file holds the bytes from the sample start to the next sample start; the',
     '; table rounds lengths up to whole blocks, so a sample plays into the start of the next.', '']
for bank in sorted(bybank):
    ps = sorted(bybank[bank], key=lambda p: p['addr'])
    L.append('SECTION "CMR PCM bank $%02X", ROMX[$%04X], BANK[$%02X]' % (bank, ps[0]['addr'], bank))
    for i, p in enumerate(ps):
        start = p['addr']
        end = ps[i + 1]['addr'] if i + 1 < len(ps) else start + 16 * p['blocks']
        off = bank * 0x4000 + start - 0x4000
        data = rom[off:off + (end - start)]
        fn = 'Pcm%02X.bin' % p['n']
        open(os.path.join(out, 'pcm', fn), 'wb').write(data)
        # wav of what the driver actually plays (whole blocks)
        play = rom[off:off + 16 * p['blocks']]
        smp = bytearray()
        for b in play:
            smp.append((b >> 4) * 17)
            smp.append((b & 15) * 17)
        hdr = b'RIFF' + struct.pack('<I', 36 + len(smp)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, 1, 8192, 8192, 1, 8) \
            + b'data' + struct.pack('<I', len(smp))
        open(os.path.join(out, 'wav', 'Pcm%02X.wav' % p['n']), 'wb').write(hdr + bytes(smp))
        over = 16 * p['blocks'] - (end - start)
        L.append('Pcm%02X:: INCBIN "pcm/%s" ; %d bytes, %d blocks%s' % (
            p['n'], fn, end - start, p['blocks'],
            ('' if over <= 0 else ' (plays %d bytes into the next sample)' % over) if i + 1 < len(ps) else ''))
    L.append('')
open(os.path.join(out, 'ColinMcRae_PCM.inc'), 'w').write('\n'.join(L))
