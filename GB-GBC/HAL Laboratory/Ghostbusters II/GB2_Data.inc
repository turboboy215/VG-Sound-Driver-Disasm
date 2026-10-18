; bank 7: sound headers and streams ($48C1-$69EA)

; sound 0 is never started (id 0 = empty queue). Its header has no terminator of its own and
; runs on into Sound46 (stop the music channels): together they cover channels 4-7 and 0-3.
Sound00:
	channel 4, Sound_SilenceStream
	channel 5, Sound_SilenceStream
	channel 6, Sound_SilenceStream
	channel 7, Sound_SilenceStream
Sound46:
	channel 0, Sound_SilenceStream
	channel 1, Sound_SilenceStream
	channel 2, Sound_SilenceStream
	channel 3, Sound_SilenceStream
Sound_SilenceStream:
	snd_end  ; header terminator, also the stream of every channel above
Sound01:
	channel 0, Sound01_M1
	channel 1, Sound01_M2
	channel 2, Sound01_M3
	channel 3, Sound01_M4
	end_header
Sound01_M1:
	envelope 19
	duty $80
	attenuate 5
	length 45
	note B_, 2
	envelope 13
	duty $40
	attenuate 5
	length 34
	rest
	length 36
	note B_, 1
	length 34
	rest
	snd_call Sub_4974
	length 34
	rest
	length 36
	note B_, 1
	length 34
	rest
	snd_call Sub_4974
	loop 4
	duty $80
	length 34
	note D_, 3
	note B_, 2
	sweep $FF
	length 35
	note B_, 2
	sweep_off
	length 33
	rest
	snd_call Sub_4974
	duty $80
	length 34
	note B_, 2
	note B_, 2
	sweep $FF
	length 34
	note A_, 2
	sweep_off
	length 34
	rest
	snd_call Sub_4974
	endloop
	duty $80
	loop 2
	length 31
	note C_, 3
	note C#, 3
	length 43
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 35
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 31
	note C_, 3
	note C#, 3
	length 43
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 35
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 31
	note C#, 3
	length 0
	note D_, 3
	length 33
	rest
	note B_, 2
	rest
	note A_, 2
	note A#, 2
	note B_, 2
	rest
	endloop
	duty $40
	length 34
	rest
	length 36
	note B_, 1
	length 34
	rest
	snd_call Sub_4974
	length 34
	rest
	length 36
	note B_, 1
	length 34
	rest
	length 36
	note A_, 2
	length 34
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	length 34
	rest
	length 39
	note B_, 1
	snd_end
Sub_4974:
	duty $40
	length 36
	note A_, 2
	note G#, 2
	snd_ret
Sound01_M2:
	envelope 19
	duty $80
	attenuate 5
	length 45
	note F#, 2
	envelope 13
	duty $40
	attenuate 5
	length 34
	rest
	length 36
	note F#, 1
	length 34
	rest
	snd_call Sub_4A28
	length 34
	rest
	length 36
	note F#, 1
	length 34
	rest
	snd_call Sub_4A28
	loop 4
	duty $80
	attenuate 8
	length 33
	rest
	length 34
	note D_, 3
	note B_, 2
	length 35
	rest
	snd_call Sub_4A28
	duty $80
	attenuate 8
	length 33
	rest
	length 34
	note B_, 2
	note B_, 2
	length 35
	rest
	snd_call Sub_4A28
	endloop
	length 34
	rest
	duty $80
	attenuate 8
	length 31
	note C_, 3
	note C#, 3
	length 43
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 35
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 31
	note C_, 3
	note C#, 3
	length 43
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 35
	note D_, 3
	length 33
	note B_, 2
	length 34
	rest
	length 31
	note C#, 3
	length 0
	note D_, 3
	length 33
	rest
	note B_, 2
	rest
	note A_, 2
	note A#, 2
	attenuate 5
	length 31
	note E_, 3
	note F_, 3
	length 43
	note F#, 3
	length 33
	note D_, 3
	length 34
	rest
	length 35
	note F#, 3
	length 33
	note D_, 3
	length 34
	rest
	length 31
	note E_, 3
	note F_, 3
	length 43
	note F#, 3
	length 33
	note D_, 3
	length 34
	rest
	length 35
	note F#, 3
	length 33
	note D_, 3
	length 34
	rest
	length 63
	note A#, 3
	length 44
	note B_, 3
	duty $40
	length 34
	rest
	length 36
	note F#, 1
	length 34
	rest
	snd_call Sub_4A28
	length 34
	rest
	length 36
	note F#, 1
	length 34
	rest
	length 36
	note E_, 2
	length 34
	note E_, 2
	length 33
	note E_, 2
	note E_, 2
	length 34
	rest
	length 39
	note F#, 1
	snd_end
Sub_4A28:
	duty $40
	attenuate 5
	length 36
	note E_, 2
	note E_, 2
	snd_ret
Sound01_M3:
	envelope 1
	length 45
	rest
Seq_4A34:
	loop 10
	snd_call Sub_4A78
	endloop
	length 39
	note B_, 1
	length 36
	note A_, 1
	length 40
	note A_, 1
	length 39
	note G#, 1
	length 36
	note E_, 2
	length 40
	note E_, 2
	snd_call Sub_4A78
	length 33
	note B_, 1
	rest
	length 34
	note B_, 1
	length 33
	note B_, 1
	note D#, 2
	length 34
	note F#, 2
	length 33
	note A_, 2
	rest
	note A_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	note E_, 2
	length 34
	rest
	note B_, 2
	length 47
	note A#, 2
	note A_, 2
	note G#, 2
	note G_, 2
	note F#, 2
	note F_, 2
	note E_, 2
	note D#, 2
	note D_, 2
	note C#, 2
	note C_, 2
	note B_, 1
	note A#, 1
	note A_, 1
	note G#, 1
	note G_, 1
	note F#, 1
	note F_, 1
	note E_, 1
	note D#, 1
	note D_, 1
	note C#, 1
	note C_, 1
	snd_end
Sub_4A78:
	length 33
	note B_, 1
	rest
	length 34
	note B_, 1
	length 33
	note B_, 1
	note D#, 2
	length 34
	note F#, 2
	length 33
	note A_, 2
	rest
	note A_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	rest
	snd_ret
Sound01_M4:
	length 36
	rest
	length 38
	rest
Seq_4A90:
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	snd_call Sub_4BF5
	length 33
	loop 16
	envelope 6
	attenuate 3
	drum 9
	endloop
	loop 7
	snd_call Sub_4BF5
	endloop
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 5
	attenuate 1
	drum 1
	snd_call Sub_4BF5
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 5
	attenuate 1
	drum 1
	snd_call Sub_4BF5
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 5
	attenuate 1
	drum 1
	snd_call Sub_4BF5
	length 33
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 0
	drum 14
	length 63
	envelope 7
	attenuate 11
	drum 8
	length 47
	envelope 7
	attenuate 11
	drum 8
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	length 63
	envelope 7
	attenuate 11
	drum 8
	length 47
	envelope 7
	attenuate 11
	drum 8
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 5
	attenuate 1
	drum 1
	envelope 6
	attenuate 3
	drum 9
	length 34
	rest
	length 39
	envelope 9
	attenuate 4
	drum 3
	snd_end
Sub_4BF5:
	length 34
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	snd_ret
Sound02:
	channel 0, Sound02_M1
	channel 1, Sound02_M2
	channel 2, Sound02_M3
	channel 3, Sound02_M4
	end_header
Sound02_M1:
	envelope 11
	duty $80
	attenuate 6
	length 17
	note C_, 3
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note C_, 3
	note B_, 2
	rest
	note B_, 2
	length 20
	rest
	length 17
	note C_, 3
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note C_, 3
	note D_, 3
	rest
	note B_, 2
	length 20
	rest
	length 17
	note C_, 3
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note C_, 3
	note B_, 2
	rest
	note B_, 2
	length 20
	rest
	length 17
	note C_, 3
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note C_, 3
	note D_, 3
	rest
	note E_, 3
	envelope 6
	note E_, 4
	note C_, 4
	note D_, 4
	note G_, 3
	snd_jump Sound02_M1
Sound02_M2:
	envelope 11
	duty $80
	attenuate 6
	length 17
	note A_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note A_, 2
	note G_, 2
	rest
	note G_, 2
	length 20
	rest
	length 17
	note A_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note A_, 2
	note B_, 2
	rest
	note G_, 2
	length 20
	rest
	length 17
	note A_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note A_, 2
	note G_, 2
	rest
	note G_, 2
	length 20
	rest
	length 17
	note A_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note A_, 2
	note B_, 2
	rest
	note C_, 3
	envelope 6
	attenuate 10
	length 16
	rest
	length 17
	note E_, 4
	note C_, 4
	note D_, 4
	length 16
	note G_, 3
	snd_jump Sound02_M2
Sound02_M3:
	envelope 1
	length 16
	note G_, 1
	rest
	note G_, 1
	rest
	note G_, 1
	rest
	rest
	rest
	note G_, 1
	rest
	note G_, 1
	rest
	rest
	rest
	note G_, 1
	rest
	length 19
	rest
	length 16
	note C_, 2
	rest
	note C_, 2
	rest
	rest
	rest
	note E_, 2
	rest
	rest
	rest
	snd_jump Sound02_M3
Sound02_M4:
	length 17
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	envelope 6
	attenuate 3
	drum 9
	length 18
	envelope 5
	attenuate 1
	drum 1
	length 17
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	length 0
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	length 49
	envelope 7
	attenuate 11
	drum 8
	snd_jump Sound02_M4
Sound03:
	channel 1, Sound03_M2
	channel 0, Sound03_M1
	channel 2, Sound03_M3
	channel 3, Sound03_M4
	end_header
Sound03_M2:
	envelope 13
	duty $80
	attenuate 5
	length 18
	note A_, 2
	length 17
	note A_, 2
	rest
	length 16
	note F#, 2
	rest
	note F#, 2
	rest
	length 18
	note G_, 2
	length 17
	note G_, 2
	rest
	length 16
	note A_, 2
	rest
	note A_, 2
	rest
	length 18
	note F#, 2
	length 17
	note F#, 2
	rest
	length 16
	note G_, 2
	rest
	note G_, 2
	rest
	length 52
	note F#, 2
	rest
	snd_jump Sound03_M2
Sound03_M1:
	envelope 13
	duty $80
	attenuate 5
	length 18
	note F#, 2
	length 17
	note F#, 2
	rest
	length 16
	note D_, 2
	rest
	note D_, 2
	rest
	length 18
	note E_, 2
	length 17
	note E_, 2
	rest
	length 16
	note F#, 2
	rest
	note F#, 2
	rest
	length 18
	note D_, 2
	length 17
	note D_, 2
	rest
	length 16
	note E_, 2
	rest
	note E_, 2
	rest
	length 52
	note D_, 2
	rest
	snd_jump Sound03_M1
Sound03_M3:
	envelope 1
	length 17
	note D_, 2
	rest
	note D_, 2
	rest
	length 16
	note F#, 2
	rest
	note A_, 2
	rest
	length 47
	note A#, 2
	length 35
	note B_, 2
	length 52
	note A_, 2
	snd_jump Sound03_M3
Sound03_M4:
	length 17
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	length 16
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	snd_jump Sound03_M4
Sound04:
	channel 0, Sound04_M1
	channel 1, Sound04_M2
	channel 2, Sound04_M3
	channel 3, Sound04_M4
	end_header
Sound04_M1:
	envelope 11
	duty $80
	attenuate 4
	loop 4
	length 17
	note G_, 2
	length 19
	rest
	length 17
	note G#, 2
	length 19
	rest
	length 17
	note F_, 2
	rest
	note G#, 2
	note G_, 2
	length 20
	rest
	endloop
	loop 4
	length 17
	note G_, 2
	length 19
	rest
	length 17
	note A_, 2
	length 19
	rest
	length 17
	note F_, 2
	rest
	note A_, 2
	note G_, 2
	length 20
	rest
	endloop
	loop 4
	length 17
	note G_, 2
	length 19
	rest
	length 17
	note G#, 2
	length 19
	rest
	length 17
	note F_, 2
	rest
	note G#, 2
	note G_, 2
	length 20
	rest
	endloop
	loop 3
	length 17
	note G_, 2
	length 19
	rest
	length 17
	note A_, 2
	length 19
	rest
	length 17
	note F_, 2
	rest
	note A_, 2
	note G_, 2
	length 20
	rest
	endloop
	length 17
	note G_, 2
	note A_, 2
	rest
	note B_, 2
	rest
	note C_, 3
	rest
	note D_, 3
	rest
	note E_, 3
	rest
	note E_, 3
	note E_, 3
	rest
	rest
	rest
	snd_jump Sound04_M1
Sound04_M2:
	envelope 11
	duty $80
	attenuate 4
	loop 4
	length 17
	note D#, 2
	length 19
	rest
	length 17
	note F_, 2
	length 19
	rest
	length 17
	note D_, 2
	rest
	note F_, 2
	note D#, 2
	length 20
	rest
	endloop
	loop 4
	length 17
	note E_, 2
	length 19
	rest
	length 17
	note F_, 2
	length 19
	rest
	length 17
	note D_, 2
	rest
	note F_, 2
	note E_, 2
	length 20
	rest
	endloop
	loop 4
	length 17
	note D#, 2
	length 19
	rest
	length 17
	note F_, 2
	length 19
	rest
	length 17
	note D_, 2
	rest
	note F_, 2
	note D#, 2
	length 20
	rest
	endloop
	loop 3
	length 17
	note E_, 2
	length 19
	rest
	length 17
	note F_, 2
	length 19
	rest
	length 17
	note D_, 2
	rest
	note F_, 2
	note E_, 2
	length 20
	rest
	endloop
	length 17
	note E_, 2
	note F_, 2
	rest
	note G_, 2
	rest
	note A_, 2
	rest
	note B_, 2
	rest
	note C_, 3
	rest
	note C_, 3
	note C_, 3
	rest
	rest
	rest
	snd_jump Sound04_M2
Sound04_M3:
	envelope 1
	loop 4
	snd_call Sub_4F47
	endloop
	loop 4
	snd_call Sub_4F59
	endloop
	loop 4
	snd_call Sub_4F47
	endloop
	loop 3
	snd_call Sub_4F59
	endloop
	length 16
	note F_, 2
	length 63
	rest
	length 17
	note F_, 2
	rest
	note F_, 2
	rest
	note F_, 2
	rest
	note F_, 2
	rest
	note G_, 2
	rest
	length 16
	note G_, 2
	length 63
	rest
	length 17
	note G_, 2
	rest
	rest
	rest
	snd_jump Sound04_M3
Sub_4F47:
	length 17
	note D#, 2
	rest
	note D#, 2
	note A#, 1
	rest
	note A#, 1
	rest
	note C_, 2
	rest
	note D#, 2
	rest
	note D#, 2
	note D#, 2
	rest
	note A#, 1
	rest
	snd_ret
Sub_4F59:
	length 17
	note C_, 2
	rest
	note C_, 2
	note G_, 1
	rest
	note G_, 1
	rest
	note B_, 1
	rest
	note C_, 2
	rest
	note C_, 2
	note C_, 2
	rest
	note G_, 1
	rest
	snd_ret
Sound04_M4:
	loop 15
	length 18
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 0
	drum 14
	length 17
	rest
	envelope 2
	attenuate 0
	drum 14
	length 18
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	endloop
	length 17
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	length 19
	rest
	snd_jump Sound04_M4
Sound05:
	channel 0, Sound05_M1
	channel 1, Sound05_M2
	channel 2, Sound05_M3
	channel 3, Sound05_M4
	end_header
Sound05_M1:
	envelope 13
	duty $80
	attenuate 4
	loop 4
	length 16
	note D#, 3
	length 63
	rest
	length 17
	note D#, 3
	rest
	note D#, 3
	length 20
	rest
	length 17
	rest
	note D#, 3
	rest
	rest
	length 16
	note D#, 3
	length 63
	rest
	length 17
	note D#, 3
	rest
	note D#, 3
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	rest
	length 20
	note C_, 3
	note C#, 3
	endloop
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	length 22
	note E_, 3
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	length 22
	note F_, 3
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	length 22
	note E_, 3
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	note D_, 3
	rest
	length 16
	note D_, 3
	length 63
	rest
	length 17
	note D_, 3
	rest
	note D_, 3
	rest
	rest
	note E_, 3
	rest
	rest
	rest
	note F#, 3
	rest
	rest
	rest
	note G#, 3
	rest
	rest
	length 20
	note B_, 3
	snd_jump Sound05_M1
Sound05_M2:
	envelope 13
	duty $80
	attenuate 4
	loop 4
	length 16
	note G_, 2
	length 63
	rest
	length 17
	note G_, 2
	rest
	note G_, 2
	length 20
	rest
	length 17
	rest
	note G_, 2
	rest
	rest
	length 16
	note G_, 2
	length 63
	rest
	length 17
	note G_, 2
	rest
	note G_, 2
	length 16
	note F_, 2
	length 63
	rest
	length 17
	note F_, 2
	rest
	note F_, 2
	rest
	note F_, 2
	rest
	rest
	length 20
	note G#, 2
	note G#, 2
	endloop
	loop 3
	length 16
	note B_, 2
	length 63
	rest
	length 17
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	length 16
	note B_, 2
	length 63
	rest
	length 17
	note B_, 2
	rest
	note B_, 2
	rest
	length 16
	note B_, 2
	length 63
	rest
	length 17
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	length 22
	note C_, 3
	endloop
	length 16
	note B_, 2
	length 63
	rest
	length 17
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	length 16
	note B_, 2
	length 63
	rest
	length 17
	note B_, 2
	rest
	note B_, 2
	rest
	rest
	note C_, 3
	rest
	rest
	rest
	note D_, 3
	rest
	rest
	rest
	note E_, 3
	rest
	rest
	length 20
	note F_, 3
	snd_jump Sound05_M2
Sound05_M3:
	envelope 1
	loop 4
	length 16
	note D#, 2
	length 63
	rest
	length 16
	note A#, 1
	length 63
	rest
	length 16
	note C_, 2
	length 63
	rest
	length 16
	note D#, 2
	length 63
	rest
	length 20
	rest
	length 17
	rest
	note D_, 2
	note D#, 2
	note F_, 2
	note G_, 2
	note G#, 2
	note F_, 2
	note G_, 2
	note D#, 2
	note F_, 2
	note G_, 2
	note G#, 1
	rest
	note G#, 1
	rest
	note G#, 1
	length 20
	note C#, 2
	note D#, 2
	endloop
	length 16
	note E_, 2
	length 63
	rest
	length 17
	note E_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	rest
	length 16
	note E_, 2
	length 63
	rest
	length 17
	note E_, 2
	rest
	note E_, 2
	rest
	length 16
	note C_, 2
	length 63
	rest
	length 17
	note C_, 2
	rest
	note C_, 2
	rest
	note C_, 2
	rest
	note C_, 2
	length 20
	note D_, 2
	note D_, 2
	length 16
	note E_, 2
	length 63
	rest
	length 17
	note E_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	rest
	note E_, 2
	rest
	length 16
	note E_, 2
	length 63
	rest
	length 17
	note E_, 2
	rest
	note E_, 2
	rest
	length 16
	note C_, 2
	length 63
	rest
	length 17
	note C_, 2
	rest
	note C_, 2
	rest
	note C_, 2
	rest
	note C_, 2
	length 20
	note A_, 1
	note A_, 1
	length 19
	note E_, 2
	length 16
	note B_, 1
	length 63
	rest
	length 19
	note B_, 1
	length 16
	note E_, 2
	length 63
	rest
	length 19
	note E_, 2
	length 16
	note B_, 1
	length 63
	rest
	length 19
	note B_, 1
	length 16
	note E_, 2
	length 63
	rest
	length 19
	note C_, 2
	length 16
	note G_, 1
	length 63
	rest
	length 19
	note G_, 1
	length 16
	note C_, 2
	length 63
	rest
	length 19
	note D_, 2
	length 16
	note A_, 1
	length 63
	rest
	length 18
	note A_, 1
	note D_, 2
	length 19
	note E_, 2
	length 16
	note B_, 1
	length 63
	rest
	length 19
	note B_, 1
	length 16
	note E_, 2
	length 63
	rest
	length 19
	note E_, 2
	length 16
	note B_, 1
	length 63
	rest
	length 19
	note B_, 1
	length 16
	note E_, 2
	length 63
	rest
	length 17
	rest
	note D_, 1
	rest
	rest
	rest
	note E_, 1
	rest
	rest
	rest
	note F#, 1
	rest
	rest
	length 20
	note G_, 1
	snd_jump Sound05_M3
