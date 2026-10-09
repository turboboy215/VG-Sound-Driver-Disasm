"""Per-game configuration for gen_disasm.py (Rare NES sound engine)."""
from rareparse import BT_CMDS, DD_CMDS, TrackParser, SfxParser, NOTE_NAMES

CH = ['Sq1', 'Sq2', 'Tri', 'Noise']
NOTE_PERIOD_NAMES = ['REST'] + ['%s%d' % (NOTE_NAMES[i % 12], 2 + i // 12) for i in range(60)]

# ============================================================================
# shared data builders
# ============================================================================

def cmd_text(cfg, op):
    nm = cfg['cmds'][op][0]
    if cfg.get('cmd_text'): return cfg['cmd_text'](op, nm)
    return 'CMD_' + nm

def note_text(b, noise):
    if b == 0x80: return 'REST'
    if noise and 0xC0 <= b <= 0xD0:
        k = b - 0xC1
        return 'NZ+%d' % k if k >= 0 else 'NZ-%d' % -k
    n = b - 0x81
    if 0 <= n < 60:
        return 'N_%s%d' % (NOTE_NAMES[n % 12], 2 + n // 12)
    return '$%02X' % b

def build_song_tables(s):
    cfg = s.cfg
    ns = cfg['nsongs']
    ta, tt = cfg['tempo_table'], cfg['track_table']
    s.labels[ta] = 'SongTempoTbl'
    s.labels[tt] = 'SongTrackTbl'
    s.labels[tt + 1] = 'SongTrackTbl_Hi'
    tp = TrackParser(s.mem, 0x8000, cfg['cmds'], cfg['name'])
    names = {}
    for song in range(ns):
        for c in range(4):
            p = s.w(tt + song * 8 + c * 2)
            nm = 'Song%02X_%s' % (song, CH[c])
            if p in names:
                s.equates.append((nm, names[p]))
            else:
                names[p] = nm
                s.labels[p] = nm
            tp.walk(p, nm, chan=c)
    assert not tp.errors and not tp.conflicts, (tp.errors, tp.conflicts[:4])
    s.trackparser = tp
    # tempo table
    for song in range(ns):
        t = s.b(ta + song)
        cm = 'song $%02X: %d/256 ticks per frame' % (song, t & cfg.get('tempo_mask', 0xFF))
        if cfg.get('tempo_mask', 0xFF) != 0xFF and t & 1: cm += ', odd channels lag 1 frame'
        s.add_item(ta + song, 1, ['.byte $%02X' % t], 'data')
        s.comments[ta + song] = cm
    s.blocks[ta] = cfg['tempo_doc']
    # track pointer table
    for song in range(ns):
        a = tt + song * 8
        nms = []
        for c in range(4):
            p = s.w(a + c * 2)
            nms.append(names[p])
        s.add_item(a, 8, ['.word %s' % ', '.join(nms)], 'data')
        s.comments[a] = 'song $%02X' % song
    s.blocks[tt] = 'Track pointers: Square 1, Square 2, Triangle, Noise (8 bytes per song)'

    # ---- tracks
    ev = tp.ev
    jt = {a for a, k in tp.targets.items() if a not in names}
    for a in sorted(jt):
        kinds = tp.targets[a]
        if 'call' in kinds or 'rcall' in kinds:
            s.labels.setdefault(a, 'Pat_%04X' % a)
            s.blocks.setdefault(a, '')
        else: s.labels.setdefault(a, 'Lp_%04X' % a)
    items = sorted(ev)
    # merge runs of 1-byte notes for compactness
    i = 0
    while i < len(items):
        a = items[i]
        kind, n, info = ev[a]
        noise = tp.chan.get(a) == {3}
        if kind == 'note':
            if n == 1:
                run = [a]
                j = i + 1
                while j < len(items) and len(run) < 8:
                    b = items[j]
                    if b != run[-1] + 1 or ev[b][0] != 'note' or ev[b][1] != 1 or b in s.labels \
                       or (tp.chan.get(b) == {3}) != noise:
                        break
                    run.append(b); j += 1
                s.add_item(a, len(run), ['.byte ' + ', '.join(note_text(s.b(x), noise) for x in run)], 'track')
                i = j
                continue
            parts = [note_text(s.b(a), noise)] + ['$%02X' % s.b(a + k) for k in range(1, n)]
            s.add_item(a, n, ['.byte ' + ', '.join(parts)], 'track')
        else:
            op = s.b(a)
            nm, np, k2 = cfg['cmds'][op]
            ct = cmd_text(cfg, op)
            if k2 in ('jump', 'call'):
                t = s.w(a + 1)
                s.add_item(a, n, ['.byte ' + ct, '.word ' + s.labels[t]], 'track')
            elif k2 == 'rcall':
                t = s.w(a + 2)
                s.add_item(a, n, ['.byte %s, $%02X' % (ct, s.b(a + 1)), '.word ' + s.labels[t]], 'track')
            else:
                parts = [ct] + ['$%02X' % s.b(a + k) for k in range(1, n)]
                s.add_item(a, n, ['.byte ' + ', '.join(parts)], 'track')
        i += 1
    for p, nm in names.items():
        s.blocks.setdefault(p, '')

def build_sfx(s):
    cfg = s.cfg
    st, nsfx = cfg['sfx_table'], cfg['nsfx']
    s.labels[st] = 'SfxTbl'
    s.labels[st + 1] = 'SfxTbl_Hi'
    sp = SfxParser(s.mem, 0x8000, cfg['cmds'])
    names = {}
    ptrs = []
    for i in range(nsfx):
        p = s.w(st + i * 2)
        ptrs.append(p)
        if p not in names:
            names[p] = 'Sfx_%02X' % (i * 2)
            s.labels[p] = names[p]
        sp.walk(p)
    assert not sp.errors, sp.errors
    for i in range(0, nsfx, 4):
        k = min(4, nsfx - i)
        s.add_item(st + i * 2, k * 2, ['.word ' + ', '.join(names[ptrs[i + j]] for j in range(k))], 'data')
        s.comments[st + i * 2] = 'id $%02X-$%02X' % (i * 2, (i + k - 1) * 2)
    s.blocks[st] = cfg['sfx_doc']
    evs = sorted(sp.ev)
    i = 0
    while i < len(evs):
        a = evs[i]
        kind, n, info = sp.ev[a]
        if kind == 'sfxhdr':
            h0, h1, h2 = s.b(a), s.b(a + 1), s.b(a + 2)
            s.add_item(a, 3, ['.byte $%02X, $%02X, $%02X' % (h0, h1, h2)], 'sfx')
            s.comments[a] = 'reg0 $%X0, %d frame(s)/step, sweep $%02X, reg3 $%02X' % (h0 >> 4, (h0 & 15) + 1, h1, h2)
            s.blocks.setdefault(a, '')
        elif kind == 'sfxstep':
            run = [a]
            j = i + 1
            while j < len(evs) and len(run) < 6 and sp.ev[evs[j]][0] == 'sfxstep' and evs[j] == run[-1] + 2 \
                  and evs[j] not in s.labels:
                run.append(evs[j]); j += 1
            s.add_item(a, 2 * len(run), ['.byte ' + ',  '.join('$%02X,$%02X' % (s.b(x), s.b(x + 1)) for x in run)], 'sfx')
            i = j
            continue
        elif kind == 'sfxend':
            s.add_item(a, 1, ['.byte CMD_END'], 'sfx')
        else:
            s.add_item(a, n, ['.byte ' + cmd_text(cfg, s.b(a))], 'sfx')
        i += 1

def build_period(s):
    cfg = s.cfg
    a = cfg['period_table']
    s.labels[a] = 'PeriodTbl'
    s.labels[a + 1] = 'PeriodTbl_Hi'
    for i in range(61):
        x = a + i * 2
        s.add_item(x, 2, ['.word $%04X' % s.w(x)], 'data')
        if i == 0:
            s.comments[x] = 'REST (index 0)'
        else:
            per = s.w(x)
            s.comments[x] = '%-4s %7.2f Hz' % (NOTE_PERIOD_NAMES[i], 1789773.0 / (16 * (per + 1)))
    s.blocks[a] = ('Pulse/triangle period table (NTSC Hz shown for pulse channels; triangle sounds\n'
                   'one octave lower). Note byte $81 = C2 ... $BC = B6, $80 = rest.\n'
                   'The noise channel does not use this table: its period index is (note - $C1).')

def build_cmdtable(s):
    cfg = s.cfg
    a, n = cfg['cmd_table'], cfg['ncmd']
    s.labels[a] = 'CmdTbl'
    s.labels[a + 1] = 'CmdTbl_Hi'
    for i in range(n):
        x = a + i * 2
        t = s.w(x)
        s.add_item(x, 2, ['.word ' + s.label_for(t)], 'data')
        s.comments[x] = '$%02X %s' % (i, cfg['cmds'][i][0])

def build_pcm_tables(s):
    cfg = s.cfg
    # --- start index table (overlapping code)
    # --- wave (ramp-segment) table
    wa, wend = cfg['pcm_wave']
    s.labels[wa] = 'PcmWaveTbl'
    s.labels[wa + 1] = 'PcmWaveTbl_1'
    x = wa
    starts = {0: 'PCM_WAVE_A (id 3) starts here; 5-bit length, 3-bit slope',
              0x18: 'PCM_WAVE_C (id 5) starts here; 4-bit length, 4-bit slope',
              0x44: 'PCM_WAVE_B (id 4) starts here; 4-bit length, 4-bit slope'}
    s.blocks[wa] = ('PCM "wave" generator data (ids 3, 4, 5). Each byte is one ramp segment:\n'
                    '  len = byte AND mask (mask $1F for id 3, $0F otherwise), slope = byte >> 5 (id 3)\n'
                    '  or byte >> 4; successive segments alternate direction (up, down, up, ...).\n'
                    '  $00,m  sets the noise mask (random AND m is XORed into every sample);\n'
                    '  $00,$00 ends the sound.')
    while x < wend:
        off = x - wa
        if off in starts and off:
            s.blocks[x] = starts[off]
        elif off == 0:
            s.blocks[x] = s.blocks[x] + '\n' + starts[0]
        if s.b(x) == 0:
            m = s.b(x + 1)
            s.add_item(x, 2, ['.byte $00, $%02X' % m], 'data')
            s.comments[x] = 'end of sound' if m == 0 else 'noise mask $%02X' % m
            x += 2
            continue
        y = x
        while y < wend and s.b(y) != 0 and y - x < 8 and (y == x or (y - wa) not in starts):
            y += 1
        s.add_item(x, y - x, ['.byte ' + s.hexb(x, y - x)], 'data')
        x = y
    # --- noise table: (amplitude, decay, length) triples
    na = cfg['pcm_noise']
    s.labels[na] = 'PcmNoiseTbl'
    s.labels[na + 1] = 'PcmNoiseTbl_1'
    s.labels[na + 2] = 'PcmNoiseTbl_2'
    s.blocks[na] = ('PCM "noise" generator data (id 2): amplitude, decay/sample (subtracted from a\n'
                    '16-bit amplitude accumulator, 8.8), length in samples (0 = 256). $00 = end.')
    x = na
    while s.b(x):
        s.add_item(x, 3, ['.byte $%02X, $%02X, $%02X' % (s.b(x), s.b(x + 1), s.b(x + 2))], 'data')
        s.comments[x] = 'amp $%02X, decay $%02X, %d samples' % (s.b(x), s.b(x + 1), s.b(x + 2) or 256)
        x += 3
    s.add_item(x, 1, ['.byte $00'], 'data'); s.comments[x] = 'end'
    # --- tone table: (len | accel bit 0, accel) pairs
    sa = cfg['pcm_tone']
    s.labels[sa] = 'PcmToneTbl'
    s.blocks[sa] = ('PCM "tone" generator data (id 1), one entry per parabolic segment.\n'
                    'byte 0: bit 7 = acceleration bit 0, bits 0-6 = samples the acceleration lasts;\n'
                    'byte 1: acceleration bits 1-7, sign-magnitude ($80+n = negative). The value\n'
                    'added to the 16-bit velocity is (+/-)((b1 & $7F) * 2 + b0.7) * 4.\n'
                    'A new entry is read every time the level crosses a multiple of 64.')
    x = sa
    while s.b(x) & 0x7F:
        b0, b1 = s.b(x), s.b(x + 1)
        mag = ((b1 & 0x7F) * 2 + (b0 >> 7)) * 4
        sl = -mag if b1 & 0x80 else mag
        s.add_item(x, 2, ['.byte $%02X, $%02X' % (b0, b1)], 'data')
        s.comments[x] = 'len %3d, accel %+d' % (b0 & 0x7F, sl)
        x += 2
    s.add_item(x, 1, ['.byte $00'], 'data'); s.comments[x] = 'end'
    # --- start index table bytes (after the overlapping jmp operand)
    ia = cfg['pcm_startidx']
    s.add_item(ia + 1, 4, ['.byte $00, $00, $00, $44'], 'data')
    s.comments[ia + 1] = 'ids 1-4 (id 0 = jmp operand above, id 5 = the CLC below = $18)'

def build_misc(s):
    for fn in s.cfg.get('misc_builders', ()):
        fn(s)

COMMON_BUILDERS = [build_cmdtable, build_period, build_sfx, build_song_tables, build_pcm_tables, build_misc]

APU = {0x4000: 'SQ1_VOL', 0x4001: 'SQ1_SWEEP', 0x4002: 'SQ1_LO', 0x4003: 'SQ1_HI',
       0x4011: 'DMC_RAW', 0x2000: 'PPU_CTRL', 0x2002: 'PPU_STATUS'}

def note_constants():
    out = ['; Note bytes ($80-$FF). Pulse/triangle: $81 = C2. Noise: NZ+n = period index n.',
           'REST = $80']
    for i in range(60):
        out.append('N_%-4s = $%02X' % ('%s%d' % (NOTE_NAMES[i % 12], 2 + i // 12), 0x81 + i))
    out.append('NZ     = $C1')
    return '\n'.join(out)

def cmd_constants(cmds, extra=''):
    out = ['; Track commands ($00-$7F)']
    seen = set()
    for op in sorted(cmds):
        nm = cmds[op][0]
        if nm in seen: continue
        seen.add(nm)
        out.append('CMD_%-16s = $%02X   ; %d parameter byte(s)' % (nm, op, cmds[op][1]))
    return '\n'.join(out) + extra

# ============================================================================
# Battletoads (E)
# ============================================================================

BT_RAM = {
    0x13: ('FarCallLo', 'bank-call vector (game)'),
    0x25: ('Rng0', 'random generator state'), 0x26: ('Rng1', ''), 0x27: ('Rng2', ''),
    0x28: ('Rng3', 'incremented after every PCM sample'),
    0x32: ('TempoAcc', 'tempo accumulator (also: song number passed to Music_Init)'),
    0x33: ('Tempo', 'added to TempoAcc every frame; carry = tick'),
    0x34: ('TickFlag', 'bit 7 set on tick frames'),
    0x37: ('DataPtr', 'track/SFX data pointer (2 bytes)'), 0x38: ('DataPtrHi', ''),
    0x39: ('Temp', 'scratch; SFX number passed to Sfx_Play*'),
    0x3A: ('Temp2', 'scratch / last written reg3 (skip $4003 write if unchanged)'),
    0x3B: ('Temp3', ''),
    0x3F: ('PcmDelay', 'PCM sample delay (rate): parameter of the PCM_* commands'),
    0x40: ('PcmRequest', 'bit 7 = PCM sound pending, bits 0-6 = generator id 1-5'),
    0x41: ('PcmIndex', 'offset into the generator table'),
    0x42: ('PcmFlipRate', 'tone: added to PcmFlipAcc per segment; carry bumps PcmMask'),
    0x43: ('PcmMask', 'tone: XOR mask on output; wave: length mask $1F/$0F'),
    0x44: ('PcmFlipAcc', 'tone: accumulator; wave: direction ($00/$FF)'),
    0x45: ('PcmOutVec', 'jmp vector into PcmOut_Vol0-3 (2 bytes)'), 0x46: ('PcmOutVecHi', ''),
    0x47: ('PcmTmp', ''),
    0x48: ('PcmCount', 'samples left in the current segment'),
    0x49: ('PcmAccelLo', 'tone: 16-bit acceleration / noise: decay'),
    0x4A: ('PcmAccelHi', 'tone: acceleration high / wave: noise mask'),
    0x4B: ('PcmVelLo', 'tone: 16-bit velocity / noise: 8.8 amplitude'),
    0x4C: ('PcmVel', 'tone: velocity high / noise: amplitude / wave: slope'),
    0x4D: ('PcmLevelLo', ''), 0x4E: ('PcmLevel', 'tone/wave: current output level'),
    0x4F: ('PcmSegLimit', 'max number of segments to play (+1)'),
    0x50: ('PcmSegCount', ''),
    0x0301: ('ChActive', 'per channel, stride 4 (x = 0 Sq1, 4 Sq2, 8 Tri, 12 Noise); 0 = off'),
    0x0302: ('ChDurCnt', 'ticks until next event'),
    0x0303: ('ChPtrLo', 'track pointer'), 0x0304: ('ChPtrHi', ''),
    0x0311: ('SfxId', 'SFX playing on this channel (even id; bit 0 = flag cleared by $02)'),
    0x0312: ('SfxTimer', 'high nibble = frames left, low nibble = reload'),
    0x0313: ('SfxPtrLo', ''), 0x0314: ('SfxPtrHi', ''),
    0x0321: ('ChReg0', 'duty / flags (bits 5-7 used)'),
    0x0322: ('ChReg1', 'sweep'),
    0x0323: ('ChPerLo', 'period low'), 0x0324: ('ChPerHi', 'period high + length counter'),
    0x0331: ('SfxReg0', ''), 0x0332: ('SfxReg1', '$55 = SFX requested, not initialised yet'),
    0x0333: ('SfxReg2', ''), 0x0334: ('SfxReg3', ''),
    0x0341: ('ChRepPtrLo', 'REPEAT_CALL: pointer to the call operand'), 0x0342: ('ChRepPtrHi', ''),
    0x0343: ('ChRepCount', ''),
    0x0344: ('ChVibDelta', 'vibrato: current period delta'),
    0x0351: ('ChFixDur', 'nonzero = all notes use this duration (no duration byte)'),
    0x0352: ('ChVolume', 'current volume ($10 = constant-volume flag + 0-15)'),
    0x0353: ('ChEnvDelay', 'envelope: delay before ramp / tremolo half-period'),
    0x0354: ('ChTranspose', 'added to every note'),
    0x0361: ('ChVibWidth', 'vibrato: steps per half cycle (0 = off)'),
    0x0362: ('ChVibCount', ''), 0x0363: ('ChVibSpeed', 'frames per step (+1)'),
    0x0364: ('ChVibTimer', ''),
    0x0371: ('ChAttack', 'bit 7 set = restart volume envelope at each note from this volume'),
    0x0373: ('ChEnvTimer', ''),
    0x0374: ('ChSlideTimer', ''),
    0x0381: ('ChSlideCount', 'pitch slide: steps left'),
    0x0382: ('ChSlideDelay', 'pitch slide: frames before it starts'),
    0x0383: ('ChSlideStep', 'pitch slide: signed period delta per step'),
    0x0384: ('ChSlideRev', 'pitch slide: initial steps taken in the opposite direction'),
    0x0391: ('ChEnvTarget', 'envelope: target volume (mode 1) / delta (mode 2)'),
    0x0392: ('ChEnvCount', ''),
    0x0393: ('ChEnvMode', '0 = off, 1 = ramp to target, 2 = tremolo'),
    0x0394: ('ChEnvSpeed', 'frames per step (+1)'),
    0x03A1: ('ChSlideSpeed', 'frames per slide step (+1); 0 = slide off'),
    0x03A2: ('ChVolMode', '0 = off, $01-$7F = echo XOR, $80+ = note carries a volume byte'),
    0x03A3: ('ChEchoVol', 'echo: volume of the next note'),
    0x03A4: ('ChRetSlot', 'cleared per channel at song start; also CALL_A/CALL_B slots'),
    0x03A8: ('RetA_Hi', 'CALL_A return address (shared by all channels!)'),
    0x03AC: ('RetB_Lo', 'CALL_B return address (shared by all channels!)'),
    0x03B0: ('RetB_Hi', ''),
}

BT_LABELS = {
    0x851F: 'Pcm_PlayFullVol', 0x852B: 'Pcm_Play', 0x8531: 'Pcm_Dispatch',
    0x8541: 'PcmDisp_Wave', 0x8544: 'PcmDisp_Noise', 0x8547: 'PcmDisp_Tone',
    0x8549: 'PcmStartIdx',
    0x854E: 'Pcm_SetVolume', 0x855A: 'Pcm_Output',
    0x855D: 'PcmOut_Vol0', 0x855E: 'PcmOut_Vol1', 0x855F: 'PcmOut_Vol2', 0x8560: 'PcmOut_Vol3',
    0x8565: 'PcmOut_Delay',
    0x868F: 'Pcm_Exit',
    0x8696: 'PcmGen_Tone', 0x8698: 'PcmTone_Click', 0x86BB: 'PcmTone_Sample', 0x86CC: 'PcmTone_Coast',
    0x86E8: 'PcmTone_NextSeg', 0x8727: 'PcmTone_Done',
    0x872A: 'PcmGen_Wave', 0x8736: 'PcmWave_SetMask', 0x873E: 'PcmWave_Sample', 0x8754: 'PcmWave_NextSeg',
    0x876B: 'PcmWave_Segment', 0x8780: 'PcmWave_SetSlope',
    0x878D: 'PcmGen_Noise', 0x8791: 'PcmNoise_Sample', 0x8797: 'PcmNoise_MaskLoop', 0x879E: 'PcmNoise_Rand',
    0x87A3: 'PcmNoise_Mod', 0x87C3: 'PcmNoise_NextSeg', 0x87E1: 'PcmNoise_Done',
    0x87E4: 'Random',
    0x87F8: 'Music_Init', 0x8812: 'MusicInit_ChLoop',
    0x884F: 'Music_Update', 0x885B: 'MusicUpd_ChLoop', 0x8863: 'MusicUpd_Sfx', 0x886B: 'MusicUpd_Next',
    0x8873: 'MusicUpd_Rts',
    0x8874: 'Music_Channel', 0x887B: 'MusCh_Tick', 0x889A: 'MusCh_Attack', 0x88AF: 'MusCh_Read',
    0x88B9: 'ReadEvent_Y0', 0x88BB: 'ReadEvent_Next', 0x88BC: 'ReadEvent',
    0x88C3: 'Ev_Note', 0x88CB: 'Ev_NoteIdx', 0x88E5: 'Ev_SetPerLo', 0x88F4: 'Ev_SetPerHi',
    0x890D: 'Ev_NoteVolDone', 0x8915: 'Ev_Duration', 0x891F: 'Ev_SetDuration',
    0x8932: 'Music_Effects', 0x8946: 'Fx_SlideStep', 0x895B: 'Fx_SlideApply', 0x8970: 'Fx_SlideFwd',
    0x8973: 'Fx_SlideSign', 0x8976: 'Fx_SlideAdd',
    0x8984: 'Fx_Vibrato', 0x89A6: 'Fx_VibAdd', 0x89CA: 'Fx_Envelope', 0x89DF: 'Fx_EnvStep',
    0x8A03: 'Fx_TremoloCount', 0x8A1C: 'Fx_EnvRamp', 0x8A29: 'Fx_EnvDown', 0x8A2C: 'Fx_EnvCheck',
    0x8A39: 'Fx_Done',
    0x8A3F: 'WriteRegsForce', 0x8A49: 'WriteRegs', 0x8A64: 'WriteRegs_Rts',
    0x8A65: 'Sfx_PlaySq1', 0x8A69: 'Sfx_PlaySq2', 0x8A6D: 'Sfx_PlayTri', 0x8A71: 'Sfx_PlayNoise',
    0x8A73: 'Sfx_Play', 0x8A8D: 'Sfx_Play_Rts',
    0x8A8E: 'Sfx_Start', 0x8AC1: 'Sfx_Update', 0x8AD4: 'Sfx_Step', 0x8AEC: 'Sfx_ReadStep',
    0x8AF8: 'SilenceChannel', 0x8AFE: 'Sfx_RestoreMusic', 0x8B01: 'Sfx_Event', 0x8B3A: 'Sfx_SetLo',
    0x8B43: 'Sfx_SavePtr',
    0x8B52: 'ExecCommand',
    0x8BB3: 'Cmd_End', 0x8BBB: 'Cmd_SfxClrFlag', 0x8BC7: 'Cmd_FixDurOff', 0x8BCF: 'Cmd_FixDur',
    0x8BD8: 'Cmd_Instr', 0x8BF2: 'SetVolume', 0x8C02: 'SetVolume_Rts',
    0x8C03: 'Cmd_Jump', 0x8C14: 'Cmd_CallA', 0x8C25: 'Cmd_CallB', 0x8C36: 'Cmd_RetA', 0x8C45: 'Cmd_RetB',
    0x8C54: 'Cmd_RepeatCall', 0x8C69: 'JumpToOperand', 0x8C79: 'Cmd_RepeatEnd', 0x8C8D: 'RepeatEnd_Done',
    0x8C9C: 'Cmd_VibratoDly', 0x8CA8: 'Cmd_Vibrato', 0x8CAE: 'ReadVibrato', 0x8CD0: 'Cmd_VibratoOff',
    0x8CD8: 'Cmd_SlideDown', 0x8CDE: 'Cmd_SlideUp', 0x8CE6: 'StoreSlide', 0x8CF2: 'ReadSlide',
    0x8D0E: 'Cmd_FixDurEchoOff', 0x8D15: 'Cmd_NoteVolOn', 0x8D19: 'Cmd_EchoOff', 0x8D1B: 'SetVolMode',
    0x8D21: 'Cmd_Echo', 0x8D30: 'Cmd_Volume', 0x8D38: 'SetVolumeCmd',
    0x8D40: 'Cmd_AttackOff', 0x8D48: 'Cmd_AttackEnv', 0x8D50: 'Cmd_VolEnv', 0x8D75: 'ApplyVolume',
    0x8D7B: 'Cmd_Tremolo', 0x8D9F: 'Cmd_VolEnvOff',
    0x8DA7: 'Cmd_Tempo', 0x8DA9: 'SetTempo', 0x8DB2: 'Cmd_TempoAdd',
    0x8DB7: 'Cmd_Transpose', 0x8DB9: 'SetTranspose', 0x8DC3: 'Cmd_TransposeAdd', 0x8DC9: 'Cmd_TransposeAll',
    0x8DDB: 'Cmd_PcmTone', 0x8DDD: 'SetPcmRequest', 0x8DE7: 'Cmd_PcmNoise', 0x8DEB: 'Cmd_PcmWaveA',
    0x8DEF: 'Cmd_PcmWaveB', 0x8DF3: 'Cmd_PcmWaveC', 0x8DF7: 'Cmd_PcmSetup',
}

BT_BLOCKS = {
    0x851F: (
        '-' * 76 + '\n'
        'PCM ("digital") sound player.\n'
        'Entered through the bank-3 jump table: X=$09 -> Pcm_PlayFullVol (game sound\n'
        'effects), X=$18/$1B -> Pcm_Play (music drums, volume set by PCM_SETUP).\n'
        'Nothing is read from ROM sample data: each sound is synthesised on the fly by\n'
        'one of three generators and written to $4011 (DMC direct load) in a busy\n'
        'loop. The generators leave through Pcm_Exit, which unwinds the far call.\n'
        '  id 1 = PcmGen_Tone  (pitch-swept sine-like tone after a noise click: kick/tom)\n'
        '  id 2 = PcmGen_Noise (decaying random noise: snare/crash)\n'
        '  id 3-5 = PcmGen_Wave (ramp segments plus masked noise)\n' +
        '-' * 76),
    0x854E: 'A = 0-3: output volume (number of LSRs skipped). Sets PcmOutVec.',
    0x855A: 'Output one sample (A) through the selected volume entry point.',
    0x855D: ('Sample output: 3/2/1/0 right shifts, write $4011, then delay PcmDelay*5\n'
             'cycles. Rng3 is bumped so the random generator keeps changing.'),
    0x856B: None,
    0x868F: 'Common exit: drop the return into the far-call stub and return to bank 0.',
    0x8696: ('-' * 76 + '\nGenerator 1: tone (kick/tom).\n'
             '84 samples of random noise ($3C-$4B) as an attack click, then a second-order\n'
             'oscillator: PcmLevel += PcmVel every sample, and PcmVel += PcmAccel for the\n'
             'first PcmCount samples of each segment. A new segment (with an acceleration\n'
             'of the opposite sign) starts each time the level crosses a multiple of 64, so\n'
             'the output is built from parabolic arcs - a sine-like wave whose period and\n'
             'amplitude follow the table (falling pitch). PcmFlipRate is added to\n'
             'PcmFlipAcc per segment; each carry increments PcmMask, which is XORed into\n'
             'the output (a slightly dirtier tone).\n' + '-' * 76),
    0x872A: ('-' * 76 + '\nGenerator 3/4/5: ramp segments. The level moves up and down in straight\n'
             'lines (slope from the table, direction alternating) with random bits\n'
             '(Random AND noise mask) XORed in.\n' + '-' * 76),
    0x878D: ('-' * 76 + '\nGenerator 2: decaying noise. Each sample is a random value in\n'
             '[0, amplitude) centred around $40; the amplitude falls by the decay rate.\n' + '-' * 76),
    0x87E4: 'Pseudo-random number generator (Rng0-3). Returns A = Rng0.',
    0x87F8: ('=' * 76 + '\nMusic_Init: start song number TempoAcc ($32). Far-call X=$03.\n' + '=' * 76),
    0x884F: ('=' * 76 + '\nMusic_Update: called once per frame (far-call X=$06, or bank-0 $FF84).\n'
             'Tempo is a fractional accumulator: a tick happens when TempoAcc+Tempo\n'
             'carries. On tick frames tracks advance; on other frames effects run.\n' + '=' * 76),
    0x8874: 'Process one music channel (X = 0/4/8/12).',
    0x88B9: 'Read events until a note is found. Commands jump back here.',
    0x88C3: ('Note: $80 = rest (period 0), otherwise note + transpose indexes PeriodTbl.\n'
             'The noise channel uses (index - $82)/2 as its period instead.'),
    0x8932: 'Non-tick frame: pitch slide, vibrato and volume envelope, then write the APU.',
    0x8A3F: 'Write the channel shadow registers to the APU ($4003 only when it changed).',
    0x8A65: ('=' * 76 + '\nSfx_Play*: start sound effect Temp ($39) on one channel.\n'
             'Far-call X=$0C/$0F/$12/$15. Effects $7A/$7B cannot be interrupted.\n' + '=' * 76),
    0x8A8E: 'First frame of a sound effect: read its 3-byte header.',
    0x8AC1: 'Per-frame sound effect update (overrides the music on that channel).',
    0x8B52: ('Dispatch command A (< $80) through CmdTbl. Music handlers continue at\n'
             'ReadEvent; SFX-only handlers ($02, $04) continue in the SFX reader.'),
}

BT_COMMENTS = {
    0x8563: 'delay: 5 cycles per count',
    0x8568: 'keep the random generator moving',
    0x868F: 'discard the return into the far-call stub',
    0x86A5: 'Y = 0: clear the oscillator state',
    0x86BD: 'acceleration only for the first PcmCount samples',
    0x86E4: 'next segment when the level crosses a multiple of 64',
    0x8730: 'id 3 (start index 0) uses 5-bit lengths',
    0x874C: 'leftover: X is not used here',
    0x8780: 'alternate the direction of each segment',
    0x87A3: 'A = random mod amplitude',
    0x87AD: 'centre it: + (127 - amplitude) / 2',
    0x8856: 'carry (TempoAcc wrapped) -> bit 7 = tick',
    0x887E: 'note still sounding (no effects on tick frames)',
    0x8880: 'a new event cancels any pitch slide',
    0x888C: 'echo: alternate the volume on every note',
    0x889F: 'attack: restart the envelope from the attack volume',
    0x88DB: 'noise channel: period = (note*2 - $82) / 2',
    0x88EB: 'keep the length-counter bits',
    0x88F7: 'note-volume mode: a volume byte follows the note',
    0x8912: 'note-on: write all registers ($4003 always)',
    0x8917: 'fixed duration, or read a duration byte',
    0x8A5D: 'skip $4003 if unchanged (avoids a phase reset)',
    0x8A78: 'effects $7A/$7B cannot be interrupted',
    0x8A84: 'SfxReg1 = $55: initialise on the next update',
    0x8ACC: 'count frames in the high nibble',
    0x8AF0: 'effect over: hand the channel back to the music',
    0x8B03: '$01-$0F: command (only $02 and $04 belong here)',
    0x8B29: 'write $4003 only when the period high bits change',
    0x8C79: 'repeat the call, or continue after it',
    0x8DDD: 'request a PCM sound; NMI/main loop plays it',
}

BT_OPERAND = {
    0x854F: '#<PcmOut_Vol0', 0x8553: '#>PcmOut_Vol0',
    0x8C19: 'RetA_Lo', 0x8C36: 'RetA_Lo',
}

def bt_misc(s):
    pass

BT_HEADER = """;=============================================================================
; Battletoads (E) - sound engine, PRG bank 3 ($8000-$FFFF, AxROM 32K bank 3)
; Rare, 1991. Labeled disassembly generated by tool/gen_disasm.py.
;
; Covers $851F-$CCCF: PCM generators, music/SFX driver, period table,
; sound effects and all song data. Assemble with:
;   ca65 bt_sound.asm -o bt_sound.o && ld65 -C bt_sound.cfg bt_sound.o -o bt_sound
; and compare bt_sound.0.bin with ROM file offset $0C52F (bank 3 + $051F).
;
; Far-call interface (bank-0 stub $FFCB: X = jump-table offset, Y = bank 3):
;   X=$03 Music_Init  ($32 = song)      X=$06 Music_Update (every frame)
;   X=$09 Pcm_PlayFullVol               X=$18/$1B Pcm_Play (pending drum)
;   X=$0C/$0F/$12/$15 Sfx_PlaySq1/Sq2/Tri/Noise ($39 = sound effect id)
;=============================================================================
"""

CONFIG_BT = dict(
    name='bt', bank=3,
    regions=[(0x851F, 0xCCD0)], segments=['SOUND'],
    code_entries=[0x851F, 0x852B, 0x87F8, 0x884F, 0x8A65, 0x8A69, 0x8A6D, 0x8A71, 0x855D],
    labels=BT_LABELS, blocks={k: v for k, v in BT_BLOCKS.items() if v},
    comments=BT_COMMENTS,
    ram={a: v[0] for a, v in BT_RAM.items()},
    ram_defs=BT_RAM,
    ram_arrays=[(0x0354, 'ChTranspose', 13, 4)],
    extern={0x4000: 'SQ1_VOL', 0x4001: 'SQ1_SWEEP', 0x4002: 'SQ1_LO', 0x4003: 'SQ1_HI',
            0x4011: 'DMC_RAW', 0xFFE1: 'FarCall_Return'},
    operand=BT_OPERAND,
    cmds=BT_CMDS, cmd_table=0x8B65, ncmd=39,
    period_table=0x8E0A, sfx_table=0x8E84, nsfx=85,
    tempo_table=0x9588, track_table=0x959D, nsongs=21,
    pcm_wave=(0x856B, 0x8627), pcm_noise=0x8627, pcm_tone=0x8649, pcm_startidx=0x8549,
    data_builders=COMMON_BUILDERS,
    unref_notes={0x868E: 'Unreferenced: second terminator byte after PcmToneTbl',
                 0xCB23: 'Unreferenced: never reached (follows a JUMP)',
                 0xCCCF: 'Unreferenced: last byte before game code at $CCD0'},
    tempo_doc='Song tempo: added to TempoAcc each frame, a carry is one tick.',
    sfx_doc=('Sound effect pointers, indexed by id/2 (ids are even; bit 0 is a flag).\n'
             'SFX format: header (reg0 high nibble | frames-per-step - 1, sweep, reg3),\n'
             'then 2-byte steps: (volume << 4 | period bits 8-10), period bits 0-7.\n'
             '$00 ends the effect; $02 clears the id flag bit; $04 holds one step.'),
    header=BT_HEADER,
)

# ============================================================================
# Battletoads & Double Dragon (E)
# ============================================================================

DD_RAM = {
    0x10: ('GameLevel', 'game: current level (selects the raster budget)'),
    0x13: ('FarCallLo', 'bank-call vector (game)'),
    0x1D: ('SfxHdrPtr', 'Sfx_Play: temporary pointer (saved/restored)'), 0x1E: ('SfxHdrPtrHi', ''),
    0x2C: ('Rng0', 'random generator state'), 0x2D: ('Rng1', ''), 0x2E: ('Rng2', ''),
    0x2F: ('Rng3', 'incremented after every PCM sample'),
    0x39: ('TempoAcc', 'tempo accumulator (also: song number passed to Music_Init)'),
    0x3A: ('Tempo', 'song tempo (even); added to TempoAcc every frame'),
    0x3B: ('TickFlag', 'bit 7 set on tick frames'),
    0x3C: ('LagMode', '0 = normal; 1/$81 = Sq2+Noise tick one frame after Sq1+Tri'),
    0x3D: ('DataPtr', 'track/SFX data pointer (2 bytes)'), 0x3E: ('DataPtrHi', ''),
    0x3F: ('Temp', 'scratch; SFX number passed to Sfx_Play*'),
    0x40: ('Temp2', 'scratch / command vector / last reg3'), 0x41: ('Temp3', ''),
    0x44: ('UpdateMode', 'A given to the bank-0 sound call; $10 = in-level raster mode'),
    0x45: ('PcmDelay', 'PCM sample delay (rate)'),
    0x46: ('PcmRequest', 'bit 7 = PCM sound pending, bits 0-6 = generator id 1-5'),
    0x47: ('PcmIndex', ''),
    0x48: ('PcmFlipRate', ''), 0x49: ('PcmMask', ''), 0x4A: ('PcmFlipAcc', ''),
    0x4B: ('PcmOutVec', ''), 0x4C: ('PcmOutVecHi', ''),
    0x4D: ('PcmTmp', ''), 0x4E: ('PcmCount', ''),
    0x4F: ('PcmAccelLo', ''), 0x50: ('PcmAccelHi', ''),
    0x51: ('PcmVelLo', ''), 0x52: ('PcmVel', ''),
    0x53: ('PcmLevelLo', ''), 0x54: ('PcmLevel', ''),
    0x55: ('PcmSegLimit', ''), 0x56: ('PcmSegCount', ''),
    0x57: ('SplitMask', 'game: $2002 bit to wait for (sprite-0 hit) during PCM'),
    0x59: ('SplitWait', 'game: samples before polling; $FF = split done'),
    0x09: ('PpuCtrlCopy', 'game: shadow of PPU_CTRL'),
    0xFA: ('RasterBudget', 'delay units left after the update (raster mode)'),
}
for a, v in BT_RAM.items():
    if a >= 0x300: DD_RAM[a] = v
for a in (0x03A8, 0x03AC, 0x03B0): DD_RAM.pop(a)
DD_RAM.update({
    0x03A2: ('ChLoopDepth', 'REPEAT_CALL nesting: $FD = none, 0, 3, 6 ...'),
    0x03A3: ('ChEchoXor', 'bit 7 set = echo off; CALL stores the return high byte here'),
    0x03A4: ('ChEchoVol', 'echo volume; CALL stores the return low byte here'),
    0x03B1: ('SaveY', ''),
    0x0600: ('LoopStack', 'REPEAT_CALL stack, 15 bytes per channel'),
})
DD_RAM[0x0332] = ('SfxReg1', '')

DD_LABELS = {
    0x8952: 'Pcm_PlayFullVol', 0x895E: 'Pcm_Play', 0x8964: 'Pcm_Dispatch',
    0x8974: 'PcmDisp_Wave', 0x8977: 'PcmDisp_Noise', 0x897A: 'PcmDisp_Tone',
    0x897C: 'PcmStartIdx',
    0x8981: 'Pcm_SetVolume', 0x898D: 'Pcm_Output',
    0x8990: 'PcmOut_Vol0', 0x8991: 'PcmOut_Vol1', 0x8992: 'PcmOut_Vol2', 0x8993: 'PcmOut_Vol3',
    0x8998: 'PcmOut_Delay', 0x899D: 'Pcm_SplitPoll', 0x89B5: 'SplitPoll_Count', 0x89B7: 'SplitPoll_Rts',
    0x8ADC: 'Pcm_Exit', 0x8AE2: 'PcmExit_Delay', 0x8AEB: 'PcmExit_Return',
    0x8AF2: 'PcmGen_Tone', 0x8AF4: 'PcmTone_Click', 0x8B17: 'PcmTone_Sample', 0x8B28: 'PcmTone_Coast',
    0x8B44: 'PcmTone_NextSeg', 0x8B83: 'PcmTone_Done',
    0x8B86: 'PcmGen_Wave', 0x8B92: 'PcmWave_SetMask', 0x8B9A: 'PcmWave_Sample', 0x8BB0: 'PcmWave_NextSeg',
    0x8BC7: 'PcmWave_Segment', 0x8BDC: 'PcmWave_SetSlope',
    0x8BE9: 'PcmGen_Noise', 0x8BED: 'PcmNoise_Sample', 0x8BF3: 'PcmNoise_MaskLoop', 0x8BFA: 'PcmNoise_Rand',
    0x8BFF: 'PcmNoise_Mod', 0x8C1F: 'PcmNoise_NextSeg', 0x8C3D: 'PcmNoise_Done',
    0x8C40: 'Random',
    0x8C54: 'Music_Init', 0x8C77: 'MusicInit_ChLoop',
    0x8CBC: 'RasterBudgetTbl_m2', 0x8CBE: 'RasterBudgetTbl',
    0x8CC6: 'Music_Update', 0x8CD9: 'MusicUpd_Budget', 0x8CF4: 'MusicUpd_Delay', 0x8CF9: 'MusicUpd_Plain',
    0x8CFC: 'MusicUpd_Rts',
    0x8CFD: 'Music_Frame', 0x8D09: 'MusicFrm_ChLoop', 0x8D11: 'MusicFrm_Sfx', 0x8D19: 'MusicFrm_Next',
    0x8D2D: 'MusicFrm_SetLag', 0x8D2F: 'MusicFrm_Rts',
    0x8D30: 'Music_Channel', 0x8D3F: 'MusCh_Effects1', 0x8D42: 'MusCh_LagOdd', 0x8D4A: 'MusCh_Normal',
    0x8D51: 'MusCh_Tick', 0x8D6E: 'MusCh_Attack', 0x8D83: 'MusCh_Read',
    0x8D8D: 'ReadEvent_Y0', 0x8D8F: 'ReadEvent_Next', 0x8D90: 'ReadEvent',
    0x8D97: 'Ev_Note', 0x8D9F: 'Ev_NoteIdx', 0x8DB9: 'Ev_SetPerLo', 0x8DC8: 'Ev_SetPerHi',
    0x8DD3: 'Ev_Duration', 0x8DDD: 'Ev_SetDuration',
    0x8DF0: 'Music_Effects', 0x8E04: 'Fx_SlideStep', 0x8E19: 'Fx_SlideApply', 0x8E2E: 'Fx_SlideFwd',
    0x8E31: 'Fx_SlideSign', 0x8E34: 'Fx_SlideAdd',
    0x8E42: 'Fx_Vibrato', 0x8E64: 'Fx_VibAdd', 0x8E88: 'Fx_Envelope', 0x8E9D: 'Fx_EnvStep',
    0x8EC1: 'Fx_TremoloCount', 0x8EDA: 'Fx_EnvRamp', 0x8EE7: 'Fx_EnvDown', 0x8EEA: 'Fx_EnvCheck',
    0x8EF7: 'Fx_Done',
    0x8EFD: 'WriteRegsForce', 0x8F07: 'WriteRegs', 0x8F22: 'WriteRegs_Rts',
    0x8F23: 'Sfx_PlaySq1', 0x8F27: 'Sfx_PlaySq2', 0x8F2B: 'Sfx_PlayTri', 0x8F2F: 'Sfx_PlayNoise',
    0x8F31: 'Sfx_Play',
    0x8F8A: 'Sfx_Update', 0x8F96: 'Sfx_Step', 0x8FAE: 'Sfx_ReadStep',
    0x8FBA: 'SilenceChannel', 0x8FC0: 'Sfx_RestoreMusic', 0x8FC3: 'Sfx_Event', 0x8FFC: 'Sfx_SetLo',
    0x9005: 'Sfx_SavePtr',
    0x9014: 'ExecCommand',
    0x90D5: 'Cmd_End', 0x90DD: 'Cmd_SfxClrFlag', 0x90E9: 'Cmd_FixDurOff', 0x90F1: 'Cmd_FixDur',
    0x90FA: 'Cmd_Instr', 0x9114: 'Cmd_HwLen', 0x9123: 'SetHwLen', 0x9134: 'Cmd_HwLenInstr',
    0x914A: 'SetVolume', 0x915A: 'SetVolume_Rts', 0x915B: 'HwLenTbl',
    0x916A: 'Cmd_Jump', 0x917B: 'Cmd_RepeatCall', 0x91A0: 'RepCall_Deeper', 0x91BB: 'JumpToOperand',
    0x91CB: 'Cmd_RepeatEnd', 0x91DF: 'RepeatEnd_Done', 0x9208: 'RepeatEnd_Pop',
    0x9212: 'Cmd_Call', 0x9231: 'Cmd_Ret',
    0x9240: 'Cmd_VibratoDly', 0x924C: 'Cmd_Vibrato', 0x9252: 'ReadVibrato', 0x9274: 'Cmd_VibratoOff',
    0x927C: 'Cmd_SlideDown', 0x9282: 'Cmd_SlideUp', 0x928A: 'StoreSlide', 0x9296: 'ReadSlide',
    0x92B2: 'Cmd_EchoToggle', 0x92CD: 'Cmd_FixDurEchoOff', 0x92D2: 'Cmd_EchoOff', 0x92D4: 'SetEchoXor',
    0x92DA: 'Cmd_Echo', 0x92F3: 'Cmd_VolumeN', 0x92FD: 'SetVolumeCmd',
    0x9305: 'Cmd_AttackOff', 0x930D: 'Cmd_AttackPreset', 0x931C: 'Cmd_EnvPreset', 0x931F: 'EnvPreset_Load',
    0x9349: 'ApplyVolume', 0x934F: 'EnvPresetDelay', 0x935F: 'EnvPresetSpeed', 0x936F: 'EnvPresetTarget',
    0x937F: 'Cmd_Tremolo', 0x93A3: 'Cmd_VolEnvOff',
    0x93AB: 'Cmd_Tempo', 0x93AD: 'SetTempo', 0x93B6: 'Cmd_TempoAdd',
    0x93BB: 'Cmd_Transpose', 0x93BD: 'SetTranspose', 0x93C7: 'Cmd_TransposeAdd', 0x93CD: 'Cmd_TransposeAll',
    0x93DF: 'Cmd_PcmTone', 0x93E1: 'SetPcmRequest', 0x93EB: 'Cmd_PcmNoise', 0x93EF: 'Cmd_PcmWaveA',
    0x93F3: 'Cmd_PcmWaveB', 0x93F7: 'Cmd_PcmWaveC', 0x93FB: 'Cmd_PcmSetup',
    0x9DBD: 'LoopStackBase',
}

DD_BLOCKS = {
    0x8952: (
        '-' * 76 + '\n'
        'PCM ("digital") sound player - same generators as Battletoads, but the\n'
        'output routine also performs the game\'s sprite-0 raster split, because a\n'
        'PCM sound now owns the main thread for the rest of the frame.\n'
        '  id 1 = PcmGen_Tone (kick/tom), id 2 = PcmGen_Noise, id 3-5 = PcmGen_Wave\n' +
        '-' * 76),
    0x8981: 'A = 0-3: output volume. Sets PcmOutVec.',
    0x8990: ('Sample output (3/2/1/0 right shifts), delay, then fall into Pcm_SplitPoll.'),
    0x899D: ('Raster split during PCM: after SplitWait samples, wait for the $2002 bit in\n'
             'SplitMask (sprite-0 hit); then set PPU_CTRL = $80 for the lower screen\n'
             'and disarm (SplitMask = 0, SplitWait = $FF).'),
    0x8ADC: ('Common exit: keep polling until the split has happened (SplitWait < 0),\n'
             'then unwind the far call and return to bank 0.'),
    0x8AF2: ('-' * 76 + '\nGenerator 1: tone (kick/tom) - noise click, then parabolic arcs\n'
             '(see the Battletoads disassembly for the full description).\n' + '-' * 76),
    0x8B86: ('-' * 76 + '\nGenerator 3/4/5: ramp segments with masked noise.\n' + '-' * 76),
    0x8BE9: ('-' * 76 + '\nGenerator 2: decaying noise.\n' + '-' * 76),
    0x8C40: 'Pseudo-random number generator (Rng0-3). Returns A = Rng0.',
    0x8C54: ('=' * 76 + '\nMusic_Init: start song TempoAcc ($39). Far-call X=$03.\n'
             'Tempo table bit 0 selects LagMode.\n' + '=' * 76),
    0x8CBE: ('Raster budget per level (read as RasterBudgetTbl-2,x, so levels 0/1 would\n'
             'read the two code bytes before it).'),
    0x8CC6: ('=' * 76 + '\nMusic_Update: called once per frame from bank 0 ($FF84) with A in\n'
             'UpdateMode. In raster mode ($10) the time the update takes is padded to a\n'
             'constant: RasterBudget starts from a per-level value, every command executed\n'
             'subtracts 3, and the remainder is burned in the DelayYX loop afterwards.\n' + '=' * 76),
    0x8CFD: 'One frame of music and SFX processing.',
    0x8D30: 'Process one music channel (X = 0/4/8/12), honouring LagMode.',
    0x8D8D: 'Read events until a note is found. Commands jump back here.',
    0x8DF0: 'Non-tick frame: pitch slide, vibrato and volume envelope, then write the APU.',
    0x8EFD: 'Write the channel shadow registers to the APU ($4003 only when it changed).',
    0x8F23: ('=' * 76 + '\nSfx_Play*: start sound effect Temp ($3F) on one channel at once.\n'
             'Far-call X=$0C/$0F/$12/$15.\n' + '=' * 76),
    0x8F8A: 'Per-frame sound effect update (overrides the music on that channel).',
    0x9014: ('Dispatch command A (< $80) through CmdTbl; costs 3 RasterBudget units.'),
    0x9114: ('$44-$53: hardware note length. Sets reg0 ($1F, or a parameter for $4D-$53),\n'
             'sweep $43, and reg3 from HwLenTbl so the APU length counter cuts notes.'),
    0x917B: 'REPEAT_CALL with nesting: the previous level is pushed onto LoopStack.',
    0x930D: ('Attack presets: $16 nn (preset nn) or $25-$33 (presets 0-14). Each sets an\n'
             'attack volume (current volume) and a ramp from the EnvPreset tables.'),
}

DD_COMMENTS = {
    0x8996: 'delay: 5 cycles per count',
    0x89A5: 'sprite-0 hit yet?',
    0x89AC: 'switch PPU_CTRL for the lower part of the screen',
    0x8AE0: 'idle until the raster split has been done',
    0x8AEB: 'discard the return into the far-call stub',
    0x8B19: 'acceleration only for the first PcmCount samples',
    0x8B40: 'next segment when the level crosses a multiple of 64',
    0x8B8C: 'id 3 (start index 0) uses 5-bit lengths',
    0x8BA8: 'leftover: X is not used here',
    0x8BFF: 'A = random mod amplitude',
    0x8C09: 'centre it: + (127 - amplitude) / 2',
    0x8C67: 'bits 1-7 = tempo',
    0x8C6E: 'bit 0 = LagMode',
    0x8C8E: 'no REPEAT_CALL nesting yet',
    0x8CAA: 'echo off',
    0x8CD9: 'NB: index is level-2 into the table',
    0x8CE1: 'delay = remaining budget * 8 iterations',
    0x8D04: 'carry (TempoAcc wrapped) -> bit 7 = tick',
    0x8D21: 'LagMode: odd channels tick on the frame after a tick',
    0x8D54: 'note still sounding (no effects on tick frames)',
    0x8D56: 'a new event cancels any pitch slide',
    0x8D5B: 'echo: alternate the volume on every note',
    0x8D73: 'attack: restart the envelope from the attack volume',
    0x8DAF: 'noise channel: period = (note*2 - $82) / 2',
    0x8DBF: 'keep the length-counter bits',
    0x8DD0: 'note-on: write all registers ($4003 always)',
    0x8DD5: 'fixed duration, or read a duration byte',
    0x8F1B: 'skip $4003 if unchanged (avoids a phase reset)',
    0x8F33: 'same effect already playing: ignore',
    0x8F8E: 'count frames in the high nibble',
    0x8FB2: 'effect over: hand the channel back to the music',
    0x8FC5: '$01-$0F: command (only $02 and $04 belong here)',
    0x9014: 'each command costs 3 budget units',
    0x9180: 'already inside a loop: push the outer one',
    0x91CB: 'repeat the call, or continue after it',
    0x9212: 'NB: shares ChEchoVol/ChEchoXor with the echo effect',
    0x93E1: 'request a PCM sound; NMI plays it',
}

DD_OPERAND = {
    0x8982: '#<PcmOut_Vol0', 0x8986: '#>PcmOut_Vol0',
    0x918B: 'LoopStack,y', 0x9191: 'LoopStack+1,y', 0x9197: 'LoopStack+2,y',
    0x91F3: 'LoopStack-3,y', 0x91F9: 'LoopStack-2,y', 0x91FF: 'LoopStack-1,y',
}

def dd_misc(s):
    # raster budget table
    s.add_item(0x8CBE, 8, ['.byte ' + s.hexb(0x8CBE, 8)], 'data')
    s.comments[0x8CBE] = 'levels 2-9'
    # hardware length table (15 entries; entry 15 is the first byte of Cmd_Jump)
    s.add_item(0x915B, 15, ['.byte ' + s.hexb(0x915B, 8), '.byte ' + s.hexb(0x9163, 7)], 'data')
    s.comments[0x915B] = 'reg3 for $44-$52 (entry $53 reads the INY below)'
    for i, nm in enumerate(['EnvPresetDelay', 'EnvPresetSpeed', 'EnvPresetTarget']):
        a = 0x934F + i * 16
        s.add_item(a, 16, ['.byte ' + s.hexb(a, 16)], 'data')
    s.blocks[0x934F] = 'Envelope presets 0-15 (delay, speed, target volume) for $0D/$16/$25-$33.'
    s.add_item(0x9DBD, 13, ['.byte ' + s.hexb(0x9DBD, 13)], 'data')
    s.comments[0x9DBD] = 'LoopStack offset per channel (read with X = 0/4/8/12)'
    s.blocks[0x9DBD] = ''
    # code labels for overlapping entry
    s.blocks.setdefault(0x9798, 'Unreferenced bytes')

def dd_cmd_text(op, nm):
    if 0x25 <= op <= 0x33: return 'CMD_ATTACK_P+%d' % (op - 0x25)
    if 0x34 <= op <= 0x43: return 'CMD_VOL+%d' % (op - 0x34)
    if 0x44 <= op <= 0x53: return 'CMD_HWLEN+%d' % (op - 0x44)
    return 'CMD_' + nm

DD_HEADER = """;=============================================================================
; Battletoads & Double Dragon - The Ultimate Team (E) - sound engine, bank 3
; Rare, 1993. Labeled disassembly generated by tool/gen_disasm.py.
;
; Covers $8952-$B360 and $C05E-$CFDF (the gap $B361-$C05D is game code).
; Assemble with:
;   ca65 dd_sound.asm -o dd_sound.o && ld65 -C dd_sound.cfg dd_sound.o -o dd_sound
; and compare dd_sound.0.bin / dd_sound.1.bin with the ROM (bank 3 = file
; offset $0C010; $8952 -> $0C962, $C05E -> $1006E).
;
; Far-call interface (bank-0 stub $FFCB: X = jump-table offset, Y = bank 3):
;   X=$03 Music_Init  ($39 = song)      X=$06 Music_Update
;   X=$09 Pcm_PlayFullVol               X=$18/$1B Pcm_Play (pending drum)
;   X=$0C/$0F/$12/$15 Sfx_PlaySq1/Sq2/Tri/Noise ($3F = sound effect id)
;=============================================================================
"""

CONFIG_DD = dict(
    name='dd', bank=3,
    regions=[(0x8952, 0xB361), (0xC05E, 0xCFE0)], segments=['SOUND', 'SOUND2'],
    code_entries=[0x8952, 0x895E, 0x8C54, 0x8CC6, 0x8F23, 0x8F27, 0x8F2B, 0x8F2F, 0x8990],
    labels=DD_LABELS, blocks=DD_BLOCKS, comments=DD_COMMENTS,
    ram={a: v[0] for a, v in DD_RAM.items()},
    ram_defs=DD_RAM,
    ram_arrays=[(0x0354, 'ChTranspose', 13, 4)],
    extern={0x4000: 'SQ1_VOL', 0x4001: 'SQ1_SWEEP', 0x4002: 'SQ1_LO', 0x4003: 'SQ1_HI',
            0x4011: 'DMC_RAW', 0x2000: 'PPU_CTRL', 0x2002: 'PPU_STATUS',
            0xFFE1: 'FarCall_Return', 0xFFEB: 'DelayYX'},
    operand=DD_OPERAND,
    cmds=DD_CMDS, cmd_table=0x902D, ncmd=84, cmd_text=dd_cmd_text,
    period_table=0x940E, sfx_table=0x9488, nsfx=127,
    tempo_table=0x9DCA, track_table=0x9DE2, nsongs=24, tempo_mask=0xFE,
    pcm_wave=(0x89B8, 0x8A74), pcm_noise=0x8A74, pcm_tone=0x8A96, pcm_startidx=0x897C,
    data_builders=COMMON_BUILDERS, misc_builders=[dd_misc],
    foreign=[(0xC67D, 0xC6CD, 'GameCode_C67D',
              'Game code embedded in the music data (bank-3 jump-table entry X=$2D).\n'
              'Not part of the sound engine; kept as bytes.')],
    unref_notes={0x8ADB: 'Unreferenced: second terminator byte after PcmToneTbl',
                 0x9798: 'Unreferenced: an orphaned sound effect (header $30,$08,$0E, two steps, end)',
                 0xA08B: 'Unreferenced: orphaned track fragment',
                 0xC245: 'Unreferenced: orphaned note bytes',
                 0xC7E3: 'Unreferenced: orphaned track fragment (REPEAT_CALLs)',
                 0xCED8: 'Unreferenced: orphaned noise-track fragment',
                 0xCFDF: 'Unreferenced: last byte before game code'},
    tempo_doc=('Song tempo: bits 1-7 are added to TempoAcc each frame (a carry is one tick);\n'
               'bit 0 set = LagMode (Square 2 and Noise tick one frame after Square 1/Tri).'),
    sfx_doc=('Sound effect pointers, indexed by id/2 (ids are even; bit 0 is a flag).\n'
             'Same format as Battletoads.'),
    header=DD_HEADER,
)

def _consts(cfg, extra=''):
    return ('; ' + '-' * 76 + '\n' + cmd_constants(cfg['cmds']) + extra + '\n\n' + note_constants())

CONFIG_BT['constants'] = _consts(CONFIG_BT, '\n\nRetA_Lo              = ChRetSlot   ; CALL_A return address low byte (= $03A4)')
_dd_cmds = {k: v for k, v in DD_CMDS.items() if k < 0x25}
CONFIG_DD['constants'] = ('; ' + '-' * 76 + '\n' + cmd_constants(_dd_cmds) +
                          '\nCMD_ATTACK_P         = $25   ; +0..14: attack preset (no parameter)'
                          '\nCMD_VOL              = $34   ; +0..15: set volume (no parameter)'
                          '\nCMD_HWLEN            = $44   ; +0..8: hw length; +9..15: hw length + reg0 byte'
                          '\n\n' + note_constants())

CONFIGS = {'bt': CONFIG_BT, 'dd': CONFIG_DD}
