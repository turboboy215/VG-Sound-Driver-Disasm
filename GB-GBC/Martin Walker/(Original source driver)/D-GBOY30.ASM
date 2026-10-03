;-------------------------------------------------------------------------------
;GAMEBOY MUSIC DRIVER - (c) Martin Walker 1992/1993/1994
;-------------------------------------------------------------------------------

;example to produce a final customer driver file
;DEMO		equ	0	;0=driver only/ 1=demo & driver
;MUSICROM	equ	04000h	;Music Driver start address
;MUSICRAM	equ	0C500h	;Ram variables start address

;default settings to use with the music editor
DEMO		equ	1	;0=driver only/ 1=demo & driver
MUSICROM	equ	00490h	;Driver start address
MUSICRAM	equ	0DE00h	;Ram variables start address




;CURRENT STATISTICS
;CODESIZE (ROM) = 3214 bytes (3.14 Kbytes)
;VARSIZE  (RAM) = 226 bytes
;Typical compressed music file 2-4 Kbytes


HOLDTIME	equ 200		;number of frames to hold effect


;VERSION DETAILS
;3.0 - Tiny format adopted/drumbend special added/ Get_info added
;      tempo default to 0FFh
;2.3 - General routines added/GLBoffset added/effect VOLUME defaults to max
;      CLOCK added/fixed voice special added
;2.2 - Spidersoft Bugs in EYSY_OS2.ASM and D_GBOY.ASM implemented
;2.1 - arpeggio voice special/ voices to 64/ complex lo effect special
;2.0 - new format music file/fxtable/Swap nibbles effect special
;1.4 - stereo effects/stereo noise
;1.3 - new notetable/stereo music/tied note added/gate added
;1.2 - variable pulse width in all 3 channels
;1.1 - effects to 64/ voices to 32
;1.0 - new format notes with extended parameters/default tempo = 125bpm
;0.9 - new format musicfiles
;0.8 - new tempo routines




;GAMEBOY REGISTER EQUATES

P1	equ 0FF00h
SB	equ 0FF01h
SC	equ 0FF02h
DIV	equ 0FF04h
TIMA	equ 0FF05h
TMA	equ 0FF06h
TAC	equ 0FF07h
IF	equ 0FF0Fh
IE	equ 0FFFFh
LCDC	equ 0FF40h
STAT	equ 0FF41h
SCY	equ 0FF42h
SCX	equ 0FF43h
LY	equ 0FF44h
LYC	equ 0FF45h
DMA	equ 0FF46h
BGP	equ 0FF47h
OBP0	equ 0FF48h
OBP1	equ 0FF49h
WY	equ 0FF4Ah
WX	equ 0FF4Bh

NR10	equ 0FF10h
NR11	equ 0FF11h
NR12	equ 0FF12h
NR13	equ 0FF13h
NR14	equ 0FF14h

NR21	equ 0FF16h
NR22	equ 0FF17h
NR23	equ 0FF18h
NR24	equ 0FF19h

NR30	equ 0FF1Ah
NR31	equ 0FF1Bh
NR32	equ 0FF1Ch
NR33	equ 0FF1Dh
NR34	equ 0FF1Eh

NR41	equ 0FF20h
NR42	equ 0FF21h
NR43	equ 0FF22h
NR44	equ 0FF23h

NR50	equ 0FF24h
NR51	equ 0FF25h
NR52	equ 0FF26h

WAVE	equ 0FF30h