Sound05_M4:
	loop 3
	snd_call Sub_531E
	endloop
	length 20
	envelope 9
	attenuate 4
	drum 3
	length 17
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	loop 3
	snd_call Sub_531E
	endloop
	length 20
	envelope 9
	attenuate 4
	drum 3
	length 17
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	length 18
	envelope 5
	attenuate 1
	drum 1
	loop 3
	snd_call Sub_531E
	endloop
	length 20
	envelope 9
	attenuate 4
	drum 3
	length 17
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	loop 3
	snd_call Sub_531E
	endloop
	length 20
	envelope 9
	attenuate 4
	drum 3
	length 16
	envelope 7
	attenuate 11
	drum 8
	length 63
	envelope 7
	attenuate 11
	drum 8
	length 17
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	loop 2
	length 17
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 6
	attenuate 3
	drum 9
	length 22
	envelope 9
	attenuate 4
	drum 3
	endloop
	loop 3
	snd_call Sub_5348
	endloop
	loop 3
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 3
	attenuate 4
	drum 1
	endloop
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 5
	attenuate 1
	drum 1
	snd_jump Sound05_M4
Sub_531E:
	length 17
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	snd_ret
Sub_5348:
	length 17
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	snd_ret
Sound06:
	channel 1, Sound06_M2
	channel 0, Sound06_M1
	channel 2, Sound06_M3
	channel 3, Sound06_M4
	end_header
Sound06_M2:
	envelope 11
	duty $80
	attenuate 7
Seq_53AD:
	loop 4
	length 1
	note B_, 2
	note D_, 3
	rest
	note G_, 2
	rest
	note D_, 3
	rest
	note B_, 2
	rest
	note E_, 3
	rest
	note D_, 3
	note C#, 3
	rest
	note D_, 3
	rest
	endloop
Seq_53C1:
	envelope 11
	loop 8
	length 1
	note B_, 2
	note D_, 3
	rest
	note G_, 2
	rest
	note D_, 3
	rest
	note B_, 2
	rest
	note E_, 3
	rest
	note D_, 3
	note C#, 3
	rest
	note D_, 3
	rest
	endloop
	snd_call Sub_53F2
	snd_call Sub_53F2
	snd_call Sub_5404
	snd_call Sub_5404
	snd_call Sub_53F2
	snd_call Sub_53F2
	snd_call Sub_5404
	snd_call Sub_5404
	snd_jump Seq_53C1
Sub_53F2:
	length 1
	note A_, 3
	rest
	note A#, 2
	note F_, 3
	rest
	note D_, 3
	rest
	note A_, 3
	rest
	note A#, 2
	rest
	note F_, 3
	note F_, 3
	rest
	note D_, 3
	rest
	snd_ret
Sub_5404:
	length 1
	note G#, 3
	rest
	note A_, 2
	note E_, 3
	rest
	note C#, 3
	rest
	note G#, 3
	rest
	note A_, 2
	rest
	note E_, 3
	note E_, 3
	rest
	note C#, 3
	rest
	snd_ret
Sound06_M1:
	envelope 11
	duty $80
	attenuate 10
	length 2
	rest
	snd_jump Seq_53AD
Sound06_M3:
	envelope 1
	length 8
	note G_, 1
	note E_, 1
	note D_, 1
	length 7
	note C#, 1
	envelope 15
	loop 3
	length 0
	note C#, 1
	length 63
	rest
	endloop
Seq_5432:
	envelope 15
	loop 16
	length 0
	note G_, 1
	length 63
	rest
	endloop
	loop 16
	length 0
	note E_, 1
	length 63
	rest
	endloop
	loop 16
	length 0
	note G_, 1
	length 63
	rest
	endloop
	loop 16
	length 0
	note E_, 1
	length 63
	rest
	endloop
	loop 16
	length 0
	note G_, 1
	length 63
	rest
	endloop
	loop 16
	length 0
	note E_, 1
	length 63
	rest
	endloop
	loop 16
	length 0
	note G_, 1
	length 63
	rest
	endloop
	loop 16
	length 0
	note E_, 1
	length 63
	rest
	endloop
	envelope 1
	loop 2
	length 3
	note G_, 1
	length 1
	note A#, 1
	rest
	length 3
	note F_, 2
	note G_, 1
	length 1
	note D_, 2
	rest
	length 3
	note A_, 2
	endloop
	loop 2
	length 3
	note F#, 1
	length 1
	note A_, 1
	rest
	length 3
	note E_, 2
	note F#, 1
	length 1
	note C#, 2
	rest
	length 3
	note G#, 2
	endloop
	loop 2
	length 3
	note G_, 1
	length 1
	note A#, 1
	rest
	length 3
	note F_, 2
	note G_, 1
	length 1
	note D_, 2
	rest
	length 3
	note A_, 2
	endloop
	loop 2
	length 3
	note F#, 1
	length 1
	note A_, 1
	rest
	length 3
	note E_, 2
	note F#, 1
	length 1
	note C#, 2
	rest
	length 3
	note G#, 2
	endloop
	snd_jump Seq_5432
Sound06_M4:
	length 1
	envelope 3
	attenuate 4
	drum 1
	loop 31
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	endloop
Seq_54C4:
	envelope 2
	attenuate 0
	drum 14
	envelope 3
	attenuate 4
	drum 1
	envelope 6
	attenuate 3
	drum 9
	envelope 3
	attenuate 4
	drum 1
	snd_jump Seq_54C4
Sound07:
	channel 0, Sound07_M1
	channel 1, Sound07_M2
	channel 2, Sound07_M3
	channel 3, Sound07_M4
	end_header
Sound07_M1:
	envelope 13
	duty $80
	attenuate 5
	length 0
	note A#, 1
	note C_, 2
	note C#, 2
	note D#, 2
	length 49
	note F_, 2
	note F#, 2
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	length 39
	note G_, 2
	length 33
	rest
	length 10
	note D#, 2
	note F_, 2
	length 17
	note G_, 2
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	note G_, 2
	length 40
	rest
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	length 39
	note G_, 2
	length 33
	rest
	length 10
	note D#, 2
	note F_, 2
	length 17
	note G_, 2
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	note G_, 2
	length 40
	rest
	loop 2
	length 33
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	rest
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	endloop
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	rest
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	rest
	note G_, 3
	rest
	note D#, 3
	rest
	note D_, 3
	note D#, 3
	rest
	note F_, 3
	rest
	loop 2
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	rest
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	endloop
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	rest
	note G_, 3
	rest
	note D#, 3
	rest
	note F_, 3
	note G_, 3
	rest
	note G#, 3
	rest
	length 33
	note A#, 3
	rest
	note A#, 3
	rest
	length 16
	note A#, 3
	length 48
	rest
	length 33
	note A#, 3
	rest
	note C_, 4
	rest
	rest
	rest
	note C_, 4
	length 34
	note C_, 4
	snd_end
Sound07_M2:
	envelope 13
	duty $80
	attenuate 8
	length 34
	rest
	length 0
	note A#, 1
	note C_, 2
	note C#, 2
	note D#, 2
	length 49
	note F_, 2
	note F#, 2
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	length 39
	note G_, 2
	length 33
	rest
	length 10
	note D#, 2
	note F_, 2
	length 17
	note G_, 2
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	note G_, 2
	length 40
	rest
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	length 39
	note G_, 2
	length 33
	rest
	length 10
	note D#, 2
	note F_, 2
	length 17
	note G_, 2
	length 39
	note G#, 2
	length 33
	note G#, 2
	note G#, 2
	rest
	note G_, 2
	length 40
	rest
	attenuate 9
	loop 2
	length 33
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	rest
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	endloop
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	rest
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	rest
	note G_, 3
	rest
	note D#, 3
	rest
	note D_, 3
	note D#, 3
	rest
	note F_, 3
	rest
	loop 2
	length 33
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	rest
	note F_, 3
	rest
	note C#, 3
	rest
	note F#, 3
	note F_, 3
	rest
	note C#, 3
	rest
	endloop
	note G#, 3
	note G_, 3
	rest
	note D#, 3
	rest
	note G#, 3
	rest
	note G_, 3
	rest
	note D#, 3
	rest
	note F_, 3
	note G_, 3
	rest
	attenuate 5
	note G_, 3
	rest
	note G_, 3
	rest
	length 16
	note G_, 3
	length 48
	rest
	length 33
	note G_, 3
	rest
	note G#, 3
	rest
	rest
	rest
	note G_, 3
	length 34
	note G_, 3
	snd_end
