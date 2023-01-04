;======================================================================

	;Install SBIOS and secondary bootstrap
	ORG	0

INSTALL	LD	HL,0		;Originally a vector to CCP in CP/M
				;Patched by the HD boot sector
				;to a LDIR routine in the boot sector
	LD	A,H		;here we test if it was patched
	OR	L		;
	JR	Z,INSTAL0	;Go if not
	PUSH	HL		;save jump address
	PUSH	HL		;
	POP	IX		;copy to IX
	LD	(IX+0BH),0C9H	;put a RET at end of the LDIR routine
	LD	HL,(0006H)	;get BDOS entry point
	LD	DE,INSTAL0-0806H;adjust to INSTAL0 effective address
	ADD	HL,DE		;
	EX	(SP),HL		;push return address; pop LDIR routine
	JP	(HL)		;go to LDIR routine

INSTAL0	; Move UCSD Secondary bootstrap to 8200H
	LD	HL,(0001H)	;get BIOS base address
	LD	L,0		;
	PUSH	HL		;copy to IX
	POP	IX		;
	LD	DE,BIAS-CBIOS	;adjust to UCSD sec bootstrap address
	ADD	HL,DE		;
	PUSH	HL		;save it
	LD	DE,8200H	;dest address for sec bootstrap
	LD	BC,0800H	;length of sec bootstrap
	LDIR			;move sec bootstrap

	;HALT

	POP	HL		;restore address
	; Relocate addresses in this primary bootstrap
	DEC	H		;point to this page
	LD	L,TFIXUP	;point to FIXUP table
	LD	C,H		;offset high byte to C
INSTAL1	LD	E,(HL)		;get FIXUP address from table
	INC	HL		;
	LD	D,(HL)		;
	INC	HL		;
	LD	A,D		;check if end of table (0000H)
	OR	E		;
	JR	Z,XINST1	;exit loop if yes
	EX	DE,HL		;swap HL and DE
	LD	A,H		;adjust FIXUP address
	ADD	A,C		;
	LD	H,A		;
	LD	A,(HL)		;adjust value high byte
	ADD	A,C		;
	LD	(HL),A		;
	EX	DE,HL		;swap back HL and DE
	JR	INSTAL1		;loop again
XINST1	;HALT			;loop exits here
	LD	L,A		;clear L (A==0)
	LD	A,C		;adjust to SBIOS address
	ADD	A,16H-HIGH SBIOSSZ
	LD	H,A		;HL = SBIOS address
	LD	B,30		;number of jump vectors
INSTAL2	INC	HL		;loop over jump vectors
	INC	HL		;
	LD	A,(HL)		;
	ADD	A,C		;adjust jump vector
	LD	(HL),A		;
	INC	HL		;
	DJNZ	INSTAL2		;loop until all jumps are done

	;HALT
	LD	BC,0		;select drive 0 and
	CALL	SETDISK		;  get drive parameters
FIXUP24	EQU	$-1		;


;======================================================================

	;0EB80H init
BOOT	EQU	8200H		; SECONDARY BOOTSTRAP LOADED HERE
MSIZE	EQU	64		; MEMORY SIZE FOR ASSEMBLY
BIAS	EQU	(MSIZE*1024)-02B00H
CBIOS	EQU	1500H+BIAS	; ORIGIN POINT
CPMB	EQU	-0100H+BIAS	; BASE OF CCP

PBOOT	;HALT
	; push secondary bootstrap parameters
	LD	DE,-SBIOSSZ	;
	ADD	IX,DE
	LD	SP,IX		; RESET THE STACK

	LD	HL,128		; MAXIMUM NUMBER OF BYTES PER SECTOR
	PUSH	HL		;
	LD	HL,128		; MAXIMUM NUMBER OF SECTORS IN TABLE
	PUSH	HL		;
	LD	HL,0		; TRACK-TO-TRACK SKEW
	PUSH	HL		;
	LD	HL,1		; FIRST INTERLEAVED TRACK
	PUSH	HL		;
	LD	HL,1		; 2:1 INTERLEAVING
	PUSH	HL		;
	LD	HL,128		; BYTES PER SECTOR
	PUSH	HL		;
	LD	HL,(DSKSECS)	; SECTORS PER TRACK
