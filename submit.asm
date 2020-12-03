; Sends a command to DOS and fetches the response.
;
; Syntax: dos <command>
;
; e.g. to delete a file: dos s:filename

	.include "c64.inc"
	.include "cshell.inc"

PTR1 = 6
YTEMP = 8
PTR2 = 9

	.cpu "6502"
	CSHELL_HEADER

	ldy #PPB_ARGPTR
	lda (PPB), y
	tay

	jsr parse_parameters
	jsr open_submit_file
	jsr parse_file
	jsr close_submit_file
	lda nflag
	bne nflag_cmd
	jsr copy_to_destination
	rts

; --- File dumper ------------------------------------------------------------

	; Just lists the buffer to stdout without doing anything.
nflag_cmd:
	lda #<buffer
	sta PTR1+0
	lda #>buffer
	sta PTR1+1

-
	ldy #0
	lda (PTR1), y
	beq nflag_eof
	jsr CHROUT

	inc PTR1+0
	bne +
	inc PTR1+1
+
	jmp -

nflag_eof:
	lda #13
	jmp CHROUT
	
; --- Parameter parsing -----------------------------------------------------

; On entry, Y is the PPB offset.
parse_parameters:
	lda (PPB), y
	cmp #'-'
	bne no_arguments

	iny
	lda (PPB), y
	cmp #'h'
	bne +
	; Print help.
	jsr print
	.null "syntax: submit [-h] [-n] <subfile> [<parameters>...]", 13
	jmp error
+

	cmp #'n'
	bne +
	inc nflag
+

	iny
	lda (PPB), y
no_arguments:
-
	cmp #' '
	bne +
	iny
	lda (PPB), y
	jmp -
+

	; Y is now pointing at the first actual word. Parse the string, accumulating
	; pointers to them, and null-terminating.
	ldx #0
argument_parse_loop:
	tya
	sta words, x	; store offset to this word
	inx

-					; skip non-whitespace
	iny
	lda (PPB), y
	beq end_of_line
	cmp #' '
	bne -
	
	lda #0
	sta (PPB), y	; terminate last word

-					; skip whitespace
	iny
	lda (PPB), y
	beq end_of_line
	cmp #' '
	beq -
	jmp argument_parse_loop

end_of_line:
	rts

; --- Utilities --------------------------------------------------------------

; (Here to keep them within relative jump range)

file_error:
	jsr print
	.null "File error", 13
	; fall through
error:
	lda #1
	ldy #PPB_STATUS
	sta (PPB), y
	jmp (CSHELL)

; --- Load source file -------------------------------------------------------

open_submit_file:
	; Copy the source filename to the buffer.

	ldy words
	ldx #0
-
	lda (PPB), y
	beq +
	sta buffer, x
	iny
	inx
	jmp -
+

	; Now append the .sub suffix.

	ldy #4
-
	lda dotsub, y
	sta buffer, x
	inx
	dey
	bpl -
	dex

	; X is the file length.

	txa
	ldx #<buffer
	ldy #>buffer
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

close_submit_file:
	lda #1
	jmp CLOSE

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

	ldx #0
	jsr CHKOUT
	lda #15
	jsr CLOSE
	rts

; --- Read and parse the file ------------------------------------------------

parse_file:
	lda #<buffer
	sta PTR1+0
	lda #>buffer
	sta PTR1+1

	ldx #1
	jsr CHKIN

parse_loop:
	jsr READST
	and #$40		; check for EOF
	bne eof

	jsr CHRIN
	cmp #'$'
	bne not_dollar

	jsr CHRIN
	cmp #'$'
	beq not_dollar	; $$ gets turned into a $

	sec
	sbc #'0'
	cmp #10
	bcs parse_loop	; out of range

	tay
	lda words, y
	beq not_dollar	; no such parameter
	tay
-
	lda (PPB), y
	beq parse_loop
	iny
	sty YTEMP
	ldy #0
	sta (PTR1), y
	ldy YTEMP
	inc PTR1+0
	bne -
	inc PTR1+1
	jmp -

not_dollar:
	ldy #0
	sta (PTR1), y
	inc PTR1+0
	bne +
	inc PTR1+1
+
	jmp parse_loop
	
eof:
	ldx #0
	jsr CHKIN

	lda #0
	ldy #0
	sta (PTR1), y	; null-terminate buffer
	rts
	
; --- Copy to destination ----------------------------------------------------

; Copies the contents of the buffer to just below TOP.
; On entry, PTR1 points to the end of the buffer.

copy_to_destination:
	; Set PTR1 to the length of the buffer.

	sec
	lda PTR1+0
	sbc #<buffer
	sta PTR1+0
	lda PTR1+1
	sbc #>buffer
	sta PTR1+1

	; Now compute the start address into PTR2.

	sec
	jsr MEMTOP

	sec
	txa
	sbc PTR1+0
	sta PTR2+0
	tya
	sbc PTR1+1
	sta PTR2+1

	; Update the kernal's top-of-memory address.

	ldx PTR2+0
	ldy PTR2+1
	clc
	jsr MEMTOP

	; Tell cshell to start reading input from the buffer.

	ldy #PPB_INPUTBUF
	lda PTR2+0
	sta (PPB), y
	iny
	lda PTR2+1
	sta (PPB), y

	; Now copy the buffer.

	lda #<buffer
	sta PTR1+0
	lda #>buffer
	sta PTR1+1
	ldy #0
-
	lda (PTR1), y
	sta (PTR2), y
	beq end_of_copy
	inc PTR1+0
	bne +
	inc PTR1+1
+
	inc PTR2+0
	bne +
	inc PTR2+1
+
	jmp -

end_of_copy:
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

dotsub: .text 0, 'bus.' ; backwards

nflag: .byte 0
words: .fill 10, 0
buffer:

