@ Macros for the WarioWare sound data (ww_music_data.s)

@ "A": sampled instrument (0x20 bytes)
@   key: fixed key used when the instrument sits in a drum map (R); nointerp: 1 = mix without interpolation
@   pan: s16 offset added to the channel pan when used from a drum map (127 = none)
@   envelope levels are 7.16 fixed point (0x7F0000 = full), rates are per 60 Hz frame
	.macro ins_sample key, nointerp, pan, sample, env_start, sustain, attack, decay, sustain_rate, release
	.byte 0x41, (\key) | ((\nointerp) << 7)
	.hword \pan
	.word \sample, \env_start, \sustain, \attack, \decay, \sustain_rate, \release
	.endm

@ "P": PSG instrument (0x24 bytes); psg bits 0-1 = channel (0 square 1, 1 square 2, 2 wave, 3 noise),
@   2-9 = SOUNDxCNT_H low byte (length/duty), 10-16 = sweep (square 1), 17-18 = duty, 19-31 = OR'd into SOUND4CNT_H
	.macro ins_psg key, nointerp, pan, wave, env_start, sustain, attack, decay, sustain_rate, release, psg
	.byte 0x50, (\key) | ((\nointerp) << 7)
	.hword \pan
	.word \wave, \env_start, \sustain, \attack, \decay, \sustain_rate, \release, \psg
	.endm

@ "R": drum map (8 bytes): key k plays table[k - base]
	.macro ins_drummap base, table
	.word 0x52 | ((\base) << 8)
	.word \table
	.endm

@ "S": key split (12 bytes): key k plays table[keymap[k - base]]
	.macro ins_split base, keymap, table
	.word 0x53 | ((\base) << 8)
	.word \keymap, \table
	.endm

@ Song table entry (20 bytes)
	.macro song_entry midi, bank, volume, priority, player, w8, name, id
	.word \midi
	.word (\player) | ((\bank) << 5) | ((\volume) << 15) | ((\priority) << 22)
	.word \w8, \name, \id
	.endm

@ Sample header (24 bytes); length and loop points in samples
	.macro sample_hdr length, rate, root, loop_start, loop_end, pcm
	.word \length, \rate, \root, \loop_start, \loop_end, \pcm
	.endm

@ Player configuration (20 bytes)
	.macro player_cfg index, channels, prio_check, chans, synth, tracks, player
	.hword (\index) | ((\channels) << 5) | ((\prio_check) << 10), 0
	.word \chans, \synth, \tracks, \player
	.endm