Sound07_M3:
	envelope 1
	length 20
	rest
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 34
	note G#, 1
	length 16
	note G#, 1
	length 48
	rest
	note C#, 2
	length 16
	rest
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 33
	rest
	note A#, 1
	length 34
	note A#, 1
	length 16
	note A#, 1
	length 48
	rest
	note D#, 2
	length 16
	rest
	length 34
	note D#, 2
	length 16
	note D#, 2
	length 48
	rest
	note A#, 1
	length 16
	rest
	length 34
	note A#, 1
	length 16
	note A#, 1
	length 48
	rest
	note D#, 2
	length 16
	rest
	length 10
	note C_, 2
	note D_, 2
	length 17
	note D#, 2
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 34
	note G#, 1
	length 16
	note G#, 1
	length 48
	rest
	note C#, 2
	length 16
	rest
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 33
	rest
	note A#, 1
	length 33
	note G_, 2
	note G#, 2
	length 15
	note G#, 1
	length 49
	rest
	length 47
	note G#, 3
	length 16
	rest
	length 15
	note G#, 1
	length 49
	rest
	length 33
	note D#, 2
	rest
	length 48
	note D#, 2
	length 16
	rest
	length 34
	note D#, 3
	length 33
	rest
	length 16
	note D#, 3
	length 48
	rest
	length 33
	note F#, 3
	note F_, 3
	note C#, 3
	note A#, 2
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 34
	note G#, 1
	length 16
	note G#, 1
	length 48
	rest
	note C#, 2
	length 16
	rest
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 33
	rest
	note A#, 1
	length 34
	note A#, 1
	length 16
	note A#, 1
	length 48
	rest
	note D#, 2
	length 16
	rest
	length 34
	note D#, 2
	length 16
	note D#, 2
	length 48
	rest
	note A#, 1
	length 16
	rest
	length 34
	note A#, 1
	length 16
	note A#, 1
	length 48
	rest
	note D#, 2
	length 16
	rest
	length 10
	note C_, 2
	note D_, 2
	length 17
	note D#, 2
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 34
	note G#, 1
	length 16
	note G#, 1
	length 48
	rest
	note C#, 2
	length 16
	rest
	length 34
	note C#, 2
	length 16
	note C#, 2
	length 48
	rest
	note G#, 1
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 48
	note C#, 2
	length 16
	rest
	length 33
	rest
	note A#, 1
	length 33
	note A#, 1
	length 34
	note A#, 2
	length 33
	note A#, 1
	note C_, 2
	length 34
	note C_, 3
	length 33
	note C_, 2
	note C#, 2
	length 34
	note C#, 3
	length 33
	note C#, 2
	note F_, 2
	length 34
	note F_, 3
	length 33
	note F_, 2
	loop 2
	length 34
	note F#, 2
	length 33
	rest
	length 16
	note C#, 2
	length 48
	rest
	length 34
	note C#, 2
	length 33
	rest
	length 16
	note F#, 2
	length 48
	rest
	length 34
	note F#, 2
	length 33
	rest
	length 16
	note C#, 2
	length 48
	rest
	length 34
	note C#, 2
	note F#, 2
	endloop
	loop 2
	length 34
	note G#, 2
	length 33
	rest
	length 16
	note D#, 2
	length 48
	rest
	length 34
	note D#, 2
	length 33
	rest
	length 16
	note G#, 2
	length 48
	rest
	length 34
	note G#, 2
	length 33
	rest
	length 16
	note D#, 2
	length 48
	rest
	length 34
	note D#, 2
	note G#, 2
	endloop
	loop 2
	length 34
	note F#, 2
	length 33
	rest
	length 16
	note C#, 2
	length 48
	rest
	length 34
	note C#, 2
	length 33
	rest
	length 16
	note F#, 2
	length 48
	rest
	length 34
	note F#, 2
	length 33
	rest
	length 16
	note C#, 2
	length 48
	rest
	length 34
	note C#, 2
	note F#, 2
	endloop
	length 34
	note G#, 2
	length 33
	rest
	length 16
	note D#, 2
	length 48
	rest
	length 34
	note D#, 2
	length 33
	rest
	length 16
	note G#, 2
	length 48
	rest
	length 34
	note G#, 2
	length 33
	rest
	length 16
	note D#, 2
	length 48
	rest
	length 34
	note D#, 2
	note G#, 2
	length 33
	note D#, 2
	rest
	note D#, 2
	rest
	length 16
	note D#, 2
	length 48
	rest
	length 33
	note D#, 2
	rest
	note A#, 1
	rest
	rest
	rest
	note C_, 2
	length 16
	note C_, 2
	length 15
	note B_, 1
	note A#, 1
	note A_, 1
	note G#, 1
	note G_, 1
	note F#, 1
	note F_, 1
	note E_, 1
	note D#, 1
	note D_, 1
	note C#, 1
	note C_, 1
	snd_end
Sound07_M4:
	length 20
	rest
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	length 10
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	length 17
	envelope 6
	attenuate 3
	drum 9
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 0
	drum 14
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	length 10
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	length 17
	envelope 6
	attenuate 3
	drum 9
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 3
	attenuate 4
	drum 1
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	loop 3
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	endloop
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	loop 2
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	endloop
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 33
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	length 35
	rest
	length 33
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	snd_end
Sound08:
	channel 0, Sound08_M1
	channel 1, Sound08_M2
	channel 2, Sound08_M3
	channel 3, Sound08_M4
	end_header
Sound08_M1:
	envelope 13
	duty $80
	attenuate 4
	length 49
	note F_, 1
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note D_, 2
	note E_, 2
	note F_, 2
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note D_, 3
	length 49
	note D_, 3
	note C_, 3
	note B_, 2
	note A_, 2
	note B_, 2
	rest
	note C_, 3
	rest
	note D_, 3
	rest
	note B_, 2
	rest
	rest
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note E_, 3
	length 49
	note E_, 3
	note D_, 3
	note C_, 3
	note B_, 2
	note C_, 3
	rest
	note D_, 3
	rest
	note E_, 3
	rest
	note C_, 3
	rest
	rest
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note D_, 3
	length 49
	note D_, 3
	note C_, 3
	note B_, 2
	note A_, 2
	note B_, 2
	rest
	note C_, 3
	rest
	note D_, 3
	rest
	note B_, 2
	rest
	rest
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note E_, 3
	length 49
	note E_, 3
	note D_, 3
	note C_, 3
	note B_, 2
	note C_, 3
	rest
	note D_, 3
	rest
	note E_, 3
	rest
	note C_, 3
	rest
	rest
	length 49
	note F_, 2
	note F_, 2
	rest
	note G_, 2
	rest
	rest
	rest
	note A_, 2
	rest
	note A_, 2
	rest
	note A_, 2
	note G_, 2
	rest
	note G_, 2
	rest
	note F_, 2
	note F_, 2
	rest
	note G_, 2
	rest
	rest
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	note A_, 2
	rest
	note G_, 2
	rest
	note F_, 2
	note F_, 2
	rest
	note G_, 2
	rest
	rest
	rest
	note A_, 2
	rest
	note A_, 2
	rest
	note A_, 2
	note G_, 2
	rest
	note G_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	rest
	note B_, 2
	note B_, 2
	rest
	note C_, 3
	rest
	rest
	rest
	note C_, 3
	note C_, 3
	snd_end
Sound08_M2:
	envelope 13
	duty $80
	attenuate 7
	length 49
	note D_, 1
	note E_, 1
	note F_, 1
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note D_, 2
	length 50
	rest
	length 49
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note D_, 3
	length 49
	note D_, 3
	note C_, 3
	note B_, 2
	note A_, 2
	note B_, 2
	rest
	note C_, 3
	rest
	note D_, 3
	rest
	note B_, 2
	rest
	rest
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note E_, 3
	length 49
	note E_, 3
	note D_, 3
	note C_, 3
	note B_, 2
	note C_, 3
	rest
	note D_, 3
	rest
	note E_, 3
	rest
	note C_, 3
	rest
	rest
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note D_, 3
	length 49
	note D_, 3
	note C_, 3
	note B_, 2
	note A_, 2
	note B_, 2
	rest
	note C_, 3
	rest
	note D_, 3
	rest
	note B_, 2
	rest
	rest
	loop 3
	note G_, 2
	note F_, 2
	note E_, 2
	note F_, 2
	endloop
	note B_, 2
	note C_, 3
	rest
	note A_, 2
	length 51
	note E_, 3
	length 49
	note E_, 3
	note D_, 3
	note C_, 3
	note B_, 2
	note C_, 3
	rest
	note D_, 3
	rest
	note E_, 3
	rest
	note C_, 3
	attenuate 4
	length 49
	note D_, 2
	note D_, 2
	rest
	note E_, 2
	rest
	rest
	rest
	note F_, 2
	rest
	note F_, 2
	rest
	note F_, 2
	note E_, 2
	rest
	note E_, 2
	rest
	note D_, 2
	note D_, 2
	rest
	note E_, 2
	rest
	rest
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	note F_, 2
	rest
	note E_, 2
	rest
	note D_, 2
	note D_, 2
	rest
	note E_, 2
	rest
	rest
	rest
	note F_, 2
	rest
	note F_, 2
	rest
	note F_, 2
	note E_, 2
	rest
	note E_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	rest
	note G_, 2
	note G_, 2
	rest
	note G_, 2
	rest
	rest
	rest
	note G_, 2
	note G_, 2
	snd_end