FIXUP25	EQU	$-1
	PUSH	HL		;
	LD	HL,(DSKTRKS)	; TRACKS PER DISK
FIXUP26	EQU	$-1		;
	PUSH	HL		;
	PUSH	IX		; TOP OF MEMORY (MUST BE WORD BOUNDARY)
	POP	HL		;
	DEC	HL		;
	DEC	HL		;
	PUSH	HL		;
	LD	HL,0100H	; BOTTOM OF MEMORY
	PUSH	HL		;
	PUSH	IX		; START OF THE SBIOS (JMP WBOOT)
	POP	DE		;
	PUSH	DE		;
	PUSH	HL		; STARTING ADDRESS OF INTERPRETER

	; display welcome message
BOOT1	LD	HL,BOOTMSG	;welcome message
FIXUP01	EQU	$-1		;address of sec bootstrap MSB to fix
	LD	DE,BOOT		;load 8200H sec bootstrap addr
	PUSH	DE		;push it
OUTMSG	LD	A,(HL)		;get char from message
	CP	'$'		;'$' as terminator ?
	RET	Z		;go to sec bootstrap if yes
	LD	C,A		;move char to C
	PUSH	HL		;save message ptr
	CALL	CONOUT		;call CONOUT
FIXUP02	EQU	$-1		;address of CONOUT to fix
	POP	HL		;restore message ptr
	INC	HL		;bump it
	JR	OUTMSG		;display next char

TFIXUP	DW	FIXUP01, FIXUP02, FIXUP03, FIXUP04
	DW	FIXUP05, FIXUP06, FIXUP07, FIXUP08
	DW	FIXUP09, FIXUP10, FIXUP11, FIXUP12
	DW	FIXUP13, FIXUP14, FIXUP15, FIXUP16
	DW	FIXUP17, FIXUP18, FIXUP19, FIXUP20
	DW	FIXUP21, FIXUP22, FIXUP23, FIXUP24
	DW	FIXUP25, FIXUP26, FIXUP27, FIXUP28
	DW	FIXUP29, FIXUP30, FIXUP31, FIXUP32
	DW	FIXUP33, FIXUP34
	DW	0

;======================================================================

SBIOSSZ	EQU	0200H		; SBIOS extension size

	ORG	1500H-SBIOSSZ	;1 page below SBIOS
BOOTMSG	DB	10,'UCSD Bootstrap Loader - ExtSBIOS v0.95'
	DB	' - Copyright (C) 2020 by GmEsoft',13,10
	DB	10,'Booting to UCSD Pascal ...',13,10,'$'

;======================================================================
	ORG	1600H-SBIOSSZ	;2 pages below CBIOS

;-----	SBIOS jump vectors
SBIOS	EQU	$
	JP	SYSINIT		;SYSINIT saves callback vector
	JP	SYSHALT		;SYSHALT stops system
	JP	CONINIT		;CONINIT does nothing
	JP	CONST		;CONSTAT to CBIOS
	JP	CONIN		;CONREAD to CBIOS
	JP	CONOUT		;CONWRIT to CBIOS
	JP	SETDISK		;SETDISK call CBIOS SELDSK and update params
	JP	SETTRAK		;SETTRAK to CBIOS
	JP	SETSECT		;SETSECT dec BC then to CBIOS
	JP	SETBUFR		;SETBUFR call CBIOS SETDMA and clear B
	JP	DSKREAD		;DSKREAD check disk then to CBIOS
	JP	DSKWRIT		;DSKWRIT check disk then to CBIOS
	JP	DSKINIT		;DSKINIT
	JP	DSKSTRT		;DSKSTRT
	JP	DSKSTOP		;DSKSTOP
