; Lists the current directory.
;
; Syntax: dos <command>
;
; e.g. to delete a file: dos s:filename

	.include "c64.inc"
	.include "cshell.inc"

	.cpu "6502"
	CSHELL_HEADER

	jsr open_directory

	ldx #1
	jsr CHKIN

line_loop:
	; Skip until the next ".

-
	jsr READST
	and #$40		; check for EOF
	bne eof
	jsr CHRIN
	cmp #'"'
	bne -

	jsr CHROUT
-
	jsr READST
	and #$40		; check for EOF
	bne eof
	jsr CHRIN
	beq eol
	jsr CHROUT
	jmp -

eol:
	lda #13
	jsr CHROUT
	jmp line_loop
	
eof:
	ldx #0
	jsr CHKIN
	jsr CLOSE
	rts

; --- Open the directory stream ----------------------------------------------

open_directory:
	lda #1
	ldx #<filename
	ldy #>filename
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

filename: .null "$0"

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