COMAD	equ 0118H	;The address of the comms interface
HDLEN	equ 16	;Header buffer length (don't change)
RESTART	equ 0101H	;Main program start address

;-----------------------------------------------------------------------------
	IF DEMO
	ORG 0000H

	DB 0FFH DUP 040H

	ORG 0040H	;V_BLANK INT
	JP V_BLANK

	ORG 0048H	;LCDC STATUS INTERRUPT
	RETI

V_BLANK:	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL
	LDS A,(SCX)
	INC A
	LDS (SCX),A	;SCROLL SCREEN LEFT
	CALL JUMPTABLE+3	;SOUND INTERRUPT ROUTINE
	CALL Get_Info
	LD A,1
	LD (vbi_flag),A	;VBLANK INTERRUPT END FLAG
	POP HL
	POP DE
	POP BC
	POP AF
	RETI


	ORG 0100H
	NOP
	JP START	;USER START ADDRESS

	DB 0CEH,0EDH,066H,066H	;NINTENDO DATA
	DB 0CCH,00DH,000H,00BH
	DB 003H,073H,000H,083H
	DB 000H,00CH,000H,00DH
	DB 000H,008H,011H,01FH
	DB 088H,089H,000H,00EH
	DB 0DCH,0CCH,06EH,0E6H
	DB 0DDH,0DDH,0D9H,099H
	DB 0BBH,0BBH,067H,063H
	DB 06EH,00EH,0ECH,0CCH
	DB 0DDH,0DCH,099H,09FH
	DB 0BBH,0B9H,033H,03EH

;-----------------------------------------------------------------------------
	DB 'WALKER MUSIC DRV'	;GAME TITLE
	DB 0,0,0	;NOT USED
	DB 1	;CARTIDGE TYPE = ROM+MMC
	DB 2	;ROM SIZE = 1M
	DB 0	;RAM SIZE = NO
	DB 0,0	;MAKER CODE
	DB 1	;VERSION NO
	DB 070H	;COMPLEMENT CHECK
	DB 0,0	;CHECK SUM


;-----------------------------------------------------------------------------
;Start of Debugger routines
;-----------------------------------------------------------------------------
DEBUG:	PUSH BC	;Enter debugger
	LD BC,04170H
	JR ASM10
COMMS:	PUSH BC	;Enter debugger if host waiting to transfer
	LD BC,0C0F0H
ASM10:	PUSH AF
	LD A,(COMAD)	;'Read' port of comms link
	XOR B ;Bits 4-6 are used to determine if the comms is enabled
	AND C ;Bit 7 set indicates that the host is waiting to transfer
	JR NZ,ASM20	;Skip debugger
	;CHANGE BANK	;The debugger may be in a different rom bank
	CALL COMRT	;Enter debugger
	;RESTORE BANK
ASM20:	POP AF
	POP BC
	RET	;Return to main program
	;All regs preserved unless changed by host command


;-------------------------------------------------------------------------------
;This is the debugger.
;If a new bank was paged in, the previous value should be in the A
;reg. This can be read by the 'transfer registers' command.
;The B reg holds the breakpoint type (041H for DEBUG 0C0H for COMMS).
;-------------------------------------------------------------------------------
COMRT:	PUSH DE
	PUSH HL
	LD HL,12
	ADD HL,SP
	PUSH HL	;Stack value
	LD C,A
	PUSH BC	;Bank and type
	LD HL,-HDLEN
	ADD HL,SP
	LD SP,HL	;Buffer for header
COM20:	LD A,(COMAD)
	AND 0F0H
	CP 040H
	JR Z,COM20	;Wait for host (for DEBUG entry)
	LD A,(COMAD+6)	;Reset port
	LD A,(COMAD+4)
COM30:	LD A,(COMAD+3)
COM40:	CALL COMRX	;Read first byte of header
	JR C,COM70	;Enter ram or exit
	AND A
	JR Z,COM80	;This command not used
	LD HL,0
	ADD HL,SP
	CALL COMCMD	;Execute command
	JR NC,COM30	;If no error loop back for next command
	LD A,(COMAD+2)	;Signal error to host
	LD A,(COMAD+4)
	LD A,(COMAD+7)
COM60:	LD A,(COMAD)	;Wait for host to disable comms with COMOFF
	AND 0F0H
	CP 0C0H
	JR Z,COM60
	JR COM90	;Exit
COM70:	JR NZ,COM80	;Jump if exit
	LD A,(COMAD+6)
	DI		;Prepare to enter ram (for ESYS access)
	LD HL,HDLEN-CWTLN
	ADD HL,SP
	LD SP,HL	;Make space for ram routine
	PUSH HL
	LD D,H
	LD E,L
	LD HL,COMWT	;Copy routine into stack buffer
	LD B,CWTLN	;LD BC,/LDIR (for Z80)
COM75:	LD A,(HLI)
	LD (DE),A
	INC DE
	DEC B
	JR NZ,COM75
	RET		;Enter ram

;-------------------------------------------------------------------------------
COMCT:	LD A,(COMAD+2)	;Continue here after exiting ram
	LD HL,CWTLN-HDLEN
	ADD HL,SP
	LD SP,HL	;Reclaim space
	EI
COM78:  LD A,(COMAD)  ;Add these (BUG REPORT)
        AND 0F2h      ;lines of code
        CP 0C0h       ;in place of the
        JR Z,COM78    ;CALL TXACK
	JR COM30
COM80:	LD A,(COMAD+6)	;Prepare for exit
	LD A,(COMAD+2)
COM90:	LD HL,HDLEN	;Exit after error
	ADD HL,SP
	LD SP,HL	;Reclaim header buffer
	POP BC
	LD A,C
	POP HL
	POP HL
	POP DE
	RET		;Exit


;-----------------------------------------------------------------------------
;Execute command, A is command number
;-----------------------------------------------------------------------------
COMCMD:
	CP 10H	;This command not used
	JR NZ,CMD10
	LD DE,HDLEN+1
	ADD HL,DE
	LD A,(HL)
	CALL COMTX
	RET C

TXACK:	LD A,(COMAD)	;Wait for acknowledgement from host
	AND 0F2H
	CP 0C0H
	JR Z,TXACK
	LD A,(COMAD+2)
CMD5:	LD A,(COMAD)
	AND 0F1H
	XOR 0C0H
	JR Z,CMD5
	RET

CMD10:	LD E,A
	AND 0FH
	RET Z	;Single byte command
	LD C,A
	LD B,0
	PUSH DE
	PUSH HL
	CALL CRXLP	;Load rest of header
	POP HL
	POP DE
	RET C	;Error
	LD A,E
	AND 0EFH
	CP 02H
	JR NZ,CMD20	;Jump if not transfer regs command
	LD C,(HL)
	INC HL
	LD A,(HL)
	LD B,0
	ADD HL,BC
	LD C,HDLEN-1
	ADD HL,BC	;Point to regs list on stack
	LD C,A
	LD D,B
	JR CMD30
CMD20:	XOR 05H
	RET NZ	;Return if not transfer memory command
	LD A,(HL)
	INC HL
	LD D,(HL)
	INC HL
	INC HL
	LD C,(HL)
	INC HL
	LD B,(HL)
	LD H,D
	LD L,A
	LD D,0

CMD30:	PUSH DE
	BIT 4,E
	JR Z,CMD40
	CALL CTXBUF	;Send data
	CALL NC,TXACK	;Wait for acknowledgement
	JR CMD50
CMD40:	CALL CRXBUF	;Load data
CMD50:	POP DE
	DEC D
	RET NZ	;Return if display unchanged


;-----------------------------------------------------------------------------
;This routine is copied into ram to allow the host access
;to the ESYS
;-----------------------------------------------------------------------------
COMWT:
	LD A,(COMAD+2)
CWT10:	XOR A	;Wait for command
CWT20:	ADD HL,HL
	DEC A
	JR NZ,CWT20
	LD A,(COMAD)
	AND 0F0H
	CP 0C0H
	JR Z,CWT30	;Jump if host waiting to send command
	CP 040H
	JR Z,CWT10
	JR CWT50		;Jump if comms disabled
CWT30:	LD A,(COMAD+3)	;Send acknowledgement
CWT40:	LD A,(COMAD)
	AND 0F2H
	CP 0C0H
	JP Z,COMCT	;Jump back to debugger
	CP 0C2H
	JR Z,CWT40
	LD A,(COMAD+2)
CWT50:	JP RESTART	;Jump to start if comms disabled or ENDTRN called
CWTLN	EQU	$-COMWT


;-----------------------------------------------------------------------------
;Transmit data to host
;HL points to data, BC is the length
;-----------------------------------------------------------------------------
CTXBUF:
	LD E,0
CTX10:	LD A,(HL)
	LD D,A
	INC HL
	CALL COMTX	;Send byte
	RET C	;Error
	LD A,D	;Checksum
	ADD A,E
	LD E,A
	DEC BC
	LD A,B
	OR C
	JR NZ,CTX10
	LD A,E	;Send checksum
	;Send a byte (in A)
COMTX:	PUSH BC
	PUSH DE
	PUSH HL
	LD C,A
	LD B,0C2H
	LD DE,COMAD+2
	LD HL,COMAD+4
	SCF
	RL C
CTX20:	RR E
	RLC E
CTX30:	LD A,(COMAD)	;Wait for handshake
	XOR B
	AND 0F2H
	JR Z,CTX40
	XOR 02H
	JR Z,CTX30
	AND 070H
	SCF
	JR NZ,CTX50	;Exit if comms disabled
	BIT 3,B
	JR NZ,CTX30
CTX40:	SET 3,B	;Send first bit even if host is not ready
	LD A,(DE)
	LD A,L
	XOR 01H
	LD L,A
	LD A,B
	XOR 02H
	LD B,A
	LD A,(HL)
	SLA C
	JR NZ,CTX20
	AND A
CTX50:	POP HL
	POP DE
	POP BC
	RET
	;On exit NC=send OK, C=comms disabled


;-----------------------------------------------------------------------------
;Receive data from host
;HL points to data, BC is the length
;-----------------------------------------------------------------------------
CRXBUF:
	LD E,0
CRXLP:	CALL COMRX	;Load byte
	RET C	;Error
	LD (HL),A
	INC HL
	ADD A,E	;Checksum
	LD E,A
	DEC BC
	LD A,B
	OR C
	JR NZ,CRXLP
	CALL COMRX	;Load checksum
	RET C	;Error
	XOR E
	ADD A,0FFH	;Signal error if checksums do not match
	RET
	;On exit NC=load OK, C=comms disabled or error


;-----------------------------------------------------------------------------
;Receive a byte from host
;-----------------------------------------------------------------------------
COMRX:
	PUSH BC
	PUSH HL
	LD BC,0C001H
	LD HL,COMAD+6
CRX10:	LD A,(COMAD)	;Wait for handshake
	AND 0F2H
	XOR B
	JR Z,CRX20
	XOR 02H
	JR Z,CRX10
	XOR B
	XOR 042H
	JR NZ,CRX30	;Jump if comms disabled
	LD A,C	;Check for 'enter ram' command
	XOR 3
	JR CRX30
CRX20:	LD A,L
	XOR 01H
	LD L,A
	LD A,B
	XOR 02H
	LD B,A
	LD A,(COMAD)
	CP (HL)
	RRA
	RL C
	JR NC,CRX10
	LD A,C
CRX30:	POP HL
	POP BC
	CCF
	RET
	;On exit NC=load OK, value in A
	;        C and A=0 - Enter ram command
	;        C and A<>0 - Comms transfer ended




;-------------------------------------------------------------------------------
START:	DI
	LD SP,0E000H	;PLACE STACK AT E000

	XOR A	;CLEAR 8K OF WORK RAM (C000-DFFF)
	LD HL,0C000H
CLRWORK:	LD (HLI),A
	BIT 5,H
	JR Z,CLRWORK

	XOR A
	LDS (STAT),A	;CLEAR LCD STATUS
	LDS (IF),A	;CLEAR INTERRUPT FLAG

	LD A,1
	LDS (IE),A	;ENABLE V_BLANK INTERRUPT


	CALL JUMPTABLE+0	;Initialise driver
	LD A,0FFH
	LD (sfxno),A
	LD (tuneno),A
	LD (PCnewdata),A
	XOR A
	LD (editnum),A
	LD (selectflag),A
	EI

;-------------------------------------------------------------------------------
MAIN:	CALL COMMS

NEWchk:	ld a,(PCnewdata)
	cp 0ffh
	jr z,JOYchk
	call JUMPTABLE+6	;re-initialise after compression
	LD A,0FFH
	LD (PCnewdata),A	;cancel flag


JOYchk:	CALL CONT	;get a key press
	LD A,(CNT1)	;GET VALUE
	bit 0,A
	JR NZ,AKEY
	bit 1,a
	jr nz,BKEY
	bit 2,a
	jr nz,SELECT
	bit 3,A
	JR NZ,STRTBUT
	bit 6,A
	JR NZ,UPKEY
	bit 7,A
	JR NZ,DNKEY
	JR VBLK_WT

UPKEY:	LD A,(editnum)	;inc call number
	INC A
	LD (editnum),A
	JR KEYEND
DNKEY:	LD A,(editnum)	;dec call number
	DEC A
	LD (editnum),A
	JR KEYEND
AKEY:	ld a,0		;select music calls
	ld (selectflag),a
	JR KEYEND
BKEY:	ld a,0FFh	;select effect calls
	ld (selectflag),a
	JR KEYEND

SELECT:	ld a,080h
	ld (tuneno),A	;kill music
	xor a
	ld (sfxno),A	;effect 0
	jr keyend

STRTBUT:
	ld a,(selectflag)
	cp 0ffh
	jr nz,STRTUNE
	LD A,(editnum)
	LD (sfxno),A
	JR keyend

STRTUNE:
	ld a,(editnum)
	LD (tuneno),A	;start tune

KEYEND:	CALL CONT
	LD A,(CNT1)
	CP 0
	JR NZ,KEYEND	;wait for key release

VBLK_WT:
	HALT		;system stop until next interrupt
	LD A,(vbi_flag)
	AND A		;VBLANK interrupt ?
	JR Z,VBLK_WT
	XOR A
	LD (vbi_flag),A	;clear flag (set at end of VBLANK)
	JP MAIN


;-------------------------------------------------------------------------------
CONT:	LD C,P1 AND 0FFH	;key port address
	LD A,020H
	LD (C),A
	LD A,(C)
	LD A,(C)
	LD A,(C)

	LD B,A
	LD A,010H
	LD (C),A
	LD A,B

	AND 0FH
	SWAP A
	LD B,A

	LD A,(C)
	LD A,(C)
	LD A,(C)
	LD A,(C)
	LD A,(C)
	LD A,(C)
	LD A,(C)
	LD A,(C)
	LD A,(C)

	AND 0FH
	OR B
	CPL
	LD B,A

	LD A,030H
	LD (C),A
	LD A,(CNT1)
	XOR B
	AND B
	LD (TRG1),A

	LD A,B
	LD (CNT1),A

	RET



;-------------------------------------------------------------------------------
;Get_Info
;-------------------------------------------------------------------------------
Get_Info:
	LD BC,PCbuffer
	LD A,(TUNENO)
	LD (BC),A
	INC BC
	LD A,(STATUS)
	LD (BC),A
	INC BC
	LD A,(TEMPOVAL)
	LD (BC),A
	INC BC
	LD A,(CLOCK_L)
	LD (BC),A
	INC BC
	LD A,(CLOCK_H)
	LD (BC),A
	INC BC
	LD A,(GLOBOFFSET)
	LD (BC),A
	INC BC

	XOR A
	LD D,A
	LD E,A
	LD (CURCHAN),A

Gilup1:	LD HL,NOTELENGTH
	ADD HL,DE
	LD A,(HL)
	LD (BC),A
	INC BC
	LD HL,THRESHOLD
	ADD HL,DE
	LD A,(HL)
	LD (BC),A
	INC BC
	LD HL,VOICENUM
	ADD HL,DE
	LD A,(HL)
	LD (BC),A
	INC BC
	LD HL,NOTEVALUE
	ADD HL,DE
	LD A,(HL)
	LD (BC),A
	INC BC
	LD HL,SEQNUM
	ADD HL,DE
	LD A,(HL)
	LD (BC),A
	INC BC
	LD HL,STEREO
	ADD HL,DE
	LD A,(HL)
	LD (BC),A
	INC BC

	LD HL,SDLN
	ADD HL,DE	;add current value
	LD D,H
	LD E,L		;& move to DE
	LD HL,CURCHAN
	INC (HL)
	LD A,(HL)
	CP 3
	JP C,Gilup1
	RET




	ENDIF


;-------------------------------------------------------------------------------
; ****** START OF DRIVER CODE ******
;-------------------------------------------------------------------------------

	ORG MUSICROM

JUMPTABLE:
	JP INITSND	;Initialise sound routine
	JP INTSND	;Interrupt routine
	JP INVEC		;New load routine

INITSND:
	LD HL,MUSICVAR	;clear variable RAM
	LD BC,VARSIZE
CLRVAR:	LD (HL),0
	INC HL
	DEC BC
	LD A,B
	OR C
	JR NZ,CLRVAR
	CALL INVEC	;calc. addresses from vector table

	LD A,0ffh	;initialise RAM variables
	LD (SFXCHAN1),A
	LD (SFXCHAN1+SDLN),A
	LD (SFXCHAN1+SDLN+SDLN),A
	LD (PRIORITY),A
	LD (PRIORITY+SDLN),A
	LD (PRIORITY+SDLN+SDLN),A
	LD (VCEMUTE),A
	LD (VCEMUTE+SDLN),A
	LD (VCEMUTE+SDLN+SDLN),A
	LD (NCHAN),A
	LD A,8
	LD (ENVAL+1),A
	LD (ENVAL+SDLN+1),A
	LD (ENVAL+SDLN+SDLN+1),A
	ld a,0FFh
	ld (TEMPOVAL),a	;default tempo = 296

	LD A,80H
	LDS (NR52),A	;all sound circuits on
	LD A,008h
	LDS (NR10),A	;sound 1 mode = sweep off
	XOR A
	LDS (NR30),A	;sound 3 output stop
	LDS (NR34),A	;continuous sound 3

	LD B,16	;clear WAVE RAM
	LD HL,WAVE
CLRWAVE:	LD (HLI),A
	DEC B
	JR NZ,CLRWAVE

	LD BC,0400h	;set all 4 channels to freq=0
IN30:	PUSH BC
	CALL FREQOFF
	POP BC
	INC C
	DEC B
	JR NZ,IN30

	xor a
	LDS (NR11),A
	LDS (NR21),A
	LDS (NR31),A
	LDS (NR41),A
	LD A,020h
	LDS (NR32),A	;sound 3 full volume
	LD A,77h
	LDS (NR50),A	;max. volume to SO1 & SO2
	LD A,0FFh
	LDS (NR51),A	;all channels to both SO1 & SO2
	LD A,08Fh
	LDS (NR52),A	;all sound channels on
	RET


;-----------------------------------------------------------------------------
;Calculate new pointers from Musicdata chunk sizes
;-----------------------------------------------------------------------------
INVEC:	LD HL,GAMEDAT1	;chunk table start address
	LD DE,GAMEDAT1+14	;music data start address
IN50:	LD A,E
	LD (FXBANK),A
	LD A,D
	LD (FXBANK+1),A	;save start address of effects

	ld bc,FXTABLE
	call stvar	;calculate FXTABLE address
	CALL STVAR	;calculate VCEBANK address
	CALL STVAR	;calc. SEQOFF address
	CALL STVAR	;calc. SEQDATA address
	CALL STVAR	;calc. TRKOFF address
			;calc. TRKDATA address
STVAR:	LD A,(HLI)	;get low byte from vector table
	ADD A,E		;add GAMEDATA low byte address
	LD E,A		;and save in E
	LD (BC),A	;and save in final offset low byte
	INC BC		;now move to high byte
	LD A,(HLI)	;get high byte from vector table
	ADC A,D		;add GAMEDATA high byte address
	LD D,A		;DE now holds address of this block
	LD (BC),A	;save to final offset high byte
	INC BC		;now move to next dest. entry

	RET




;-------------------------------------------------------------------------------
;INTERRUPT ROUTINE
;-------------------------------------------------------------------------------
INTSND:	LD A,(sfxno)
	CP 0FFH
	JR Z,INTSND2
	CALL SENDFX
	LD A,0FFH
	LD (sfxno),A
INTSND2:
	LD A,(tuneno)
	CP 0FFH
	JR Z,INTSND3
	CALL SENDMUS
	LD A,0FFH
	LD (tuneno),A
INTSND3:
	CALL INTSFX
	CALL INTMUSIC

	ld de,0
	ld a,0
	call EXESD
	ld de,SDLN
	ld a,1
	call EXESD
	ld de,2*SDLN
	ld a,2
EXESD:	ld (CURCHAN),a	;0/1/2 (current channel)
	call OUTSOUND
	ret




;-------------------------------------------------------------------------------
SENDFX:	ld hl,0
	ld l,a	;enter with A=FXTABLE call number
	add hl,hl
	add hl,hl	;4 bytes for each entry
	ld a,(FXTABLE)
	add a,l
	ld c,a
	ld a,(FXTABLE+1)
	adc a,h
	ld h,a	;final high byte of address
	ld l,c	;final low byte of address

	ld c,(hl)	;get priority
	inc hl
	ld a,(hli)	;get chan0 call
	cp 0ffh
	jr z,sendfx1
	ld (SFXCHAN1),a
	ld a,c
	ld (PRIORTEST),a
sendfx1:	ld a,(hli)	;get chan1 call
	cp 0ffh
	jr z,sendfx2
	ld (SFXCHAN1+SDLN),a
	ld a,c
	ld (PRIORTEST+SDLN),a
sendfx2:	ld a,(hli)	;get chan2 call
	cp 0ffh
	jr z,sendfx3
	ld (SFXCHAN1+SDLN+SDLN),a
	ld a,c
	ld (PRIORTEST+SDLN+SDLN),a
sendfx3:	ld a,(STATUS)
	rla
	ret C	;not during music
	ld a,077H	;max volume in both left & right
	lds (NR50),a	;(after fade etc.)
	ret




;-------------------------------------------------------------------------------
INTSFX:	XOR A
	LD D,A	;channel 0
	LD E,A
	CALL CALLFX
	LD A,1
	LD DE,SDLN	;channel 1
	CALL CALLFX
	LD A,2
	LD DE,2*SDLN	;channel 2

CALLFX:	LD (CURCHAN),A
	LD HL,FQOFF
	ADD HL,DE
	LD (HL),0	;FQOFF=0

	LD HL,SFXCHAN1
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,TESTMUSIC	;no call in this channel
	LD A,(HL)
	LD B,A	;new effect number saved in B

	inc hl
	ld c,(hl)	;C=PRIORTEST for required effect

	LD HL,PRIORITY
	ADD HL,DE
	LD A,(HL)	;get current priority
	CP C
	JR NC,LOADFX	;higher or equal, so accept
	PUSH HL	;save address of current priority
	LD HL,SFXHOLD
	ADD HL,DE
	LD A,(HL)
	POP HL
	AND A
	JR Z,LOADFX	;64 frames past
	LD HL,SFXCHAN1
	ADD HL,DE
	LD (HL),0ffh	;else cancel try

TESTMUSIC:	LD HL,SFXCHOP
	ADD HL,DE
	XOR A
	CP (HL)
	JR Z,TESTABORT	;end of sound (endcnt reduced to 0)
	PUSH HL
	LD HL,VCEMUTE
	ADD HL,DE
	CP (HL)	;cmp vcemute to 0
	POP HL
	JP NZ,TIMEFX
	LD (HL),A	;sfxchop to 0

TESTABORT:	LD HL,SFXHOLD	;force to 0 for sounds < 64 frames
	ADD HL,DE
	LD (HL),A
	RET


LOADFX:	ld (hl),c	;save this priority
	ld hl,0
	ld l,b	;retreive effect number
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl	;16 bytes each effect
	ld a,(FXBANK)
	add a,l
	ld c,a
	ld a,(FXBANK+1)
	adc a,h
	ld b,a

	LD HL,ENAD
	ADD HL,DE
	LD A,(BC)
	LD (HLI),A	;save attdec to ENAD (overwrite music)

	INC BC
	LD A,(BC)
	LD (HLI),A	;save susrel to ENSR (overwrite music)

	ld a,0F8H
	ld (hli),a	;ATKLVL forced to maximum level

	INC BC
	LD A,(BC)
	LD (HLI),A	;save atkcnt to ATKHOLD

	XOR A
	LD (HLI),A	;ENSEQ=0 (attack)
	INC A
	LD (HLI),A	;ENVAL=1
	LD (HL),8	;FQOFF=8

	LD HL,SFXCHOP
	ADD HL,DE
	INC BC
	LD A,(BC)
	LD (HLD),A	;save endcnt to SFXCHOP

	LD (HL),HOLDTIME	;SFXHOLD= 100 frames
	DEC HL
	dec hl
	ld (hl),0ffh	;SFXCHAN1=0ffh

	LD HL,CTRLAD
	ADD HL,DE
	inc bc
	ld a,(bc)
	ld (hli),a	;save wave ad to CTRLAD

	inc bc
	ld a,(bc)
	ld (hli),a	;save wave sr to CTRLSR

	inc bc
	ld a,(bc)
	inc hl	;skip freqlo dest.
	ld (hl),a	;save freqhi to FREQ high byte
	inc bc
	ld a,(bc)
	dec hl
	ld (hli),a	;save freqlo to FREQ low byte
	inc hl

	inc bc
	LD A,(BC)
	LD (HLI),A	;save bend to BENDTYPE

	INC BC
	LD A,(BC)
	inc hl	;skip bendlo dest
	LD (HL),A	;save bendhi to BEND high byte
	INC BC
	LD A,(BC)
	dec hl
	LD (hli),A	;save bendlo to BEND low byte
	inc hl	;skip bendhi dest

	inc bc
	push bc
	push hl
	ld a,(bc)
	and 11h	;L/R bits only
	ld hl,STEREO
	add hl,de
	ld (hl),a	;save STEREO (effect)
	push af
	ld a,(CURCHAN)	;STEREO (1st frame only)
	inc a
	ld c,a	;C=1,2,3 (current channel+1)
	pop af	;retrieve STEREO
	ld b,0EEh
	dec c
	jr z,loadfx2	;channel 1
	add a,a	;11h to 22h
	ld b,0DDh
	dec c
	jr z,loadfx2	;channel 2
	add a,a	;channel 3   (22h to 44h)
	ld b,0BBh
loadfx2:	ld c,a	;C=stereo bits
	lds a,(NR51)	;get assignment
	and b	;mask out this channel
	or c		;add stereo for this channel
	lds (NR51),a
	pop hl
	pop bc

	inc bc
	LD A,(BC)
	LD (HLI),A	;save specls to SFXEXTRA

	inc bc
	ld a,(bc)
	ld (hli),a	;save newcnt to CNTDOWN
	ld (hli),a	;         and to CNTVAL
	inc bc
	ld a,(bc)
	ld (hli),a	;save newfhi to NEWVAL
	inc bc
	ld a,(bc)
	ld (hli),a	;save newflo to NEWVAL2
	INC HL	;skip PRIORITY
	LD (HL),0FFH	;DIRFLAG=0FFh
	ret



TIMEFX:	LD HL,SFXHOLD
	ADD HL,DE
	LD A,(HL)
	AND A
	JR Z,TIMING1
	DEC (HL)
TIMING1:	LD HL,CNTDOWN
	ADD HL,DE
	DEC (HL)
	BIT 7,(HL)
	JR Z,TIMING2
	INC HL
	LD A,(HLD)	;cntval
	LD (HLI),A
	INC HL
	INC HL
	INC HL
	inc hl
	LD A,(HL)	;DIRFLAG
	CPL		;toggle
	LD (HL),A	;& resave
TIMING2:	LD HL,ATKHOLD
	ADD HL,DE
	LD A,(HL)
	AND A	;set flags
	JR NZ,TIMING4	;continue attack cycle
	LD HL,CTRLSR
	ADD HL,DE
	LD A,(HLD)
	CP (HL)
	JR NZ,TIMING3	;start release cycle

	DEC HL
	LD A,(HL)	;sfxchop
	CP 0FFH
	JR Z,SBENDING	;ff=no chop
	DEC (HL)
	JR NZ,SBENDING	;not ended, so continue effects
	INC HL
	LD (HL),0	;CTRLAD=0
	LD HL,ENVAL+1
	ADD HL,DE
	LD (HL),0	;ENVAL+1=0
	RET

TIMING3:	LD (HL),A	;CTRLSR to CTRLAD (start release)
	JR SBENDING
TIMING4:	DEC (HL)	;atkhold


SBENDING:	LD HL,BENDTYPE
	ADD HL,DE
	LD A,(HL)
	AND A
	JR Z,SPECSFX

BEND3:	LD HL,ATKHOLD
	ADD HL,DE
	SUB 3
	JR NZ,BEND4
	OR (HL)
	JR NZ,BEND1A
	JR SPECSFX

BEND4:	DEC A	;BEND4
	JR NZ,BEND5
	OR (HL)
	JR NZ,BEND2A
	JR SPECSFX

BEND5:	DEC A	;BEND5
	JR NZ,BEND6
	OR (HL)
	JR NZ,BEND1A
	JR BEND2A

BEND6:	DEC A	;BEND6
	JR NZ,BEND7
	OR (HL)
	JR NZ,BEND2A
	JR BEND1A

BEND7:	DEC A	;BEND7
	JR NZ,BEND8
	OR (HL)
	JR Z,BEND1A
	JR SPECSFX

BEND8:	DEC A	;BEND8
	JR NZ,BEND9
	OR (HL)
	JR Z,BEND2A
	JR SPECSFX

BEND9:	DEC A	;BEND9
	JR NZ,BEND1
	LD HL,DIRFLAG
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,BEND1A
	JR BEND2A

BEND1	SUB 0F8H		;WAS '1-9'	BEND1
	JR NZ,BEND2
BEND1A:	LD HL,FREQ
	ADD HL,DE
	LD B,H
	LD C,L
	INC BC
	INC BC
	INC BC
	LD A,(BC)	;BEND low byte
	ADD A,(HL)
	LD (HLI),A
	INC BC
	LD A,(BC)	;BEND high byte
	ADC A,(HL)
	LD (HL),A
	JR SPECSFX

BEND2:	DEC A
	JR NZ,SPECSFX
BEND2A:	LD HL,FREQ
	ADD HL,DE
	LD B,H
	LD C,L
	INC HL
	INC HL
	INC HL
	LD A,(BC)
	SUB (HL)
	LD (BC),A
	INC BC
	INC HL
	LD A,(BC)
	SBC A,(HL)
	LD (BC),A


SPECSFX:
	LD HL,SFXEXTRA
	ADD HL,DE
	LD A,(HL)
	AND A
	RET Z		;no special effect
	LD C,A
	LD HL,FREQ+1
	ADD HL,DE

SF01:	SRL C		;swap F lo/F hi @ 60Hz
	JR NC,SF02
	LD A,(HLD)
	LD B,(HL)
	LD (HLI),A
	LD (HL),B

SF02:	SRL C		;Complex F hi sbc bendhi/eor newval
	JR NC,SF04
	PUSH HL
	LD A,(HL)	;FREQ high byte
	INC HL
	INC HL
	INC HL
	SUB (HL)		;BEND high byte
	LD HL,NEWVAL
	ADD HL,DE
	XOR (HL)
	POP HL
	LD (HL),A

SF04:	SRL C		;waver F lo + (random and #7)
	JR NC,SF08
	LD A,(SEED)	;random number generator
	LD B,A
	ADD A,A
	ADD A,A
	ADD A,A
	ADD A,A
	ADD A,B
	ADD A,11
	LD (SEED),A
	SWAP A
	AND 0fH
	PUSH HL
	LD HL,FQOFF	;08 if effect call/0 if not
	ADD HL,DE
	LD (HL),A	;FQOFF= random 0-0fh i.e. +/- 8
	POP HL

SF08:	SRL C		;Reload
	jr nc,SF10
	PUSH HL
	LD HL,CNTDOWN
	ADD HL,DE
	LD A,(HLI)
	INC HL		;NEWVAL is 2 bytes further on
	AND A		;set flags according to CNTDOWN
	LD A,(HL)	;get NEWVAL
	POP HL
	RET NZ
	LD (HL),A	;F hi reloaded with NEWVAL

SF10:	SRL C		;swap low frequency nibbles @ 60Hz
	jr nc,SF20
	dec hl
	ld a,(hl)
	swap a
	ld (hl),a
	inc hl

SF20:	SRL C		;Complex F lo sbc bendlo/eor newflo
	RET NC
	PUSH HL
	dec hl
	LD A,(HL)	;FREQ low byte
	INC HL
	INC HL
	INC HL
	SUB (HL)		;BEND low byte
	LD HL,NEWVAL2
	ADD HL,DE
	XOR (HL)
	POP HL
	dec hl
	LD (HL),A
	ret




;-------------------------------------------------------------------------------
;OUT SOUND - Envelope/ FQOFF/ Noise/ Frequency/ Waveform
;DE=0,SDLN,SDLN*2
;CURCHAN=0,1,2
;-------------------------------------------------------------------------------
OUTSOUND:	LD HL,SFXHOLD	;Check for effect in this channel
	ADD HL,DE
	ld a,(hl)
	cp 0
	JR Z,OUTSOUND2	;EFFSND=0  (music)
	ld a,0FFh	;EFFSND=FF (effect)
OUTSOUND2:	LD (EFFSND),A

	LD HL,CTRLAD	;current waveform (effect or music)
	ADD HL,DE
	BIT 0,(HL)	;gate bit
	LD HL,ENSR	;current sustain/release
	ADD HL,DE
	JR Z,RELEASE	;if gate off

ATTDECSUS:	LD A,(HLD)	;gate bit on
	AND 0F0H	;ENSR sustain nibble
	LD B,A	;B holds sustain value
	LD A,(HLI)	;ENAD
	INC HL
	INC HL
	inc hl
	LD C,(HL)	;C=ENSEQ
	PUSH HL
	BIT 1,C
	CALL Z,EXENVF	;if attack or decay phase
	POP HL
	LD (HL),C	;save new ENSEQ phase
	JR OUTFREQ

RELEASE:	LD B,(HL)	;B=ENSR (gate off)
	INC HL
	INC HL
	inc hl
	LD (HL),0	;ENSEQ=0 (set attack phase)
	LD HL,ENVAL+1
	ADD HL,DE
	LD A,(HLD)
	SUB 08H
	JR NZ,RELEASE2	;not at sustain level
	OR (HL)	;at sustain level (ENVAL)
	RET Z	;at sustain level of 0
RELEASE2:	LD A,B	;A=ENSR (gate off)
	LD BC,1	;force decay (release phase)
	CALL EXENVF	;release phase

;-----------------------------------------------------------------------------
OUTFREQ:	LD HL,FQOFF	;frequency offset
	ADD HL,DE
	LD A,(HL)	;A=FQOFF (0 if music/8 or 0-0F effect)
	LD HL,CTRLAD
	ADD HL,DE
	LD B,(HL)	;B=current waveform
	INC HL
	INC HL
	add a,(hl)
	ld e,a	;E=FREQ low byte +FQOFF
	inc hl
	ld d,(hl)	;DE = word FREQ+FQOFF
	ld a,d

	LD A,B	;A=current waveform
	LD BC,ENVAL-FREQ AND 0FFH
	ADD HL,BC
	LD L,(HL)	;L=ENVAL
	LD H,A	;H=current waveform
	LD A,(CURCHAN)
	LD C,A	;C=current channel (0/1/2/3)
	LD A,L	;A=ENVAL
	AND 0F0H	;isolate current envelope level
	JR Z,NOVOLUME	;volume = 0
	LD A,(NCHAN)	;A=current noise channel
	BIT 7,H	;H=current waveform
	JR Z,NONOISE	;noise bit not set (in H)

;-----------------------------------------------------------------------------
	push af
	ld a,(EFFSND)
	cp 0
	jr z,NOISE	;music, so check other channels
	pop af
	jr NOISE_EFF	;effect, so force noise
NOISE:	pop af

	CP 0FFH	;any other noise already?
	JR NZ,NOISE1	;yes, so leave noise channel alone
NOISE_EFF:	LD A,C	;no noise used so far
	LD (NCHAN),A	;so this channel will use noise
NOISE1:	CP C		;noise in this channel?
	JR NZ,PULSE	;no

	PUSH BC	;yes,noise in this channel
	PUSH DE
	PUSH HL	;H was CTRLAD/L was ENVAL
	LD B,L	;B=ENVAL

	ld a,d	;get high byte of freq
	xor 0ffh
	swap a
	and 70h	;bits 4,5,6 only
	ld d,a

	ld a,e	;get low byte of freq
	xor 0ffh
	swap a
	and 0Ch	;bits 2 and 3 only (& force bit 3 low)
	rr a
	rr a		;a has bits 0 and 1
	or 04h	;force bit 2 high
	or d		;add top 4 bits
NOISE2:	ld l,a	;low byte into l
	ld c,3	;force channel 3 (noise)
	ld h,0	;3 bits of freq hi always 0
	CALL SETFREQ	;set noise frequency

	ld a,(CURCHAN)	;noise stereo position
	ld c,a
	inc c	;c=1,2,3
	ld hl,STEREO
	dec c
	jr z,noise3	;1 to 0
	ld hl,STEREO+SDLN
	dec c	;2 to 1 to 0
	jr z,noise3
	ld hl,STEREO+SDLN+SDLN
noise3:	ld a,(hl)
	add a,a
	add a,a
	add a,a	;convert to channel 4 bit position
	ld b,077h	;channel 4 mask
	ld c,a	;C=stereo bits
	lds a,(NR51)	;get assignment
	and b	;mask out this channel
	or c		;add stereo for this channel
	lds (NR51),a
	JR ENDNOISE

NONOISE:	CP C		;noise bit off in this channel
	JR NZ,PULSE	;but noise in another channel
	PUSH BC	;no noise and this was noise channel
	PUSH DE
	PUSH HL
	CALL NSOFF	;so switch off noise
ENDNOISE:	POP HL	;H=CTRLAD/ L=ENVAL
	POP DE	;DE=frequency word
	POP BC	;B=unused/ C=current channel

;-----------------------------------------------------------------------------
PULSE:	LD A,H	;A=current waveform
	AND 040H	;check for pulse wave
	JR Z,FREQOFF	;no other waveforms (set freq = 0)

	LD B,L	;B=ENVAL
	LD L,E	;transfer DE to HL
	LD H,D
	JR SETFREQ	;other waveforms needed

;-----------------------------------------------------------------------------
NOVOLUME:	LD A,(NCHAN)	;envelope level=0
	CP C		;was this the noise channel?
	JR NZ,FREQOFF	;no, so just set tone=0/level=0

	CALL FREQOFF	;yes, so set tone=0/level=0
NSOFF:	LD A,0FFH	;cancel noise channel
	LD (NCHAN),A
	LD C,3	;& set noise freq = 0/level=0 (chan 3)

;-----------------------------------------------------------------------------
;SET FREQUENCY
;B=ENVAL
;C=channel 0,1,2 or 3
;HL=11 bit frequency value (FREQOFF sets HL=0)
;A=unused
;-----------------------------------------------------------------------------
FREQOFF:	LD HL,0
	LD B,H	;force 0 volume

SETFREQ:	PUSH BC	;save ENVAL and current channel
	LD A,C
	LD BC,NR13	;low byte freq (sound 1)
	AND A	;set flags
	JR Z,SETFR2	;channel 1
	LD BC,NR23
	DEC A
	JR Z,SETFR2	;channel 2
	LD BC,NR33
	DEC A
	JR Z,SETFR2	;channel 3
	LD BC,NR43	;channel 4

SETFR2:	LD A,L	;L=low byte value
	LD (BC),A	;save low byte (NR13/23/33/43)
	INC C	;now move to high byte freq. register
	LD A,H
	AND 07H	;only 3 bits used for frequency high
	LD (BC),A	;save high byte (NR14/24/34/44)

	POP HL	;retreive ENVAL (PUSH BC)
	LD L,A	;L=high byte of freq
	LD A,H	;A=ENVAL
	AND 0F0H	;isolate envelope level
	LD H,A	;H=current envelope level
	LD A,C
	CP NR34 AND 255	;channel 3 ?
	JR Z,SETWAVE	;yes

	dec c
	dec c
	cp NR44 and 255	;channel 4 ?
	jr z,SETENV	;yes,so ignore
	push hl
	ld hl,CTRLAD	;channel 1 & 2 current waveform
	cp NR14 and 255
	jr z,SETPW
	ld hl,CTRLAD+SDLN
SETPW:	ld a,(hl)	;get current waveform
	and 030h	;pulse width bits only
	add a,a
	add a,a	;move to bit 7 & 6
     	dec c
     	ld (bc),a	;save waveform (NR11/21)
     	pop hl
     	inc c

SETENV:	LD A,(BC)	;NR12/22/42 envelope
	AND 0F0H	;current envelope level
	CP H		;desired envelope level
	RET Z	;don't change if same
	LD A,H
	LD (BC),A	;save new envelope level
	INC C
	INC C
SETINIT:	LD A,L	;high 3 bits of frequency
	OR 80H	;set restart bit
	LD (BC),A	;save to NR14/24/34/44
	AND 07H	;extract freq high bits only
	LD (BC),A	;freq hi only (already restarted)
	RET


SETWAVE:	LD A,(ENC3)	;channel 3 only (wave table)
	CP H		;is desired same as current level ?
	RET Z	;don't change if same level
	XOR A
	LDS (NR30),A	;sound 3 off
	LD A,H
	LD (ENC3),A	;save desired as new volume level
	SWAP A	;each nibble is same level
	OR H		;A has level in each nibble

	push hl
	push af
	ld hl,CTRLAD+SDLN+SDLN
	ld a,(hl)
	swap a
	and 03h	;pulse width bits only
	inc a	;1-4
	ld l,a

	pop af	;retreive volume level
	lds (WAVE),a
	lds (WAVE+8),a	;12.%5 width
	dec l
	call z,SE70	;if l=1
	lds (WAVE+1),a
	lds (WAVE+9),a	;25% width (l=2)
	dec l
	call z,SE70
	lds (WAVE+2),a
	lds (WAVE+3),a
	lds (WAVE+10),a
	lds (WAVE+11),a	;50% width (l=3)
	dec l
	call z,SE70
	lds (WAVE+4),a
	lds (WAVE+5),a
	lds (WAVE+12),a
	lds (WAVE+13),a	;75% width (l=4)
	pop hl
	LD A,80H
	LDS (NR30),A	;sound 3 on
	JR SETINIT	;now restart sound

SE70:	xor a
	ret


;-----------------------------------------------------------------------------
;A=ENAD (gate on)
;A=ENSR (gate off)
;-----------------------------------------------------------------------------
EXENVF:	PUSH DE	;save SDLN*1,2,3

	push af
	LD HL,ATKLVL
	ADD HL,DE
	LD A,(HL)
	LD (MAXVOL),A
	pop af

	LD HL,ENVAL
	ADD HL,DE
	PUSH HL
	LD E,(HL)
	INC HL
	LD H,(HL)
	LD L,E	;HL=ENVAL (word)

	CALL EXENV	;exits with HL=new ENVAL

	POP DE	;ENVAL address (push HL)
	LD A,L
	LD (DE),A
	INC DE
	LD A,H
	LD (DE),A	;final value of ENVAL (word)
	POP DE	;restore channel offset
	RET

;-----------------------------------------------------------------------------
;CREATE ENVELOPES
;A=ENAD/B=sustain value 00-F0 (gate on)
;A=ENSR/B=0                   (gate off)
;C=ENSEQ	0=attack/1=decay/2=sustain phase

;HL=ENVAL (word)
;-----------------------------------------------------------------------------
EXENV:	PUSH HL	;HL=ENVAL (word)
	BIT 0,C	;C=ENSEQ
	JR NZ,EX10
	RRCA		;attack times are shorter
	RRCA
	RRCA		;divide by 8
	JR EX20
EX10:	ADD A,A	;decay times are longer
EX20:	AND 01EH	;only 15*2 bytes in table
	ADD A,ADRTABLE AND 255
	LD L,A
	ADC A,ADRTABLE/256
	SUB L
	LD H,A	;HL=ADRTABLE entry address
	LD E,(HL)
	INC HL
	LD D,(HL)	;DE=envelope time (word)
	POP HL	;HL=ENVAL (word)
	BIT 0,C	;ENSEQ
	JR NZ,ENV_DEC	;if decay phase

ENV_ATK:	ADD HL,DE	;ENVAL+(envelope time)
	JR C,ENV_ATK2
	ADD HL,DE
	JR C,ENV_ATK2
	ADD HL,DE
	JR C,ENV_ATK2
	LD A,H

	push hl	;save new ENVAL
	LD HL,MAXVOL	;previously found 00-0F
	CP (HL)	;maximum value for this voice
	pop hl
	RET C	;not reached peak yet

ENV_ATK2:	LD HL,MAXVOL
	LD A,(HL)
	LD H,A
	LD L,0
	INC C	;move to decay phase next
	RET

ENV_DEC:	LD A,B	;(or forced release)
	AND 0F0H	;B=00-F0 isolate sustain nibble
	OR 07H
	LD B,A
	SCF		;set carry
	LD A,L
	SBC A,E
	LD L,A
	LD A,H
	SBC A,D
	LD H,A	;HL=ENVAL-(envelope time)
	LD A,B	;A=(sustain OR 7)
	JR C,ENV_SUS
	CP H
	INC HL
	RET C	;not reached sustain phase

ENV_SUS:	INC A	;sustain
	LD H,A
	LD L,0
	INC C	;move to sustain phase next
	RET




;-------------------------------------------------------------------------------
;START OF MUSIC CODE
;-------------------------------------------------------------------------------

SENDMUS:
	BIT 7,A		;Enter with A = tracknum or (80H+fader count)
	JR Z,SMUSIC2
	AND 07FH		;negative value = fade value
	LD (FADER),A
	RET		;nothing this time

SMUSIC2:
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl	;8 bytes each track
	ld a,l
	ld b,h		;save high byte of word offset
	LD HL,TRKOFF	;get pointer for this musicdata
	ADD A,(HL)	;add low byte of trkoffset
	LD E,A		;save low byte of final address
	INC HL
	ld a,b		;retreive high byte
	ADC A,(HL)	;add high byte of trkoffset
	LD H,A		;final high byte of address
	LD L,E		;final low bytes of address
	LD A,(HLI)	;A points to 1st low byte

	LD (TRACK),A
	LD A,(HLI)
	LD (TRACK+1),A
	LD A,(HLI)
	LD (SDLN+TRACK),A
	LD A,(HLI)
	LD (SDLN+TRACK+1),A
	LD A,(HLI)
	LD (2*SDLN+TRACK),A
	LD A,(HLI)
	LD (2*SDLN+TRACK+1),A

	LD DE,0
	LD B,3    	;3 channels
SM20:	PUSH BC
	LD HL,VCEMUTE
	ADD HL,DE
	XOR A
	LD (HL),A
	LD HL,LOOPFLAG
	ADD HL,DE
	LD (HL),A
	LD HL,SEQSTEP
	ADD HL,DE
	LD (HL),A
	LD HL,CTRLAD
	ADD HL,DE
	LD (HL),A
	LD HL,ENSR
	ADD HL,DE
	LD (HL),A
	LD HL,DURATION
	ADD HL,DE
	LD (HL),1
	ld a,0FFh
	LD HL,VOICENUM
	ADD HL,DE
	ld (hl),a
	ld hl,THRESHOLD
	add hl,de
	ld (hl),a
	ld hl,TRKSTEP
	add hl,de
	ld (hl),a
	CALL READTK
	LD HL,SDLN
	ADD HL,DE
	LD D,H
	LD E,L
	POP BC
	DEC B
	JR NZ,SM20
	XOR A
	LD (FADECNT),A
	ld (GLOBOFFSET),a
	DEC A
	LD (FADER),A
	LD (STATUS),A
	LD (TEMPOCNTR),A
	ld (CLOCK_L),a	;starts @ 0FFFFh 1st inc to 0000h
	ld (CLOCK_H),a
	ld a,07h
	LD (VOLUME),A
	LD A,077H	;max volume in both left & right
	LDS (NR50),A
	RET




;-------------------------------------------------------------------------------
INTMUSIC:
	LD A,(STATUS)
	RLA
	RET NC	;if not minus

	LD A,(FADER)	;fadetest
	BIT 7,A
	JR NZ,TEMPOTEST

	OR A		;set flags
	JR Z,TRKSTOP	;080H fader value = stop immediately
	LD HL,FADECNT	;fader active
	DEC (HL)
	BIT 7,(HL)
	JR Z,TEMPOTEST
	LD (HL),A	;save FADER value back into FADECNT
	LD HL,VOLUME	;end of fade count so dec volume (inits to 07h)
	DEC (HL)
	JR Z,TRKSTOP	;end of fade
	LD A,(HL)	;get current VOLUME
	LD C,A
	SWAP A
	OR C		;put into both nibbles
	LDS (NR50),A

TEMPOTEST:	LD A,(TEMPOCNTR)
	LD	HL,TEMPOVAL
	ADD	A,(HL)
	LD	(TEMPOCNTR),A
	JR	NC,TEMPO2
	ld	hl,CLOCK_L	;now update tempo clock
	inc	(hl)
	jp	nz,TEMPO1
	inc	hl
	inc	(hl)
TEMPO1:	XOR A
	JR TEMPO3
TEMPO2:	LD A,0FFH
TEMPO3:	LD (TEMPOFLAG),A

MUSIC1:	XOR A
	LD D,A
	LD E,A
	LD (CURCHAN),A
MUSICLOOP:	LD HL,SFXHOLD
	ADD HL,DE
	LD A,(HL)
	AND A
	JR Z,MUSIC1B	;past critical portion/ no effect
	LD HL,VCEMUTE
	ADD HL,DE
	LD (HL),0FFH	;mute music channel during effect

MUSIC1B:	LD A,(TEMPOFLAG)
	AND A
	JP NZ,TREATMENT

	ld hl,NOTELENGTH	;music2
	add hl,de
	inc (hl)
	inc hl
	dec (hl)	;DURATION
	jp nz,TREATMENT

	LD HL,SEQNUM	;trkread
	ADD HL,DE
	LD A,(HLD)	;HL now points to SEQSTEP
	CP 0FEH
	JR C,SEQREAD
	JR NZ,TRKLOOP

TRKSTOP:
	ld a,00h
	LD (VOLUME),A
	LD A,000H	;force min volume in left & right chan
	LDS (NR50),A

	XOR A
	LD (STATUS),A	;force STATUS=0
	LD D,A
	LD E,A
	CALL KILLS	;kill channel 1
	LD DE,SDLN
	CALL KILLS	;kill channel 2
	LD DE,2*SDLN
KILLS:	LD HL,VCEMUTE	;kill channel 3
	ADD HL,DE
	BIT 7,(HL)
	LD (HL),0FFH
	RET NZ	;still effects
	LD HL,ENVAL+1
	ADD HL,DE
	XOR A
	LD (HL),A	;no effects, so ENVAL+1=0
	LD HL,CTRLAD
	ADD HL,DE
	LD (HL),A	;& CTRLAD=0
	RET

TRKLOOP:	LD (HL),0
	CALL READTK

SEQREAD:	ADD A,A	;word table
	LD C,A	;A = SEQNUM
	LD B,0
	JR NC,SEQREAD1
	LD B,1	;for seq 80h or greater
SEQREAD1:	LD A,(SEQOFF)	;get lo byte of offset table address
	ADD A,C	;add seqnumber*2
	LD L,A	;store result, low
	LD A,(SEQOFF+1)	;get hi byte of address
	ADC A,B	;add carry only
	LD H,A	;HL points to word in offset table
	LD A,(SEQDATA)	;get low byte of SEQDATA address
	ADD A,(HL)	;add offset for this sequence
	LD C,A
	LD A,(SEQDATA+1)
	INC HL
	ADC A,(HL)
	LD B,A	;BC=address of 1st byte of sequence

	LD HL,SEQSTEP
	ADD HL,DE
	LD A,(HL)	;A = seqstep for this channel
	cp 0
	jr nz,seqread2
	ld hl,THRESHOLD
	add hl,de
	ld (hl),0FFh	;reset THRESHOLD to 0FFh at start
seqread2:	ADD A,C
	LD C,A
	ADC A,B
	SUB C
	LD B,A	;BC points to sequence byte

	LD A,0FFH
	LD (VCETEMP),A	;VCETEMP=0ffh
	LD HL,GATEMASK
	ADD HL,DE
	LD (HL),A	;GATEMASK=0ffh
	LD HL,BENDBYTE
	ADD HL,DE
	LD (HL),0	;set BENDBYTE=0
	LD HL,ATTKEND
	ADD HL,DE
	LD (HL),0	;set ATTKEND=0
	ld hl,TIED_NOTE
	add hl,de
	ld (hl),0	;set TIED_NOTE=0

newpair:	LD A,(BC)	;get next sequence byte
	BIT 7,A
	JR Z,NOTEREAD	;bpl
	INC BC	;ready for 2nd byte in pair

param80:	cp 080h	;voice change
	jr nz,param81
	ld a,(bc)
	ld (VCETEMP),a	;VCETEMP was = 0ffh
	jp paramexit

param81:	cp 081h	;rest
	jr nz,param82
	ld hl,GATEMASK
	add hl,de
	ld (hl),0feh	;release & fade
	ld hl,TIED_NOTE
	add hl,de
	ld (hl),0ffh
	jp duraread


param82:	cp 082h	;bend
	jr nz,param83
	ld a,(bc)
	ld hl,BENDBYTE
	add hl,de
	ld (hl),a
	jp paramexit

param83:	cp 083h	;tempo
	jr nz,param84
	ld a,(bc)
	LD hl,TEMPOVAL
	LD (hl),A	;temp fixed value
	jp paramexit

param84:	cp 084h	;tied
	jr nz,param85
	ld hl,TIED_NOTE
	add hl,de
	ld (hl),0ffh
	jp paramexit

param85:	cp 085h	;gate
	jr nz,param86
	ld a,(bc)
	ld hl,THRESHOLD
	add hl,de
	ld (hl),a
	jp	paramexit
	
param86:	cp 086h	;global offset
	jr nz,paramexit
	ld a,(bc)
	ld hl,GLOBOFFSET
	ld (hl),a


paramexit:	inc bc	;ready for note
	ld hl,seqstep	;HL=seqstep for this channel
	add hl,de
	inc (hl)
	inc (hl)	;add 2 to SEQSTEP
	jp newpair


NOTEREAD:	LD HL,NOTEVALUE
	ADD HL,DE
	LD (HL),A	;save notevalue
	INC BC

DURAREAD:	LD A,(BC)	;get next sequence byte
	ld hl,DURATION
	ADD HL,DE
	LD (HLD),A
	LD (HL),0	;NOTELENGTH=0
	LD HL,SEQSTEP	;HL=seqstep for this channel
	ADD HL,DE
	INC	(HL)
	INC	(HL)	;ADD 2 TO SEQSTEP
	INC BC
	PUSH BC	;save seq address for READEND

;-----------------------------------------------------------------------------
	LD HL,VCEMUTE	;Check for effect in this channel
	ADD HL,DE
	BIT 7,(HL)
	JR Z,NEWSTART	;no effects
	LD HL,SFXHOLD
	ADD HL,DE
	LD A,(HL)
	AND A
	JR NZ,NEWSTART	;still effects in critical portion
	LD HL,TIED_NOTE
	ADD HL,DE
	LD (HL),A	;past critical - force tie off

;-----------------------------------------------------------------------------
NEWSTART:	LD A,(VCETEMP)
	BIT 7,A
	JR NZ,MODREAD	;0ffh= no new voice
	LD HL,VOICENUM
	ADD HL,DE
	CP (HL)	;existing voice
	JR Z,MODREAD	;ignore if same voice
	LD (HL),A	;save new voice
	LD HL,TIED_NOTE
	ADD HL,DE
	LD (HL),A	;and force envelope restart

MODREAD:	LD HL,TIED_NOTE
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,READEND	;tied note - ignore new mods

	LD HL,VOICENUM
	ADD HL,DE
	ld l,(hl)
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl	;16 bytes each voice
	ld c,l
	ld b,h	;move to bc (=0000 to 01F0)
	LD HL,VOICEOFFSET
	ADD HL,DE
	LD (HL),c	;save offset to this voice
	inc hl
	ld (hl),b

	XOR A	;atkdec
	CALL GETVOICE
	LD (ADTEMP),A
	INC BC
	LD A,(BC)	;susrel
	LD (SRTEMP),A
	INC BC
	LD A,(BC)	;wvefrm
	LD HL,NOTECTRL
	ADD HL,DE
	LD (HL),A
	INC BC
	LD A,(BC)	;specls
	LD HL,SPECIAL
	ADD HL,DE
	LD (HL),A
	inc bc
	ld a,(bc)	;stereo
	ld (STEREOTEMP),a
	ld hl,TRANSPOSE
	add hl,de
	inc bc
	ld a,(bc)
	ld (hl),a	;offset (TRANSPOSE)
	inc bc
	ld a,(bc)
	ld (pktemp),a	;ATKLVL
	INC BC
	ld hl,SPECNTDN
	add hl,de
	LD A,(BC)	;atkcnt
	LD (HL),A
	LD A,15	;vdelay
	CALL GETVOICE
	LD HL,VIBDELAY
	ADD HL,DE
	LD (HL),A

;-----------------------------------------------------------------------------
	LD HL,SFXHOLD	;any effect on ?
	ADD HL,DE
	LD A,(HL)
	AND A
	JR NZ,READEND	;yes, so ignore
	
	LD HL,VCEMUTE
	ADD HL,DE
	LD (HL),A	;else clear any mute
	LD HL,ENAD
	ADD HL,DE
	LD A,(ADTEMP)
	LD (HLI),A	;music ADTEMP to ENAD
	LD A,(SRTEMP)
	LD (HLI),A	;music SRTEMP to ENSR
	ld a,(PKTEMP)
	swap a
	and 0F0h
	or 08h
	ld (hl),a	;music PKTEMP to ATKLVL
	ld a,(STEREOTEMP)
	and 11h	;L/R bits only
	ld hl,STEREO
	add hl,de
	ld (hl),a	;music STEREOTEMP to STEREO

;-----------------------------------------------------------------------------
READEND:
	ld hl,NOTEVALUE
	add hl,de
	ld a,(hl)	;get notevalue
	push hl
	ld hl,TRANSPOSE
	add hl,de
	add a,(hl)

	LD HL,SPECIAL
	ADD HL,DE
	LD C,(HL)
	bit 7,c		;special (fixed)
	jr nz,rdend2

	ld hl,GLOBOFFSET
	add a,(hl)
rdend2:	pop hl
	ld (hl),a	;save transposed notevalue

	ld hl,NOTE	;find freq word value for this note
	add hl,de
	inc hl	;high byte of note
	ADD A,A	;word table access
	ADD A,NOTETABLE+1 AND 255
	LD C,A
	ADC A,(NOTETABLE+1)/256
	SUB C
	LD B,A
	LD A,(BC)
	LD (HLD),A	;save high byte of NOTE
	DEC BC
	LD A,(BC)
	LD (HL),A	;save low byte of NOTE

	POP BC	;retrieve (zseq)
	LD A,(BC)	;look at next byte
	INC A	;0ffh to 0
	JR NZ,READEXIT
	LD HL,SEQSTEP	;end of sequence
	ADD HL,DE
	LD (HLI),A	;SEQSTEP=0
	INC HL
	DEC (HL)	;seqrepeat
	CALL Z,READTK

READEXIT:	LD HL,VCEMUTE
	ADD HL,DE
	LD A,(HL)
	AND A
	JP NZ,NEXTCHAN	;effect, so ignore other music code
	LD HL,SPECNTUP
	ADD HL,DE
	LD (HL),A
	PUSH HL
	LD HL,VIBSPEED
	ADD HL,DE
	LD (HL),A
	POP HL
	DEC HL
	DEC HL
	LD C,(HL)	;C=SPECIAL
	INC HL
	JP spec40


TREATMENT:	LD HL,VCEMUTE
	ADD HL,DE
	BIT 7,(HL)
	JP NZ,NEXTCHAN	;ignore all treatment if sound effect

vibrato:	LD HL,VIBDELAY
	ADD HL,DE
	LD A,(HL)
	AND A
	JR Z,vib2	;delay finished, so test for vibrato
	DEC (HL)
	JP bending

vib2:	LD HL,SPECNTDN
	ADD HL,DE
	OR (HL)
	JP NZ,bending
	LD A,14	;vibrto
	CALL GETVOICE
	AND A
	JP Z,bending
	LD C,A
	LD HL,VIBSPEED
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,vib4

	LD B,0
	LD HL,VIBTB1
	ADD HL,BC
	LD A,(HL)
	LD HL,VIBLIMIT
	ADD HL,DE
	LD (HLD),A
	XOR A
	LD (HLD),A
	LD (HLD),A
	PUSH HL
	LD HL,VIBTB2
	ADD HL,BC
	LD A,(HL)
	POP HL
	LD (HL),A

	LD HL,NOTEVALUE
	ADD HL,DE
	LD A,(HL)
	ADD A,A
	ADD A,NOTETABLE AND 255
	LD L,A
	ADC A,NOTETABLE/256
	SUB L
	LD H,A
	LD C,(HL)
	INC HL
	LD B,(HL)
	INC HL
	PUSH HL
	LD HL,NOTE
	ADD HL,DE
	LD (HL),C
	INC HL
	LD (HL),B
	POP HL
	LD A,(HLI)
	SUB C
	LD C,A
	LD A,(HL)
	SBC A,B
	LD B,A
	LD HL,VIBINC
	ADD HL,DE
	LD (HL),C
	INC HL
	LD (HL),B

vibloop1:	LD HL,VIBSPEED
	ADD HL,DE
	DEC (HL)
	BIT 7,(HL)
	JR NZ,bending
	LD HL,VIBINC+1
	ADD HL,DE
	SRL (HL)
	DEC HL
	RR (HL)
	JR vibloop1

vib4:	LD HL,FREQDIR
	ADD HL,DE
	BIT 7,(HL)
	LD HL,VIBINC
	ADD HL,DE
	JR NZ,vib5
	LD A,(HLI)
	LD B,(HL)
	INC HL
	ADD A,(HL)
	LD (HLI),A
	LD A,B
	ADC A,(HL)
	JR vib6

vib5:	LD C,(HL)
	INC HL
	LD B,(HL)
	INC HL
	LD A,(HL)
	SUB C
	LD (HLI),A
	LD A,(HL)
	SBC A,B

vib6:	LD (HL),A
	LD HL,VIBDIR
	ADD HL,DE
	BIT 7,(HL)
	INC HL
	JR NZ,vib7
	INC (HL)
	LD A,(HLI)
	CP (HL)
	JR C,bending
	DEC HL
	DEC HL
	LD (HL),0FFH
	DEC HL
	DEC HL
	DEC HL
	LD A,(HL)
	CPL
	LD (HL),A
	JR bending

vib7:	DEC (HL)	;vib7
	JR NZ,bending
	DEC HL
	LD (HL),0


bending:	LD HL,BENDBYTE	;bending
	ADD HL,DE
	LD A,(HL)
	AND A
	JR Z,specials
	CP 080H
	JR NC,bending2

	LD HL,NOTE	;bend up
	ADD HL,DE
	ADD A,(HL)
	LD (HLI),A
	JR NC,specials
	INC (HL)
	JR specials

bending2:	AND 07FH	;bend down
	LD C,A
	LD HL,NOTE
	ADD HL,DE
	LD A,(HL)
	SUB C
	LD (HLI),A
	JR NC,specials
	DEC (HL)


specials:	LD HL,SPECIAL
	ADD HL,DE
	LD C,(HL)
	INC HL
	INC HL
	bit 0,c		;arpeggio
	jr z,spec02
	ld a,(hl)	;specntup
	and 07h
	rr a
	jp spec20a


spec02:	BIT 1,C	;trill note
	JR Z,spec04
	PUSH BC
	PUSH HL
	BIT 0,(HL)	;specntup
	JR NZ,spec02b
	LD HL,NOTEVALUE
	ADD HL,DE
	LD A,(HL)
	JR spec02c
spec02b:	LD A,13	;trlnote
	CALL GETVOICE
	BIT 7,A
	JR Z,spec02c
	AND 07FH
	LD HL,NOTEVALUE
	ADD HL,DE
	ADD A,(HL)
spec02c:	ADD A,A
	ADD A,NOTETABLE AND 255
	LD C,A
	ADC A,NOTETABLE/256
	SUB C
	LD B,A
	LD HL,NOTE
	ADD HL,DE
	LD A,(BC)
	LD (HLI),A
	INC BC
	LD A,(BC)
	LD (HL),A
	POP HL
	POP BC


spec04:	BIT 2,C		;drum
	JR Z,spec08
	PUSH BC
	PUSH HL
	BIT 0,(HL)	;specntup
	JR NZ,spec04b
	LD A,2	;wvefrm
	CALL GETVOICE
	JR spec04c
spec04b:	LD A,081H
spec04c:	LD HL,NOTECTRL	;noise/ normal waveform alternately
	ADD HL,DE
	LD (HL),A
	LD HL,NOTELENGTH
	ADD HL,DE
	LD A,(HL)
	CP 02H
	JR C,spec04d
	LD HL,GATEMASK	;gate drums off after duration 2
	ADD HL,DE
	LD (HL),0FEH
spec04d:
	LD HL,NOTE+1	;freq decay
	ADD HL,DE
	DEC (HL)
	BIT 7,(HL)
	JR Z,spec04e
	INC (HL)
spec04e:
	POP HL
	POP BC


spec08:	BIT 3,C		;spec08 (chord)
	JR Z,spec08b
	LD A,(HL)	;specntup
	AND 03h
	JR spec20a
spec08b:	DEC HL


spec40:	BIT 6,C		;drumbend
	JR  Z,spec10
	PUSH BC
	PUSH HL
	LD A,9		;note1
	CALL GETVOICE
	ld hl,BENDBYTE
	add hl,de
	ld (hl),a	;save drumbend value to bendbyte
	POP HL
	POP BC


spec10:	BIT 4,C		;atkwave
	JR Z,spec20
	PUSH BC
	PUSH HL
	LD A,(HL)	;SPECNTDN
	AND A
	JR Z,spec10b
	LD A,8		;atkwave
	JR spec10c
spec10b:
	LD HL,ATTKEND	;1 frame after attack
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,spec10d
	LD A,2		;waveform
spec10c:
	CALL GETVOICE
	LD HL,NOTECTRL
	ADD HL,DE
	LD (HL),A
spec10d:
	POP HL
	POP BC


spec20:	BIT 5,C		;atknote
	JR Z,finalbit
	LD A,(HLI)	;specntdn
	AND A
	JR Z,spec20c
	LD A,(HL)
spec20a:
	ADD A,9		;chord note 0/1/2/3 to note1/2/3/4
	CALL GETVOICE
	LD HL,NOTEVALUE
	ADD HL,DE
	BIT 7,A
	JR Z,spec20d
	AND 07FH
	CP 040H
	JR NC,spec20b
	ADD A,(HL)
	JR spec20d

spec20b:
	AND 03FH
	LD C,A
	LD A,(HL)
	SUB C
	JR spec20d

spec20c:
	LD HL,ATTKEND	;1 frame after attack
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,finalbit
	LD HL,NOTEVALUE	;restore proper note
	ADD HL,DE
	LD A,(HL)

spec20d:
	ADD A,A
	ADD A,NOTETABLE AND 255
	LD L,A
	ADC A,NOTETABLE/256
	SUB L
	LD H,A
	LD C,(HL)
	INC HL
	LD B,(HL)
	LD HL,NOTE
	ADD HL,DE
	LD (HL),C
	INC HL
	LD (HL),B


;-----------------------------------------------------------------------------
finalbit:	ld hl,NOTELENGTH	;check gate
	add hl,de
	ld a,(hl)
	ld hl,THRESHOLD
	add hl,de
	cp (hl)
	jr nz,final0
	ld hl,GATEMASK	;end of gated note
	add hl,de
	ld (hl),0FEH	;release and fade

final0:	LD HL,TIED_NOTE
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,SL200	;tied, so ignore new gate
	LD HL,SPECNTUP
	ADD HL,DE
	LD A,(HL)
	AND A	;set flags only
	JR NZ,SL200	;not 1st frame of this note

	ld a,(CURCHAN)	;STEREO (1st frame only)
	inc a
	ld c,a	;C=1,2,3 (current channel+1)
	ld hl,stereo
	add hl,de
	ld a,(hl)
	ld b,0EEh
	dec c
	jr z,SL190	;channel 1
	add a,a	;11h to 22h
	ld b,0DDh
	dec c
	jr z,SL190	;channel 2
	add a,a	;channel 3   (22h to 44h)
	ld b,0BBh

SL190:	ld c,a	;C=stereo bits
	lds a,(NR51)	;get assignment
	and b	;mask out this channel
	or c		;add stereo for this channel
	lds (NR51),a

	LD A,0FEH
	JR SL210
SL200:	LD A,0FFH	;final0
SL210:	LD HL,NOTECTRL
	ADD HL,DE
	AND (HL)
	LD HL,GATEMASK
	ADD HL,DE
	AND (HL)
	LD HL,CTRLAD
	ADD HL,DE
	LD (HL),A	;NOTECTRL  to CTRLAD

	LD HL,NOTE	;transfer NOTE (music data)
	ADD HL,DE
	LD C,(HL)
	INC HL
	LD B,(HL)
	LD HL,FREQ	;to FREQ (overwrites effects data)
	ADD HL,DE
	LD (HL),C
	INC HL
	LD (HL),B

	LD HL,SPECNTDN
	ADD HL,DE
	LD A,(HL)
	AND A
	JR NZ,final1
	PUSH HL
	LD HL,ATTKEND
	ADD HL,DE
	LD (HL),0FFH
	POP HL
	JR final2
final1:	DEC (HL)	;SPECNTDN
final2:	INC HL
	INC (HL)	;SPECNTUP


;-----------------------------------------------------------------------------
NEXTCHAN:	LD HL,SDLN
	ADD HL,DE
	LD D,H
	LD E,L
	LD HL,CURCHAN
	INC (HL)
	LD A,(HL)
	CP 3
	JP C,MUSICLOOP

	RET


;-------------------------------------------------------------------------------
READTK:	LD HL,TRACK	;read track
	ADD HL,DE
	LD A,(TRKDAT)	;get TRKDATA address
	ADD A,(HL)
	LD C,A
	INC HL
	LD A,(TRKDAT+1)
	ADC A,(HL)
	LD B,A
	PUSH BC
	LD HL,TRKSTEP
	ADD HL,DE
	INC (HL)
	LD A,(HL)
	ADD A,C
	LD C,A
	ADC A,B
	SUB C
	LD B,A

readt0:	LD A,(BC)
	CP 0FDH
	JR C,readt1
	JR Z,readfade
	PUSH HL	;trkstep
	LD HL,SEQNUM
	ADD HL,DE
	LD (HL),A
	POP HL	;trkstep
	INC BC
	LD A,(BC)
	DEC A
	LD (HL),A
	INC A
	POP BC
	RET

readfade:	INC (HL)
	INC BC
	LD A,(BC)
	LD (FADER),A
RT30:	INC (HL)
	INC BC
	JR readt0

readt1:	BIT 6,A
	JR Z,RT80
	PUSH HL

	LD HL,LOOPFLAG	;readl0
	ADD HL,DE
	BIT 7,(HL)
	JR NZ,readl1

	LD (HL),0FFH
	AND 03FH
	INC HL
	LD (HL),A
	POP HL
	INC (HL)
	LD A,(HL)
	INC BC
	PUSH HL
	LD HL,LOOPMEM
	ADD HL,DE
	LD (HL),A
	POP HL
	JR readt2

readl1:	INC HL
	DEC (HL)
	JR NZ,readl2
	DEC HL
	LD (HL),0
	POP HL
	JR RT30

readl2:	INC HL
	LD A,(HL)
	POP HL
	LD (HL),A
	POP BC
	PUSH BC
	ADD A,C
	LD C,A
	ADC A,B
	SUB C
	LD B,A

readt2:	LD A,(BC)
RT80:	INC (HL)	;trkstep
	LD HL,SEQREPEAT
	ADD HL,DE
	LD (HL),A	;store seqrepeat

	INC BC
	LD A,(BC)
	DEC HL
	LD (HL),A	;seqnumber
	POP BC
	RET


;-------------------------------------------------------------------------------
;Enter with A = parameter 00 -0Fh
;Exit with A = voice data byte required
;BC = address of voice data byte
;-------------------------------------------------------------------------------
GETVOICE:	LD HL,VOICEOFFSET
	ADD HL,DE
	ADD A,(HL)	;offset for current voice 0000-01F0
	inc hl
	ld b,(hl)	;save high byte for later
	LD HL,VCEBANK	;point to voice bank data
	ADD A,(HL)
	LD C,A	;C=low byte of address required
	INC HL
	ld a,b	;retrieve high byte of voiceoffset
	ADC A,(HL)
	LD B,A	;B= high byte of address required
	LD A,(BC)	;A=voice byte required
	RET




;-------------------------------------------------------------------------------
;START OF ROM DATA
;-------------------------------------------------------------------------------

ADRTABLE:	DW 61440,61440,30720,15360 ;envelope times
		DW 10240,7680,6144,5120
		DW 4096,1661,842,526
		DW 418,140,84,53

VIBTB1:		DB 0,1,1,1,1,4,3,2
		DB 4,3,2,1,3,2,1,3,2,2,1
VIBTB2:		DB 0,5,4,3,2,5,5,4
		DB 4,4,3,1,3,2,0,1,1,0,0
NOTETABLE:	dw 000h,000h,000h,000h,000h,000h	;C-2 00h (too low)
		dw 000h,000h,000h,000h,000h,000h
		dw 000h,000h,000h,000h,000h,000h	;C-1 0Ch (too low)
		dw 000h,000h,000h,000h,000h,000h
		dw 000h,000h,000h,000h,000h,000h	;C0 18h (too low)
		dw 000h,000h,000h,000h,000h,000h
		dw 02Ch,09Ch,107h,16Bh,1C9h,223h	;C1 24h 65Hz
		dw 277h,2C7h,312h,358h,39Bh,3DAh
		dw 416h,44Eh,483h,4B5h,4E5h,511h	;C2 30h 130Hz
		dw 53Bh,563h,589h,5ACh,5CEh,5EDh
		dw 60Bh,627h,642h,65Bh,672h,689h	;C3 3Ch 262Hz(MID)
		dw 69Eh,6B2h,6C4h,6D6h,6E7h,6F7h
		dw 706h,714h,721h,72Dh,739h,744h	;C4 48h 523Hz
		dw 74Fh,759h,762h,76Bh,773h,77Bh
		dw 783h,78Ah,790h,797h,79Dh,7A2h	;C5 54h 1046Hz
		dw 7A7h,7ACh,7B1h,7B6h,7BAh,7BEh
		dw 7C1h,7C5h,7C8h,7CBh,7CEh,7D1h	;C6 60h 2093Hz
		dw 7D4h,7D6h,7D9h,7DBh,7DDh,7DFh
		dw 7E1h,7E2h,7E4h,7E6h,7E7h,7E9h	;C7 6Ch 4186Hz
		dw 7EAh,7EBh,7ECh,7EDh,7EEh,7EFh
		dw 7F0h,7F1h,7F2h,7F3h,7F4h,7F4h	;C8 78h 8372Hz
		dw 7F5h,7F6h			;G8 7Fh 12542Hz

CODESIZE	equ $-JUMPTABLE

;*****************************************************************************
		ORG 1200h

GAMEDAT1:	INCLUDE BLANK-GB.SND (BIN)	;7 WORD VECTOR TABLE @ START
;*****************************************************************************

MUSICEND:


;-------------------------------------------------------------------------------
;DRIVER RAM VARIABLES
;-------------------------------------------------------------------------------
		ORG	MUSICRAM

MUSICVAR:
sfxno		DS	1
tuneno		DS	1
STATUS:		DS	1

;-----------------------------------------------------------------------------
SFXCHAN1	DS	1
PRIORTEST	DS	1
SFXHOLD		DS	1
SFXCHOP		DS	1
CTRLAD		DS	1 ;current waveform for music/effects
CTRLSR		DS	1
FREQ		DS	2
BENDTYPE	DS	1
BEND		DS	2
SFXEXTRA:	DS	1
CNTDOWN:	DS	1
CNTVAL:		DS	1
NEWVAL:		DS	1
NEWVAL2		DS	1
PRIORITY:	DS	1
DIRFLAG:	DS	1

ENAD:		DS	1
ENSR:		DS	1
ATKLVL		DS	1 ;08-F8 peak attack level (forced to F8 if effect)
ATKHOLD:	DS	1
ENSEQ:		DS	1 ;0=attack/1=decay/2=sustain phase
ENVAL:		DS	2 ;envelope value (high nibble is current envelope level)
FQOFF:		DS	1 ;freqoffset: 0 if music/ 8 if effect (00-0F for waver)

TRACK:		DS	2
VOICEOFFSET:	DS	2
TRKSTEP:	DS	1
LOOPFLAG:	DS	1
LOOPCNTR:	DS	1
LOOPMEM:	DS	1
SEQSTEP:	DS	1
SEQNUM:		DS	1
SEQREPEAT:	DS	1
NOTELENGTH:	DS	1 ;0 at start of each note/increases as DURATION decreases
DURATION:	DS	1
NOTECTRL:	DS	1
NOTEVALUE:	DS	1
ATTKEND:	DS	1 ;0 at start of each note
VOICENUM:	DS	1
GATEMASK:	DS	1
BENDBYTE:	DS	1
FREQDIR:	DS	1
VIBDELAY:	DS	1
VIBSPEED:	DS	1
VIBDIR:		DS	1
VIBSTEP:	DS	1
VIBLIMIT:	DS	1
VIBINC:		DS	2
NOTE:		DS	2
TIED_NOTE:	DS	1
SPECIAL:	DS	1
SPECNTDN:	DS	1
SPECNTUP:	DS	1
STEREO		DS	1
TRANSPOSE	DS	1
THRESHOLD	DS	1	;sets length before gate off (init to $FF)


VCEMUTE:	DS	1

SDLN		equ	$-SFXCHAN1
		DS	2*SDLN	;3 channels for each

FADER:		DS	1
VOLUME:		DS	1
FADECNT:	DS	1
TEMPOVAL:	DS	1
TEMPOFLAG:	DS	1
TEMPOCNTR:	DS	1
VCETEMP:	DS	1
ADTEMP:		DS	1
SRTEMP:		DS	1
PKTEMP		DS	1
STEREOTEMP	DS	1
GLOBOFFSET	DS	1
CLOCK_L		DS	1
CLOCK_H		DS	1


NCHAN:		DS	1 ;current noise channel 0,1,2 (FF=no noise)
CURCHAN:	DS	1 ;current channel
SEED:		DS	1 ;for random number
ENC3:		DS	1 ;envelope value for channel 3
MAXVOL:		DS	1 ;maximum envelope attack value
EFFSND		DS	1 ;FF=effect in current channel


FXBANK:		DS	2 ;address of 1st byte of effects
FXTABLE:	DS	2 ;address of 1st byte of call table
VCEBANK:	DS	2
SEQOFF:		DS	2
SEQDATA:	DS	2
TRKOFF:		DS	2
TRKDAT:		DS	2

VARSIZE		equ	$-MUSICVAR




;-------------------------------------------------------------------------------
;DEMO RAM VARIABLES
;-------------------------------------------------------------------------------
		IF DEMO
CNT1		DS	1
TRG1		DS	1
editnum		DS	1
selectflag	DS	1
vbi_flag	DS	1
PCnewdata	ds	1
PCbuffer	ds	24	;6 + (6 * 3)
		ENDIF

		END