;-----	Extended SBIOS jump vectors
	JP	PRNINIT		;PRNINIT
	JP	PRNSTAT		;PRNSTAT
	JP	PRNREAD		;PRNREAD
	JP	PRNWRIT		;PRNWRIT
	JP	REMINIT		;REMINIT
	JP	REMSTAT		;REMSTAT
	JP	REMREAD		;REMREAD
	JP	REMWRIT		;REMWRIT
	JP	USRINIT		;USRINIT
	JP	USRSTAT		;USRSTAT
	JP	USRREAD		;USRREAD
	JP	USRWRIT		;USRWRIT
	JP	CLKREAD		;CLKREAD

;-----	Callback vectors
CALBACK	EQU	$
POLUNTS	JP	JPRET		;POLLUNITS
DSKCHNG	JP	JPRET		;DSKCHNG

;-----	System Initialization
SYSINIT	;HALT
	LD	H,B		;Callback base address
	LD	L,C		;
	LD	DE,CALBACK	;Destination address
FIXUP10	EQU	$-1		;
	LD	BC,6		;
	LDIR			;Copy jump statements
	LD	(DSKDPH),BC	;initialize DPH to 0
FIXUP27	EQU	$-1		;
	RET			;done

;-----	System Shutdown
SYSHALT	HALT			;Halt CPU
	JR	SYSHALT		;Loop forever

;-----	Dummy routines
PRNSTAT:
	;HALT
PRNREAD:
REMSTAT:
CONINIT:			;Console Initialization
DSKINIT:			;Disk Drive Initialization/Start
DSKSTRT:			;Disk Drive Initialization/Start
DSKSTOP	XOR	A		;Disk Drive Stop
	LD	C,A		;no input char
JPRET	RET			;done

;-----	Write char to printer
PRNWRIT	LD	A,C		;don't print NUL chars
	OR	A		;
	RET	Z		;
	CALL	LISTOUT		;call CBIOS LISTOUT
FIXUP28	EQU	$-1		;
PRNINIT	XOR	A		;ret IOSTATUS OK
	RET			;

;-----	Init serial interface
REMINIT	LD	HL,REMSTAT	;push return address
FIXUP33	EQU	$-1		;
	PUSH	HL		;
	LD	HL,(SPB+22)	;Serial Port DCB
FIXUP31	EQU	$-1		;
	JP	(HL)		;Init serial port

;-----	Read char from serial
REMREAD	CALL	READER		;call CBIOS READER
FIXUP29	EQU	$-1		;
	XOR	A		;ret IOSTATUS OK
	RET			;

;-----	Write char to serial
REMWRIT	CALL	PUNCH		;call CBIOS PUNCH
FIXUP30	EQU	$-1		;
	XOR	A		;ret IOSTATUS OK
	RET			;

;-----	Clock read
CLKREAD	;HALT
	LD	BC,0		;no clock: time=0
	PUSH	BC		;
	POP	DE		;
	LD	A,9		;clock offline
	RET

;-----	USR routines
USRREAD:
USRWRIT	HALT
	POP	HL		;pop ret address
	POP	AF		;discard 5th param
	EX	(SP),HL		;discard 4th param
USRSTAT	HALT
	POP	HL		;pop ret address
	POP	AF		;discard 3rd param
	POP	AF		;discard 2nd param
	POP	AF		;discard 1st param
	PUSH	HL		;push ret address
USRINIT	LD	A,9		;unavailable
	RET			;return to caller


;-----	Select Disk Drive
;			FLOPPY	HARD
;	Param	Offset	Value	Value
;	SPT	0-1	36	64
;	BSH	2	4	6
;	BLM	3	15	63
;	DSM	5-6	84	915
;	OFF	13	2	2
;	TotSecs		1360	58624	=(BLM+1)*(DSM+1)
;	LogTrks		38	916	=ceil(TotSecs/SPT)
;	TotTrks		40	918	=LogTrks+OFF
;	Cyls		40	306
;	Heads		1	3
SETDISK	CALL	SELDSK		;Call CBIOS SELDSK
FIXUP03	EQU	$-1		;
	;HALT			;$$$$$$$
	EX	DE,HL		;DPH to DE
	LD	HL,(DSKDPH)	;get old current disk DPH