Sound08_M3:
	envelope 1
	length 49
	note F_, 1
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note D_, 2
	note E_, 2
	note F_, 2
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	length 51
	note A_, 1
	length 49
	note A_, 1
	note G_, 1
	note F_, 1
	note E_, 1
	note F_, 1
	rest
	note G_, 1
	rest
	note A_, 1
	rest
	note F_, 1
	rest
	rest
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	length 51
	note B_, 1
	length 49
	note B_, 1
	note A_, 1
	note G_, 1
	note F_, 1
	note G_, 1
	rest
	note A_, 1
	rest
	note B_, 1
	rest
	note G_, 1
	rest
	rest
	length 49
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	length 51
	note A_, 1
	length 49
	note A_, 1
	note G_, 1
	note F_, 1
	note E_, 1
	note F_, 1
	rest
	note G_, 1
	rest
	note A_, 1
	rest
	note F_, 1
	rest
	rest
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	length 51
	note B_, 1
	length 49
	note B_, 1
	note A_, 1
	note G_, 1
	note F_, 1
	note G_, 1
	rest
	note A_, 1
	rest
	note B_, 1
	rest
	note G_, 1
	rest
	rest
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	length 50
	note F_, 1
	note F_, 2
	note G_, 1
	note G_, 2
	length 49
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	note C_, 2
	rest
	note E_, 2
	rest
	note G_, 1
	note A_, 1
	note B_, 1
	note C_, 2
	rest
	note C_, 2
	rest
	note C_, 2
	note C_, 2
	rest
	note C_, 2
	rest
	rest
	rest
	note C_, 2
	note C_, 2
	snd_end
Sound08_M4:
	length 49
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	loop 4
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	endloop
	loop 3
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 2
	attenuate 0
	drum 14
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	endloop
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	rest
	rest
	rest
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	snd_end
Sound09:
	channel 1, Sound09_M2
	end_header
Sound09_M2:
	envelope 13
	duty $80
	length 15
	note F_, 4
	snd_end
Sound10:
	channel 1, Sound10_M2
	channel 0, Sound10_M1
	channel 2, Sound10_M3
	channel 3, Sound10_M4
	end_header
Sound10_M2:
	envelope 11
	duty $80
	attenuate 10
	length 50
	rest
	snd_jump Seq_5F8F
Sound10_M1:
	envelope 11
	duty $80
	attenuate 5
Seq_5F8F:
	length 1
	note D#, 2
	note G_, 1
	note A#, 1
	note C_, 2
	note D#, 2
	note G_, 1
	note A#, 1
	note C_, 2
	note D#, 2
	note G_, 1
	note B_, 1
	note D#, 2
	note D#, 2
	note G_, 1
	note B_, 1
	note D#, 2
	note D#, 2
	note G_, 1
	note A#, 1
	note C_, 2
	note D#, 2
	note G_, 1
	note A#, 1
	note C_, 2
	note D#, 2
	note F_, 1
	note A_, 1
	note C_, 2
	note D#, 2
	note F_, 1
	note A_, 1
	note C_, 2
	note D#, 2
	note F_, 1
	note G#, 1
	note C_, 2
	note D#, 2
	note F_, 1
	note G#, 1
	note C_, 2
	note D#, 2
	note G_, 1
	note A#, 1
	note C_, 2
	note D#, 2
	note G_, 1
	note A#, 1
	note C_, 2
	note D#, 2
	note F#, 1
	note A_, 1
	note C_, 2
	note D#, 2
	note F#, 1
	note A_, 1
	note C_, 2
	note D_, 2
	note F_, 1
	note G_, 1
	note B_, 1
	note D_, 2
	note F_, 1
	note G_, 1
	note B_, 1
	snd_jump Seq_5F8F
Sound10_M3:
	envelope 17
	loop 8
	length 0
	note C_, 2
	length 63
	rest
	endloop
	loop 8
	length 0
	note B_, 1
	length 63
	rest
	endloop
	loop 8
	length 0
	note A#, 1
	length 63
	rest
	endloop
	loop 8
	length 0
	note A_, 1
	length 63
	rest
	endloop
	loop 8
	length 0
	note G#, 1
	length 63
	rest
	endloop
	loop 8
	length 0
	note G_, 1
	length 63
	rest
	endloop
	loop 8
	length 0
	note F#, 1
	length 63
	rest
	endloop
	loop 8
	length 0
	note G_, 1
	length 63
	rest
	endloop
	snd_jump Sound10_M3
Sound10_M4:
	length 1
	loop 15
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 8
	drum 2
	endloop
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 6
	attenuate 3
	drum 9
	envelope 5
	attenuate 1
	drum 1
	snd_jump Sound10_M4
Sound11:
	channel 0, Sound11_M1
	channel 1, Sound11_M2
	channel 2, Sound11_M3
	channel 3, Sound11_M4
	end_header
Sound11_M1:
	envelope 13
	duty $40
	attenuate 5
	snd_call Sub_60A2
	snd_call Sub_60A2
	snd_call Sub_60A2
	snd_call Sub_60A2
	length 33
	note F_, 2
	note A_, 2
	note C_, 3
	note F_, 2
	note A_, 2
	note D_, 3
	note F_, 2
	note A_, 2
	note E_, 3
	note F_, 2
	note A_, 2
	note D_, 3
	note F_, 2
	note A_, 2
	note C_, 3
	note A_, 2
	note G_, 2
	note B_, 2
	note D_, 3
	note G_, 2
	note B_, 2
	note E_, 3
	note G_, 2
	note B_, 2
	note F_, 3
	note G_, 2
	note B_, 2
	note E_, 3
	note G_, 2
	note B_, 2
	note D_, 3
	note B_, 2
	note F_, 2
	note A_, 2
	note E_, 3
	note F_, 2
	note A_, 2
	note F_, 3
	note F_, 2
	note A_, 2
	note G_, 3
	note F_, 2
	note A_, 2
	note F_, 3
	note F_, 2
	note A_, 2
	note E_, 3
	note A_, 2
	note G_, 2
	note B_, 2
	note F_, 3
	note G_, 2
	note B_, 2
	note G_, 3
	note G_, 2
	note B_, 2
	note A_, 3
	note B_, 2
	note D_, 3
	note F_, 3
	note B_, 2
	note D_, 3
	length 34
	note G#, 3
	snd_jump Sound11_M1
Sub_60A2:
	length 34
	note C_, 2
	loop 5
	length 0
	note A_, 1
	length 31
	rest
	endloop
	length 35
	note D_, 2
	loop 6
	length 0
	note A_, 1
	length 31
	rest
	endloop
	length 34
	note C_, 2
	loop 5
	length 0
	note A_, 1
	length 31
	rest
	endloop
	length 33
	note G_, 1
	note A_, 1
	note C_, 2
	rest
	note B_, 1
	rest
	length 35
	note G_, 1
	snd_ret
Sound11_M2:
	envelope 13
	duty $40
	attenuate 5
	snd_call Sub_6121
	snd_call Sub_6121
	snd_call Sub_6121
	snd_call Sub_6121
	attenuate 9
	length 10
	rest
	length 33
	note F_, 2
	note A_, 2
	note C_, 3
	note F_, 2
	note A_, 2
	note D_, 3
	note F_, 2
	note A_, 2
	note E_, 3
	note F_, 2
	note A_, 2
	note D_, 3
	note F_, 2
	note A_, 2
	note C_, 3
	note A_, 2
	note G_, 2
	note B_, 2
	note D_, 3
	note G_, 2
	note B_, 2
	note E_, 3
	note G_, 2
	note B_, 2
	note F_, 3
	note G_, 2
	note B_, 2
	note E_, 3
	note G_, 2
	note B_, 2
	note D_, 3
	note B_, 2
	note F_, 2
	note A_, 2
	note E_, 3
	note F_, 2
	note A_, 2
	note F_, 3
	note F_, 2
	note A_, 2
	note G_, 3
	note F_, 2
	note A_, 2
	note F_, 3
	note F_, 2
	note A_, 2
	note E_, 3
	note A_, 2
	note G_, 2
	note B_, 2
	note F_, 3
	note G_, 2
	note B_, 2
	note G_, 3
	note G_, 2
	note B_, 2
	note A_, 3
	note B_, 2
	note D_, 3
	note F_, 3
	note B_, 2
	note D_, 3
	length 63
	note G#, 3
	snd_jump Sound11_M2
Sub_6121:
	length 34
	note G_, 1
	loop 5
	length 33
	rest
	endloop
	length 35
	note A_, 1
	loop 6
	length 33
	rest
	endloop
	length 34
	note G_, 1
	loop 5
	length 33
	rest
	endloop
	length 34
	rest
	attenuate 6
	length 33
	note G_, 1
	note A_, 1
	note C_, 2
	rest
	note B_, 1
	rest
	note G_, 1
	snd_ret
Sound11_M3:
	envelope 1
	snd_call Sub_615A
	snd_call Sub_615A
	snd_call Sub_616B
	snd_call Sub_6173
	snd_call Sub_616B
	snd_call Sub_617B
	snd_jump Sound11_M3
Sub_615A:
	loop 55
	length 0
	note A_, 1
	length 31
	rest
	endloop
	length 33
	note B_, 1
	note C_, 2
	note E_, 2
	rest
	note D_, 2
	rest
	length 35
	note B_, 1
	snd_ret
Sub_616B:
	loop 16
	length 0
	note F_, 1
	length 31
	rest
	endloop
	snd_ret
Sub_6173:
	loop 16
	length 0
	note G_, 1
	length 31
	rest
	endloop
	snd_ret
Sub_617B:
	loop 8
	length 0
	note G_, 1
	length 31
	rest
	endloop
	length 33
	note F_, 3
	note D_, 3
	note B_, 2
	note G#, 2
	note F_, 2
	note D_, 2
	length 34
	note B_, 1
	snd_ret
Sound11_M4:
	length 33
	envelope 2
	attenuate 0
	drum 14
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	rest
	envelope 2
	attenuate 0
	drum 14
	envelope 2
	attenuate 0
	drum 14
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	rest
	rest
	envelope 6
	attenuate 3
	drum 9
	rest
	snd_jump Sound11_M4
Sound12:
	channel 0, Sound12_M1
	channel 1, Sound12_M2
	channel 2, Sound12_M3
	channel 3, Sound12_M4
	end_header
