; Dumps a file to stdout.
;
; Syntax: type <filename>

	.include "c64.inc"
	.include "cshell.inc"

	.cpu "6502"
	CSHELL_HEADER

PTR = 6

	jsr open_file

	ldx #1
	jsr CHKIN

-
	jsr READST
	and #$40		; check for EOF
	bne +
	jsr CHRIN
	jsr CHROUT
	jmp -
+
	
	ldx #0
	jsr CHKIN
	jsr CLOSE
	rts

; --- Open the directory stream ----------------------------------------------

open_file:
	ldy #PPB_ARGPTR
	lda (PPB), y
	tay
	ldx #0
-
	lda (PPB), y
	beq +
	iny
	inx
	jmp -
+

	txa
	pha
	clc
	lda PPB+0
	ldy #PPB_ARGPTR
	adc (PPB), y
	tax
	lda PPB+1
	adc #0
	tay
	sta PTR+1
	pla
	jsr SETNAM

	ldy #PPB_DRIVE
	lda (PPB), y
	tax
	lda #1
	ldy #0
	jsr SETLFS

	; Try and open the file.

	jsr OPEN
	jsr get_drive_status
	rts

; Read the drive status bytes into the buffer.

get_drive_status:
	ldy #PPB_DRIVE
	lda (PPB), y
	tax
	lda #15
	ldy #15
	jsr SETLFS

	lda #0
	jsr SETNAM
	jsr OPEN

	ldx #15
	jsr CHKIN

	jsr CHRIN
	cmp #'2'
	bcc no_drive_error

-
	jsr CHROUT
	jsr READST
	and #$40		; check for EOF
	bne +
	jsr CHRIN
	jmp -
+
	lda #1
	ldy #PPB_STATUS
	sta (PPB), y
	jmp (CSHELL)

; --- Utilities --------------------------------------------------------------

print:
	pla		; low byte
	sta 2
	pla		; high byte
	sta 3
	ldy #1
-
	lda (2), y
	inc 2
	bne +
	inc 3
+
	tax		; set flags for A
	beq +
	jsr CHROUT
	jmp -
+
	lda 3
	pha
	lda 2
	pha
	rts



	ldx #0
	jsr CHKIN
	lda #15
	jsr CLOSE

	lda #1
	ldy #PPB_STATUS
	sta (PPB), y
	jmp (CSHELL)

no_drive_error:
-
	jsr READST
	and #$40		; check for EOF
	bne +
	jsr CHRIN
	jmp -
+

	ldx #0
	jsr CHKOUT
	lda #15
	jsr CLOSE
	rts