FIXUP12	EQU	$-1		;
	OR	A		;Compare with old DPH
	SBC	HL,DE		;
	EX	DE,HL		;
	RET	Z		;return if same drive
SETDPH	LD	(DSKDPH),HL	;save new DPH
FIXUP13	EQU	$-1		;
	LD	A,H		;Check if drive active (DPH not null)
	OR	L		;
	RET	Z		;return if not
	;HALT			;$$$$$$$
	LD	DE,0AH		;point to DPB
	ADD	HL,DE		;
	LD	E,(HL)		;get DPB to DE
	INC	HL		;
	LD	D,(HL)		;
	PUSH	IX		;save IX
	PUSH	DE		;move to IX
	POP	IX		;
	LD	C,(IX+0)	;get RPT=Records Per Track
	LD	B,(IX+1)	;
	SLA	C		;mult by 2
	RL	B		;
	LD	(DSKSECS),BC	;save as number of sectors
FIXUP04	EQU	$-1		;
	LD	A,(IX+2)	;get BSH=Block Shift Factor
	LD	L,(IX+5)	;get DSM=Drive Capacity
	LD	H,(IX+6)	;
	INC	HL		;DSM+1
	POP	IX		;restore IX
LSETD0	ADD	HL,HL		;shift HL left according to BSH
	DEC	A		;
	JR	NZ,LSETD0	;
	CALL	DIVHLBC		;HL := (BLM+1) * (DSM+1) % SPT
FIXUP05	EQU	$-1		;
	LD	A,H		;Is remainder null
	OR	L		;
	JR	Z,JSETD1	;increment number of tracks if not
	INC	DE		;
JSETD1	INC	DE		;add 1 logical system tracks
	LD	A,D		;Check if >255
	OR	A		;
	JR	Z,JSETD2	;OK if not
	LD	DE,255		;set maximum number of tracks for Pascal
JSETD2	LD	(DSKTRKS),DE	;DE := (BLM+1) * (DSM+1) / SPT
FIXUP06	EQU	$-1		;
	LD	BC,DSKPARM	;return disk parameters to BC
FIXUP07	EQU	$-1		;
	JP	DSKCHNG		;Call back p-System DSKCHNG
FIXUP08	EQU	$-1		;

;-----	Set Disk Sector Buffer Address
SETBUFR	CALL	SETDMA		;call CBIOS routine
FIXUP11	EQU	$-1		;
	LD	B,0		;clear B for following SETTRAK call
	RET			;done

;-----	Set Disk Track
SETTRAK	LD	(DSKLTRK),BC	;save logical track #
FIXUP09	EQU	$-1		;
	LD	A,C		;track #
	DEC	A		;dir track ?
	SUB	1		;set Cy if yes
	ADC	A,2		;add Cy
	SUB	C		;adjust
	LD	(DSKWRTY),A	;write type (1 for dir track, else 0)
FIXUP32	EQU	$-1		;
	JR	SETTKSC		;convert to physical track/sector

;-----	Set Disk Sector
SETSECT	DEC	BC		;subtract 1 for Montezuma BIOS
	LD	(DSKLSEC),BC	;save logical sector #
FIXUP18	EQU	$-1		;

;-----	Set Disk Track/Sector
SETTKSC	;HALT
	LD	BC,(DSKLTRK)	;get logical track #
FIXUP19	EQU	$-1		;
	SLA	C		;mult by 2
	RL	B		;
	LD	DE,(DSKSECS)	;get logical sectors per track
FIXUP20	EQU	$-1		;
	SRL	D		;divide by 2
	RR	E		;to get CBIOS sectors per track
	LD	HL,(DSKLSEC)	;
FIXUP21	EQU	$-1		;get logical sector #
	OR	A		;
	SBC	HL,DE		;try subtract by CBIOS sect per track
	INC	BC		;increment CBIOS sector #
	JR	NC,JSETTS1	;go if ok
	DEC	BC		;else revert
	ADD	HL,DE		;