Sound12_M1:
	envelope 11
	duty $80
	attenuate 5
	length 1
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	note A_, 2
	note E_, 2
	note D_, 2
	note E_, 2
	length 6
	note B_, 2
	note A_, 2
	length 1
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	note A_, 2
	note E_, 2
	note D_, 2
	note E_, 2
	length 6
	note D_, 3
	note D#, 3
	envelope 13
	loop 4
	length 49
	note D_, 2
	note G_, 2
	note B_, 2
	note D_, 3
	note B_, 2
	note G_, 2
	endloop
	loop 4
	length 49
	note C_, 2
	note F_, 2
	note A_, 2
	note D_, 3
	note A_, 2
	note F_, 2
	endloop
	length 8
	note E_, 3
	snd_end
Sound12_M2:
	envelope 11
	duty $80
	attenuate 8
	length 2
	rest
	length 1
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	note A_, 2
	note E_, 2
	attenuate 5
	length 6
	note G_, 2
	note F#, 2
	attenuate 8
	length 2
	rest
	length 1
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	rest
	rest
	note B_, 2
	note F#, 2
	note C#, 2
	note F#, 2
	note A_, 2
	note E_, 2
	attenuate 5
	length 6
	note A_, 2
	note A#, 2
	envelope 13
	attenuate 8
	length 49
	rest
	loop 4
	length 49
	note D_, 2
	note G_, 2
	note B_, 2
	note D_, 3
	note B_, 2
	note G_, 2
	endloop
	loop 3
	length 49
	note C_, 2
	note F_, 2
	note A_, 2
	note D_, 3
	note A_, 2
	note F_, 2
	endloop
	length 49
	note C_, 2
	note F_, 2
	note A_, 2
	note D_, 3
	note A_, 2
	length 8
	note C_, 3
	snd_end
Sound12_M3:
	envelope 1
	length 1
	note B_, 1
	rest
	length 6
	note B_, 1
	length 2
	rest
	length 1
	note B_, 1
	note E_, 2
	length 2
	note F#, 2
	length 6
	note A_, 2
	note E_, 2
	length 1
	note B_, 1
	rest
	length 6
	note B_, 1
	length 2
	rest
	length 1
	note B_, 1
	note E_, 2
	length 2
	note F#, 2
	length 6
	note B_, 2
	note G#, 2
	length 8
	note G_, 1
	note F_, 1
	note C_, 2
	length 6
	note C_, 2
	snd_end
Sound12_M4:
	length 1
	loop 7
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	endloop
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 5
	attenuate 1
	drum 1
	loop 7
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	envelope 2
	attenuate 8
	drum 2
	endloop
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	length 34
	envelope 5
	attenuate 1
	drum 1
	length 8
	rest
	rest
	envelope 9
	attenuate 4
	drum 3
	snd_end
Sound13:
	channel 0, Sound13_M1
	channel 1, Sound13_M2
	channel 2, Sound13_M3
	channel 3, Sound13_M4
	end_header
Sound13_M1:
	envelope 11
	duty $80
	attenuate 5
	length 17
	note B_, 2
	note D_, 3
	note F#, 3
	note A_, 3
	note F#, 3
	note D_, 3
	note A_, 2
	note C#, 3
	note E_, 3
	note G#, 3
	note E_, 3
	note C#, 3
	note G#, 2
	note C_, 3
	note D#, 3
	note G_, 3
	note D#, 3
	note C_, 3
	note G_, 2
	note B_, 2
	note D_, 3
	note F#, 3
	attenuate 8
	note G_, 2
	note B_, 2
	note D_, 3
	note F#, 3
	attenuate 11
	note G_, 2
	note B_, 2
	note D_, 3
	note F#, 3
	snd_end
Sound13_M2:
	envelope 11
	duty $80
	attenuate 9
	length 50
	rest
	length 17
	note B_, 2
	note D_, 3
	note F#, 3
	note A_, 3
	note F#, 3
	note D_, 3
	note A_, 2
	note C#, 3
	note E_, 3
	note G#, 3
	note E_, 3
	note C#, 3
	note G#, 2
	note C_, 3
	note D#, 3
	note G_, 3
	note D#, 3
	note C_, 3
	note G_, 2
	note B_, 2
	note D_, 3
	note F#, 3
	attenuate 12
	note G_, 2
	note B_, 2
	note D_, 3
	note F#, 3
	attenuate 14
	note G_, 2
	note B_, 2
	note D_, 3
	note F#, 3
	snd_end
Sound13_M3:
	envelope 1
	length 17
	note G_, 2
	note G_, 2
	rest
	note G_, 2
	rest
	rest
	note F#, 2
	note F#, 2
	rest
	note F#, 2
	rest
	rest
	note F_, 2
	note F_, 2
	rest
	note F_, 2
	rest
	rest
	length 23
	note E_, 2
	snd_end
Sound13_M4:
	length 17
	loop 3
	envelope 3
	attenuate 4
	drum 1
	envelope 2
	attenuate 8
	drum 2
	envelope 3
	attenuate 4
	drum 1
	length 18
	envelope 5
	attenuate 1
	drum 1
	length 17
	envelope 2
	attenuate 8
	drum 2
	endloop
	length 23
	envelope 9
	attenuate 4
	drum 3
	snd_end
Sound14:
	channel 4, Sound14_S1
	channel 5, Sound14_S2
	end_header
Sound14_S1:
	length 15
	rest
Sound14_S2:
	envelope 11
	duty $80
	attenuate 0
	length 31
	note C_, 4
	snd_end
Sound15:
	channel 4, Sound15_S1
	channel 5, Sound15_S2
	end_header
Sound15_S1:
	length 15
	rest
Sound15_S2:
	envelope 11
	duty $80
	attenuate 0
	length 31
	note G_, 3
	note C_, 4
	note F_, 4
	snd_end
Sound16:
	channel 4, Sound16_S1
	channel 5, Sound16_S2
	end_header
Sound16_S1:
	envelope 0
	duty $40
	length 48
	note G_, 2
	note G#, 2
	snd_jump Sound16_S1
Sound16_S2:
	envelope 0
	duty $40
	length 48
	note A_, 2
	note A#, 2
	snd_jump Sound16_S2
Sound17:
	channel 6, Sound17_S3
	channel 7, Sound17_S4
	end_header
Sound17_S3:
	envelope 1
	length 48
	note F_, 2
	note F#, 2
	snd_jump Sound17_S3
Sound17_S4:
	envelope 0
	attenuate 9
	length 48
	drum 5
	drum 6
	snd_jump Sound17_S4
Sound18:
	channel 6, Sound18_S3
	channel 7, Sound18_S4
	end_header
Sound18_S3:
	envelope 1
	length 15
	note F_, 2
	note F#, 2
	note G_, 2
	note G#, 2
	note A_, 2
	note A#, 2
	note B_, 2
	note C_, 3
	snd_end
Sound18_S4:
	envelope 0
	attenuate 9
	length 15
	drum 10
	drum 9
	drum 8
	drum 7
	drum 6
	drum 5
	drum 4
	drum 3
	snd_end
Sound19:
	channel 6, Sound19_S3
	channel 7, Sound19_S4
	end_header
Sound19_S3:
	envelope 1
	length 15
	note C_, 3
	note B_, 2
	note A#, 2
	note A_, 2
	note G#, 2
	note G_, 2
	note F#, 2
	note F_, 2
	snd_end
Sound19_S4:
	envelope 0
	attenuate 9
	length 15
	drum 1
	drum 2
	drum 3
	drum 4
	drum 5
	drum 6
	drum 7
	drum 8
	snd_end
Sound20:
	channel 7, Sound20_S4
	end_header
Sound20_S4:
	envelope 0
	attenuate 4
	length 31
	drum 12
	drum 11
	drum 10
	drum 9
	drum 8
	drum 7
	drum 6
	drum 5
	drum 4
	drum 3
	drum 2
	drum 1
	drum 0
	snd_end
Sound21:
	channel 4, Sound21_S1
	channel 5, Sound21_S2
	end_header
Sound21_S1:
	envelope 0
	duty $80
Seq_6455:
	length 47
	note B_, 1
	note D#, 2
	note F#, 2
	note A#, 2
	note F_, 3
	note G#, 3
	snd_end
Sound21_S2:
	envelope 0
	duty $80
	attenuate 5
	length 49
	rest
	snd_jump Seq_6455
Sound22:
	channel 4, Sound22_S1
	channel 5, Sound22_S2
	channel 6, Sound22_S3
	end_header
Sound22_S1:
	envelope 11
	duty $80
	attenuate 9
	transpose 3
	length 63
	rest
	snd_call Sub_649C
	attenuate 8
	snd_call Sub_64A6
	attenuate 11
	snd_call Sub_64A6
	snd_end
Sound22_S2:
	envelope 11
	duty $80
	snd_call Sub_649C
	attenuate 5
	snd_call Sub_64A6
	attenuate 8
	snd_call Sub_64A6
	snd_end
Sub_649C:
	length 15
	note F_, 0
	note F#, 0
	note G_, 0
	note G#, 0
	note A_, 0
	note A#, 0
	note B_, 0
	note C_, 1
	snd_ret
Sub_64A6:
	length 15
	note C_, 1
	note C#, 1
	note D_, 1
	note D#, 1
	note E_, 1
	note F_, 1
	note F#, 1
	note G_, 1
	snd_ret
Sound22_S3:
	envelope 1
	length 47
	note C_, 1
	note E_, 1
	note F_, 1
	note C_, 2
	note G_, 2
	snd_end
	envelope 11  ; unreferenced stream
	attenuate 2
	length 17
	note D_, 0
	length 31
	note F_, 0
	note A_, 0
	db $0D ; note 0+13
	snd_end
Sound23:
	channel 4, Sound23_S1
	channel 5, Sound23_S2
	end_header
Sound23_S1:
	envelope 11
	duty $80
	attenuate 7
	length 63
	rest
	snd_call Sub_64FF
	attenuate 9
	snd_call Sub_6511
	attenuate 11
	snd_call Sub_6523
	attenuate 13
	snd_call Sub_6535
	snd_end
