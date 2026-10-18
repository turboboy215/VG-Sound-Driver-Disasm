"""Build a test ROM that runs only the sound driver, and verify the parse against emulated reads.

harness ROM = rebuilt ROM + (vectors -> reti) + harness loop at $0150 (game init overwritten).
Command interface (WRAM): CMD=1 play song ARG, CMD=2 play SFX ARG, CMD=3 extra (game-specific), cleared by harness.

verify: hooks every `ld a,[de]` (and listed extra sites) inside the driver code, plays every song and SFX,
records each address read, and checks it against the generator's model (model.json 'reads').
"""
import os, sys, json, subprocess

HARNESS_ASM = r'''
INCLUDE "{inc}"
DEF CMD EQU $C000
DEF ARG EQU $C001
DEF FRAMES EQU $C002

SECTION "vec40", ROM0[$40]
	reti
SECTION "vec48", ROM0[$48]
	reti
SECTION "vec50", ROM0[$50]
	reti
SECTION "vec58", ROM0[$58]
	reti
SECTION "vec60", ROM0[$60]
	reti
SECTION "entry", ROM0[$100]
	nop
	jp Harness

SECTION "harness", ROM0[{haddr}]
Harness:
	di
	ld sp, {sp}
	xor a
	ld [CMD], a
	ld [FRAMES], a
	ld a, {bank}
	ld [{mbc}], a
{pre}
	call {init}
	ld a, 1
	ldh [$FFFF], a
.loop
	xor a
	ldh [$FF0F], a
	halt
	nop
	ld a, {bank}
	ld [{mbc}], a
	ld a, [CMD]
	and a
	jr z, .upd
	cp 1
	jr nz, .notsong
	ld a, [ARG]
{song}
	jr .done
.notsong
	cp 2
	jr nz, .notsfx
	ld a, [ARG]
{sfx}
	jr .done
.notsfx
{extra}
.done
	xor a
	ld [CMD], a
.upd
{update}
	ld hl, FRAMES
	inc [hl]
	jr .loop
{sections}
'''


def build_harness(outdir, rom_rebuilt, p, rgbds=None):
    """p: dict(bank, mbc, init, song, sfx, update, pre='', extra='', sp='$CFF0', haddr='$0150', inc)"""
    hd = os.path.join(outdir, 'harness')
    os.makedirs(hd, exist_ok=True)
    q = dict(pre='', extra='', sp='$CFF0', haddr='$0150', sections='')
    q.update(p)
    asm = HARNESS_ASM.format(**q)
    open(os.path.join(hd, 'harness.asm'), 'w', newline='\n').write(asm)
    rgbds = rgbds if rgbds is not None else os.environ.get('RGBDS', '')
    tool = lambda n: os.path.join(rgbds, n) if rgbds else n
    r = lambda *a: subprocess.run(a, cwd=hd, check=True)
    r(tool('rgbasm'), '-Wall', '-o', 'harness.o', 'harness.asm')
    r(tool('rgblink'), '-O', os.path.abspath(rom_rebuilt), '-o', 'harness.gb', 'harness.o')
    r(tool('rgbfix'), '-f', 'gh', 'harness.gb')
    return os.path.join(hd, 'harness.gb')


def run_verify(rom, hooks, model, jobs, frames_song=3600, frames_sfx=600, cmd_extra=None, setup=None, quiet=True, bankfn=None, stop=None):
    """hooks: list of (bank, addr, regname) ; jobs: list of (cmd, arg, frames, label)."""
    import logging
    from pyboy import PyBoy
    logging.getLogger('pyboy').setLevel(logging.ERROR)
    pb = PyBoy(rom, window='null', sound_emulated=False, no_input=True, log_level='ERROR')
    reads = {}
    cur = [None]

    def mk(reg):
        def cb(ctx):
            rf = pb.register_file
            if reg == 'de':
                a = (rf.D << 8) | rf.E
            elif reg == 'hl':
                a = rf.HL
            else:
                a = (rf.B << 8) | rf.C
            if bankfn is not None and a >= 0x4000 and a < 0x8000:
                a = (bankfn(pb), a)
            reads.setdefault(a, set()).add(cur[0])
        return cb
    for bank, addr, reg in hooks:
        pb.hook_register(bank, addr, mk(reg), None)
    for _ in range(600):
        pb.tick(1, False)
        if pb.memory[0xC002] > 2:
            break
    else:
        raise RuntimeError('harness did not start')
    per_job = {}
    for cmd, arg, frames, label in jobs:
        before = set(reads)
        cur[0] = label
        if setup:
            setup(pb, cmd, arg)
        pb.memory[0xC001] = arg
        pb.memory[0xC000] = cmd
        pb.tick(frames, False)
        # stop
        if stop is not None:
            for sc, sa in stop:
                pb.memory[0xC001] = sa
                pb.memory[0xC000] = sc
                pb.tick(2, False)
        elif cmd in (1, 2):
            pb.memory[0xC001] = 0xFF
            pb.memory[0xC000] = cmd
            pb.tick(2, False)
        per_job[label] = len([a for a in reads if label in reads[a]])
    pb.stop(save=False)
    return reads, per_job