JSETTS1	CALL	SETTRK		;set CBIOS track #
FIXUP22	EQU	$-1		;
	LD	B,H		;move CBIOS sector # to BC
	LD	C,L		;
	JP	SETSEC		;set CBIOS sector #
FIXUP23	EQU	$-1		;

;-----	Read Disk Sector
DSKREAD	LD	HL,(DSKDPH)	;Check if drive active (DPH not null)
FIXUP14	EQU	$-1		;
	LD	A,H		;
	OR	L		;
	LD	A,9		;Error code 9 if not
	RET	Z		;and return
	CALL	READ		;else call CBIOS sector read routine
FIXUP15	EQU	$-1		;
	RET	Z		;return if OK
	LD	HL,0		;
	LD	(DSKDPH),HL	;clear DPH pointer
FIXUP34	EQU	$-1		;
	RET

;-----	Write Disk Sector
DSKWRIT	LD	HL,(DSKDPH)	;Check if drive active (DPH not null)
FIXUP16	EQU	$-1		;
	LD	A,H		;
	OR	L		;
	LD	A,9		;Error code 9 if not
	RET	Z		;and return
	LD	C,0		;write type (1 for dir track)
DSKWRTY	EQU	$-1		;
	JP	WRITE		;else jump to CBIOS sector write routine
FIXUP17	EQU	$-1

;-----	Divide HL by BC to DE, remainder to HL
DIVHLBC	EX	DE,HL		;dividend to DE
	LD	H,B		;divisor to HL
	LD	L,C		;
	XOR	A		;init iteration counter
LDIV0	INC	A		;inc iteration counter
	ADD	HL,HL		;rescale divisor
	JR	NC,LDIV0	;set divisor to full scale
	LD	C,L		;rescaled divisor = CF:BC
	LD	B,H		;
	LD	HL,0		;init quotient
	EX	DE,HL		;quotient to DE, dividend to HL
LDIV1	RR	B		;shift divisor right, including CF
	RR	C		;
	SLA	E		;shift quotient left
	RL	D		;
	SBC	HL,BC		;try subtraction
	INC	DE		;inc quotient
	JR	NC,JDIV2	;jump if OK
	ADD	HL,BC		;revert subtraction
	DEC	DE		;revert inc quotient
JDIV2	OR	A		;Clr CF !
	DEC	A		;next iteration
	JR	NZ,LDIV1	;until all done
	RET			;return quotient to DE, remainder to HL

;-----	Disk Drive Parameters Header Pointer
DSKDPH	DW	0		;selected disk DPH

;-----	Disk Drive Logical Track and Sector Number
DSKLTRK	DW	0		;current logical track
DSKLSEC	DW	0		;current logical sector

;-----	Disk Parameters Table
DSKPARM	EQU	$		;DSKCHNG parameters
DSKTRKS	DW	0		;tracks per disk
DSKSECS	DW	0		;sectors per track
DSKBYTS	DW	128		;bytes per sector
ITLFACT	DW	1		;interleaving factor
FPASTRK	DW	1		;first Pascal track
TRKSKEW	DW	0		;track-to-track skew

;-----	Filler
	DC	1600H-$,0	;Filler for 256 bytes

;======================================================================

;	CBIOS jump vectors
CBOOT	DS	3		;Cold start
WBOOT	DS	3		;warm start
CONST	DS	3		;console status
CONIN	DS	3		;console input
CONOUT	DS	3		;console output
LISTOUT	DS	3		;list output
PUNCH	DS	3		;punch output
READER	DS	3		;reader input
HOME	DS	3		;home drive head
SELDSK	DS	3		;select disk
SETTRK	DS	3		;set track #
SETSEC	DS	3		;set sector #
SETDMA	DS	3		;set DMA address
READ	DS	3		;read disk sector
WRITE	DS	3		;write disk sector
PRSTAT	DS	3		;get list status
SECTRN	DS	3		;sector translate

SPB	EQU	$		;System parameters block

	END