Sound23_S2:
	envelope 11
	duty $80
	attenuate 3
	snd_call Sub_64FF
	attenuate 5
	snd_call Sub_6511
	attenuate 7
	snd_call Sub_6523
	attenuate 9
	snd_call Sub_6535
	snd_end
Sub_64FF:
	length 15
	note C_, 1
	note C#, 1
	note D_, 1
	note D#, 1
	note E_, 1
	note F_, 1
	note F#, 1
	note G_, 1
	note G#, 1
	note A_, 1
	note A#, 1
	note B_, 1
	note C_, 2
	note C#, 2
	note D_, 2
	note D#, 2
	snd_ret
Sub_6511:
	length 15
	note D#, 1
	note E_, 1
	note F_, 1
	note F#, 1
	note G_, 1
	note G#, 1
	note A_, 1
	note A#, 1
	note B_, 1
	note C_, 2
	note C#, 2
	note D_, 2
	note D#, 2
	note E_, 2
	note F_, 2
	note F#, 2
	snd_ret
Sub_6523:
	length 15
	note F#, 1
	note G_, 1
	note G#, 1
	note A_, 1
	note A#, 1
	note B_, 1
	note C_, 2
	note C#, 2
	note D_, 2
	note D#, 2
	note E_, 2
	note F_, 2
	note F#, 2
	note G_, 2
	note G#, 2
	note A_, 2
	snd_ret
Sub_6535:
	length 15
	note A_, 1
	note A#, 1
	note B_, 1
	note C_, 2
	note C#, 2
	note D_, 2
	note D#, 2
	note E_, 2
	note F_, 2
	note F#, 2
	note G_, 2
	note G#, 2
	note A_, 2
	note A#, 2
	note B_, 2
	note C_, 3
	snd_ret
Sound24:
	channel 4, Sound24_S1
	channel 5, Sound24_S2
	end_header
Sound24_S1:
	length 47
	rest
Sound24_S2:
	envelope 13
	duty $80
	length 15
	note C_, 2
	note F#, 2
	note B_, 2
	note D#, 3
	note A_, 3
	note C#, 4
	length 51
	note F#, 4
	snd_end
Sound25:
	channel 6, Sound25_S3
	end_header
Sound25_S3:
	envelope 1
	length 15
	note E_, 3
	note A#, 2
	note B_, 2
	note C_, 3
	note C#, 3
	note D_, 3
	note D#, 3
	note E_, 3
	note F_, 3
	note F#, 3
	note G_, 3
	note G#, 3
	note A_, 3
	snd_end
Sound26:
	channel 4, Sound26_S1
	channel 5, Sound26_S2
	channel 6, Sound26_S3
	channel 7, Sound26_S4
	end_header
Sound26_S1:
	envelope 11
	duty $80
	length 15
	rest
	note C_, 1
	attenuate 6
	sweep $C3
	length 50
	note C_, 2
	sweep_off
	snd_end
Sound26_S2:
	envelope 11
	duty $80
	length 15
	note C_, 1
	attenuate 6
	length 15
	note C_, 1
	note D_, 1
	note D_, 1
	note D#, 1
	note E_, 1
	note F_, 1
	note F#, 1
	note G_, 1
	note G#, 1
	note A_, 1
	note A#, 1
	note B_, 1
	note C_, 2
	note C#, 2
	note D_, 2
	note D#, 2
	snd_end
Sound26_S3:
	envelope 1
	length 48
	note G_, 1
	snd_end
Sound26_S4:
	envelope 18
	length 48
	drum 10
	attenuate 6
	length 52
	drum 9
	snd_end
Sound27:
	channel 4, Sound27_S1
	end_header
Sound27_S1:
	envelope 2
	duty $80
	sweep $C2
	length 49
	note C_, 1
	sweep_off
	envelope 13
	transpose -5
	snd_call Sub_64A6
	snd_end
Sound28:
	channel 5, Sound28_S2
	channel 7, Sound28_S4
	end_header
Sound28_S2:
	envelope 0
	duty $80
	attenuate 0
	loop 31
	length 15
	note F#, 5
	note G_, 5
	endloop
	attenuate 4
	note F#, 5
	note G_, 5
	attenuate 6
	note F#, 5
	note G_, 5
	attenuate 8
	note F#, 5
	note G_, 5
	attenuate 10
	note F#, 5
	note G_, 5
	attenuate 11
	note F#, 5
	snd_end
Sound28_S4:
	envelope 0
	attenuate 12
	length 10
	drum 0
	length 11
	drum 0
	snd_end
Sound29:
	channel 4, Sound29_S1
	channel 5, Sound29_S2
	channel 6, Sound29_S3
	channel 7, Sound29_S4
	end_header
Sound29_S1:
	envelope 13
	duty $80
	attenuate 5
	length 1
	note A_, 1
	note D_, 2
	note F#, 2
	length 2
	note G_, 2
	length 1
	note F#, 2
	note D_, 2
	length 29
	note C_, 3
	length 1
	note D_, 3
	note E_, 3
	note E_, 3
	snd_end
Sound29_S2:
	envelope 13
	duty $80
	attenuate 8
	length 1
	rest
	length 1
	note A_, 1
	note D_, 2
	note F#, 2
	length 2
	note G_, 2
	length 1
	note F#, 2
	attenuate 5
	length 29
	note G_, 2
	length 1
	note B_, 2
	note C#, 2
	note C#, 2
	snd_end
Sound29_S3:
	envelope 1
	length 3
	note E_, 2
	length 4
	note G_, 1
	length 29
	note F_, 1
	length 1
	note A_, 1
	note B_, 1
	note B_, 1
	snd_end
Sound29_S4:
	length 1
	envelope 5
	attenuate 1
	drum 1
	envelope 7
	attenuate 11
	drum 8
	envelope 7
	attenuate 11
	drum 8
	envelope 5
	attenuate 1
	drum 1
	envelope 7
	attenuate 11
	drum 8
	envelope 6
	attenuate 3
	drum 9
	envelope 2
	attenuate 0
	drum 14
	length 29
	envelope 9
	attenuate 4
	drum 3
	length 1
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	envelope 6
	attenuate 3
	drum 9
	snd_end
Sound30:
	channel 4, Sound30_S1
	channel 5, Sound30_S2
	channel 7, Sound30_S4
	end_header
Sound30_S1:
	envelope 2
	duty $80
	attenuate 2
	transpose 12
	snd_call Sub_649C
	attenuate 4
	snd_call Sub_64A6
	attenuate 6
	snd_call Sub_64A6
	attenuate 8
	snd_call Sub_649C
	attenuate 10
	snd_call Sub_649C
	snd_end
Sound30_S2:
	envelope 11
	duty $80
	attenuate 3
	length 17
	note C_, 0
	length 31
	note D_, 0
	note E_, 0
	note F#, 0
	note G#, 0
	note A#, 0
	db $0C ; note 0+12
	snd_end
Sound30_S4:
	envelope 11
	attenuate 3
	length 47
	drum 0
	drum 2
	drum 4
	drum 6
	snd_end
Sound31:
	channel 5, Sound31_S2
	channel 7, Sound31_S4
	end_header
Sound31_S2:
	envelope 11
	duty $80
	attenuate 3
	length 15
	note G_, 0
	note D#, 0
	note F#, 0
	note D_, 0
	note G#, 0
	note D_, 1
	note F#, 0
	note A_, 0
	snd_end
Sound31_S4:
	envelope 14
	attenuate 3
	length 15
	drum 13
	drum 10
	drum 15
	drum 11
	drum 12
	drum 14
	drum 12
	drum 10
	snd_end
Sound32:
	channel 5, Sound32_S2
	channel 7, Sound32_S4
	end_header
Sound32_S2:
	envelope 2
	length 63
	note G_, 0
	snd_end
Sound32_S4:
	envelope 11
	length 49
	drum 13
	length 53
	drum 14
	snd_end
Sound33:
	channel 7, Sound33_S4
	end_header
Sound33_S4:
	envelope 16
	length 1
	drum 9
	drum 10
	drum 11
	envelope 17
	length 40
	drum 12
	snd_end
Sound34:
	channel 6, Sound34_S3
	channel 7, Sound34_S4
	end_header
Sound34_S3:
	envelope 1
	transpose 21
	length 31
	note F_, 0
	note D#, 0
	note G_, 0
	note F#, 0
	note G#, 0
	note E_, 0
	note G_, 0
	note F#, 0
	note F_, 0
	note A_, 0
	note C_, 1
	note D_, 1
	note F_, 1
	note G_, 0
	note F_, 0
	note E_, 0
	note G#, 0
	note D#, 0
	note F#, 0
	note E_, 0
	note A_, 0
	note C_, 1
	note E_, 0
	note F#, 0
	note G_, 0
	note E_, 0
	note F#, 0
	note E_, 0
	note F#, 0
	note G_, 0
	note F#, 0
	note F_, 0
	note E_, 0
	note A_, 0
	note G#, 0
	note D#, 0
	snd_end
Sound34_S4:
	envelope 16
	length 1
	drum 7
	drum 8
	drum 9
	drum 10
	drum 11
	envelope 17
	length 57
	drum 12
	snd_end
Sound35:
	channel 4, Sound35_S1
	channel 5, Sound35_S2
	channel 6, Sound35_S3
	channel 7, Sound35_S4
	end_header
Sound35_S1:
	envelope 0
	duty $80
	transpose 5
	length 47
	note F_, 0
	note D#, 0
	note F#, 0
	note E_, 0
	note G#, 0
	note C#, 0
	note D#, 0
	note F#, 0
	note G_, 0
	note D#, 0
	note E_, 0
	note C_, 1
	note D_, 1
	note B_, 0
	note G_, 0
	note D#, 0
	note C_, 0
	note E_, 0
	note G_, 0
	note F_, 0
	note D#, 0
	note G_, 0
	note F#, 0
	note G#, 0
	note E_, 0
	note C#, 0
	note D#, 0
	note F_, 0
	note F#, 0
	note F_, 0
	note D_, 0
	note F#, 0
	note G_, 0
	note F_, 0
	note F#, 0
	attenuate 4
	note C_, 1
	note F_, 1
	note G#, 1
	note D#, 0
	note F#, 0
	note G_, 0
	note F_, 0
	note F#, 0
	note A_, 0
	attenuate 6
	note D#, 0
	note F#, 0
	note G#, 0
	note A_, 0
	note E_, 0
	note F_, 0
	note D_, 0
	note C#, 0
	note F#, 0
	attenuate 8
	note F#, 0
	note G#, 0
	note A_, 0
	note F_, 0
	note E_, 0
	note D#, 0
	note D_, 0
	note F_, 0
	note G_, 0
	attenuate 10
	note G#, 0
	note A_, 0
	note G_, 0
	note F#, 0
	note F_, 0
	attenuate 12
	note D#, 0
	note E_, 0
	note F_, 0
	note D#, 0
	note F_, 0
	snd_end
Sound35_S2:
	envelope 0
	duty $80
	transpose 5
	length 63
	note F#, 0
	note F_, 0
	note F#, 0
	note E_, 0
	note G#, 0
	note A_, 0
	note C#, 0
	note D_, 0
	note F_, 0
	attenuate 4
	note D#, 0
	note F_, 0
	note F#, 0
	note F_, 0
	note D_, 0
	note F#, 0
	note G_, 0
	note F_, 0
	note F#, 0
	attenuate 6
	note C_, 1
	note F_, 1
	note G#, 1
	note D#, 0
	note F#, 0
	note G_, 0
	note F_, 0
	note F#, 0
	note A_, 0
	attenuate 8
	note D#, 0
	note F#, 0
	note G#, 0
	note A_, 0
	note E_, 0
	note F_, 0
	note D_, 0
	note C#, 0
	note F#, 0
	attenuate 10
	note F_, 0
	note G#, 0
	note G_, 0
	note A_, 0
	note F#, 0
	note F_, 0
	note D#, 0
	note C#, 0
	note F_, 0
	attenuate 12
	note A_, 0
	note E_, 0
	note F#, 0
	note G_, 0
	note G#, 0
	attenuate 13
	note F#, 0
	note D#, 0
	note F_, 0
	note F#, 0
	snd_end
Sound35_S3:
	envelope 1
	transpose 21
	length 31
	note F_, 0
	note D#, 0
	note G_, 0
	note F#, 0
	note G#, 0
	note E_, 0
	note G_, 0
	note F#, 0
	note F_, 0
	note A_, 0
	note C_, 1
	note D_, 1
	note F_, 1
	note G_, 0
	note F_, 0
	note E_, 0
	note G#, 0
	note D#, 0
	note F#, 0
	note E_, 0
	note A_, 0
	note C_, 1
	note E_, 0
	note F#, 0
	note G_, 0
	note E_, 0
	note F#, 0
	note E_, 0
	note F#, 0
	note G_, 0
	note F#, 0
	note F_, 0
	note E_, 0
	note A_, 0
	note G#, 0
	note D#, 0
	note C_, 1
	note F_, 1
	note G#, 1
	note D#, 0
	note F#, 0
	note G_, 0
	note F_, 0
	note F#, 0
	note A_, 0
	note D#, 0
	note F#, 0
	note G#, 0
	note A_, 0
	note E_, 0
	note F_, 0
	note D_, 0
	note C#, 0
	note F#, 0
	snd_end
Sound35_S4:
	envelope 16
	length 1
	drum 5
	drum 6
	drum 7
	drum 8
	drum 9
	drum 10
	drum 11
	envelope 17
	length 58
	drum 12
	snd_end
Sound36:
	channel 4, Sound36_S1
	channel 5, Sound36_S2
	channel 6, Sound36_S3
	channel 7, Sound36_S4
	end_header
Sound36_S1:
	transpose 1
Sound36_S2:
	envelope 13
	duty $80
	attenuate 8
	length 33
	note A_, 3
	rest
	length 36
	note A_, 3
	snd_end
Sound36_S3:
	envelope 1
	length 33
	note F_, 3
	rest
	length 36
	note F_, 3
	snd_end
Sound36_S4:
	envelope 13
	envelope 9
	length 33
	drum 0
	rest
	length 36
	drum 0
	snd_end
Sound37:
	channel 6, Sound37_S3
	end_header
Sound37_S3:
	envelope 1
	length 31
	note B_, 1
	note C_, 2
	note C#, 2
	note D_, 2
	note D#, 2
	length 10
	rest
	length 31
	note F#, 1
	note G_, 1
	note G#, 1
	note A_, 1
	note A#, 1
	length 10
	rest
	length 31
	note F_, 1
	note F#, 1
	note G_, 1
	note G#, 1
	note A_, 1
	length 10
	rest
	length 31
	note E_, 1
	note F_, 1
	note F#, 1
	note G_, 1
	note G#, 1
	length 10
	rest
	length 31
	note D#, 1
	note E_, 1
	note F_, 1
	note F#, 1
	note G_, 1
	length 10
	rest
	length 31
	note D_, 1
	note D#, 1
	note E_, 1
	note F_, 1
	note F#, 1
	length 10
	rest
	snd_end
Sound38:
	channel 4, Sound38_S1
	channel 5, Sound38_S2
	channel 6, Sound38_S3
	channel 7, Sound38_S3
	end_header
Sound38_S1:
	length 31
	rest
Sound38_S2:
	envelope 0
	duty $80
	attenuate 4
	length 47
	note C_, 4
	note F#, 3
	note C#, 3
	note G_, 2
	note F_, 2
	note C#, 2
	snd_jump Sound38_S3
Sound38_S3:
	length 15
	rest
	snd_jump Sound38_S3
Sound39:
	channel 4, Sound39_S1
	channel 5, Sound39_S1
	channel 6, Sound39_S1
	channel 7, Sound39_S1
	end_header
Sound39_S1:
	snd_end
Sound40:
	channel 4, Sound40_S1
	channel 5, Sound40_S2
	channel 6, Sound40_S3
	channel 7, Sound40_S4
	end_header
Sound40_S1:
	envelope 11
	duty $40
	transpose 1
	length 15
	note D#, 4
	note D#, 3
	note A#, 3
	note C_, 3
	note C#, 4
	note G#, 4
	note G_, 2
	length 31
	note B_, 5
	note G_, 5
	note E_, 5
	note C_, 5
	note A_, 4
	note F_, 4
	note D_, 4
	note B_, 3
	note G_, 3
	note E_, 3
	note C_, 3
	note A_, 2
	note F_, 2
	note D_, 2
	note B_, 1
	note G_, 1
	note E_, 1
	note C_, 1
	length 0
	rest
	rest
	attenuate 5
	sweep $F7
	length 27
	note C_, 2
	note G_, 1
	note D#, 1
	note C_, 1
	sweep_off
	snd_end
Sound40_S2:
	envelope 11
	duty $40
	length 15
	note D#, 4
	note D#, 3
	note A#, 3
	note C_, 3
	note C#, 4
	note G#, 4
	note G_, 2
	length 31
	note B_, 5
	note G_, 5
	note E_, 5
	note C_, 5
	note A_, 4
	note F_, 4
	note D_, 4
	note B_, 3
	note G_, 3
	note E_, 3
	note C_, 3
	note A_, 2
	note F_, 2
	note D_, 2
	note B_, 1
	note G_, 1
	note E_, 1
	note C_, 1
	length 0
	rest
	rest
	length 27
	rest
	rest
	rest
	rest
	snd_end
Sound40_S3:
	envelope 1
	length 15
	note G_, 1
	note A_, 1
	note C_, 2
	note F#, 1
	note B_, 1
	note G#, 1
	note G_, 1
	length 37
	rest
	length 16
	rest
	length 27
	rest
	rest
	rest
	rest
	snd_end
Sound40_S4:
	envelope 6
	length 37
	drum 0
	length 15
	rest
	length 0
	drum 11
	rest
	length 27
	rest
	rest
	rest
	rest
	snd_end
Sound41:
	channel 7, Sound41_S4
	end_header
Sound41_S4:
	envelope 0
	length 31
	drum 2
	drum 5
	drum 8
	drum 11
	drum 14
	snd_end
Sound42:
	channel 0, Sound42_M1
	channel 1, Sound42_M2
	channel 2, Sound42_M3
	channel 3, Sound42_M4
	end_header
Sound42_M1:
	length 30
	rest
	snd_jump Sound01_M1
Sound42_M2:
	length 30
	rest
	snd_jump Sound01_M2
Sound42_M3:
	envelope 1
	loop 11
	length 15
	note G#, 1
	length 46
	rest
	endloop
	length 38
	rest
	snd_jump Seq_4A34
Sound42_M4:
	envelope 2
	attenuate 10
	length 15
	drum 7
	length 46
	rest
	attenuate 9
	length 15
	drum 7
	length 46
	rest
	attenuate 8
	length 15
	drum 7
	length 46
	rest
	attenuate 7
	length 15
	drum 7
	length 46
	rest
	attenuate 6
	length 15
	drum 7
	length 46
	rest
	attenuate 5
	length 15
	drum 7
	length 46
	rest
	attenuate 4
	length 15
	drum 7
	length 46
	rest
	attenuate 3
	length 15
	drum 7
	length 46
	rest
	attenuate 2
	length 15
	drum 7
	length 46
	rest
	attenuate 1
	length 15
	drum 7
	length 46
	rest
	attenuate 0
	length 15
	drum 7
	length 46
	rest
	snd_jump Seq_4A90
Sound43:
	channel 4, Sound43_S1
	channel 5, Sound43_S1
	end_header
Sound43_S1:
	snd_end
Sound44:
	channel 6, Sound44_S3
	channel 7, Sound44_S3
	end_header
Sound44_S3:
	snd_end
