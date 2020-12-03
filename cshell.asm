	.include "c64.inc"
	.include "cshell.inc"

	TOP = $d000

	.cpu "6502"
	BASIC_HEADER

; ---------------------------------------------------------------------------
;                                 STARTUP CODE
; ---------------------------------------------------------------------------

entry:
	; Print startup banner

	jsr print
	.null 147, 14, 5, 13, "CShell (C) 2020 David Given", 13, "  "

	lda #>(ccp_start - $800)
	ldx #<(ccp_start - $800)
	jsr $bdcd		; Basic routine to print a byte

	jsr print
	.null " bytes free", 13

	lda #$36
	sta 1			; map Basic out
	lda #0
	sta 53280		; set border to black
	sta 53281		; set background to black

	; Set the BRK vector to restart the command processor.

	lda #<brk_handler
	sta IRQV+0
	lda #>brk_handler
	sta IRQV+1

	; Set the kernal's top-of-memory address.

	ldx #<ccp_start
	ldy #>ccp_start
	clc
	jsr MEMTOP

	; Relocate CCP to top of memory

	lda #<ccp_image_start
	sta 2
	lda #>ccp_image_start
	sta 3
	lda #<ccp_start
	sta 4
	lda #>ccp_start
	sta 5
	ldy #0

relocation_loop:
	lda (2), y
	sta (4), y

	inc 2
	bne +
	inc 3
+	inc 4
	bne +
	inc 5
+

	lda 4
	cmp #<TOP
	bne relocation_loop
	lda 5
	cmp #>TOP
	bne relocation_loop

	; Start the command processor.

	jmp ccp_entry

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

; ---------------------------------------------------------------------------
;                              COMMAND PROCESSOR
; ---------------------------------------------------------------------------

ccp_image_start:
	.logical TOP - (ccp_image_end - ccp_image_start)
ccp_start:

gobble:
	jsr readchar
	cmp #13
	bne gobble
	jmp newline_then_read_command

ccp_entry:
	ldx #0
	txs
	jsr CLALL

	; If the last command failed, close any outstanding submit files.

	lda status
	beq +
	jsr close_sub
empty_line:
	lda #'!'
	jsr CHROUT
	lda #0
	sta status
+
newline_then_read_command:
	jsr newline
read_command:
	lda drive
	clc
	adc #"0"
	jsr CHROUT
	lda #'>'
	jsr CHROUT

	; Skip leading whitespace.

-	jsr readchar
	cmp #" "
	beq -
	cmp #13
	beq ccp_entry

	; Drive change command?

	cmp #'#'
	bne +
	jsr readchar

	sec
	sbc #'0'
	sta drive
	jmp gobble
+

	; Read the command name into the buffer.

	ldx #0
-
	cmp #13
	beq +
	cmp #' '
	beq +
	sta command, x
	inx
	jsr readchar
	jmp -
+

	; Append the '.com\0' suffix.

	pha					; save last character read
	ldy #4
-
	lda dotcom, y
	sta command, x
	inx
	dey
	bpl -

	; X is now pointing at the argument string.

	dex
	txa
	sta commandlen
	clc
	adc #(command - PPB_abs) + 1
    sta argptr
	inx

	; Skip more whitespace.

	pla
-
	cmp #13
	beq null_terminate
	cmp #' '
	bne +
	jsr readchar
	jmp -
+

	; Now read the actual arguments.

-
	sta command, x
	inx
	jsr readchar
	cmp #13
	bne -

	; ...and null-terminate.

null_terminate:
	lda #0
	sta command, x

	; Look for a file of this name on the current drive.

	lda #1
	ldx drive
	ldy #1
	jsr SETLFS

	lda commandlen
	ldx #<command
	ldy #>command
	jsr SETNAM

	lda #$00
	jsr SETMSG			; no messages

	lda #0
	jsr LOAD
	bcs error
	jsr newline

	; The program is now in memory, with the start address in XY.

	lda #<ccp_entry
	sta CSHELL+0
	lda #>ccp_entry
	sta CSHELL+1
	lda #<PPB_abs
	sta PPB+0
	lda #>PPB_abs
	sta PPB+1

	lda #'c'
	ldx #'s'
	ldy #'h'
	jsr entry
	jmp ccp_entry

error:
	jsr newline
	lda #'?'
	jsr CHROUT
	jsr close_sub
	jmp ccp_entry

newline:
	lda #13
	jmp CHROUT

brk_handler:
	lda #1
	sta status
	jmp ccp_entry

; Reads a character from the input stream, either via CHRIN or the input buffer.
; Does not change X.
readchar:
	lda inputbuf+0
	sta CSHELL+0		; reuse CSHELL as the intput pointer
	bne readchar_sub
	lda inputbuf+1
	sta CSHELL+1
	bne readchar_sub
	jmp CHRIN
	
readchar_sub
	ldy #0
	lda (CSHELL), y
	beq readchar_eof

	inc inputbuf+0
	beq +
	inc inputbuf+1
+
	cmp #13
	beq +
	jsr CHROUT
+	rts

readchar_eof:
	jsr close_sub
	jmp CHRIN

close_sub:
	txa
	pha
	ldx #<ccp_start
	ldy #>ccp_start
	clc
	jsr MEMTOP
	lda #0
	sta inputbuf+0
	sta inputbuf+1
	pla
	tax
	rts

dotcom: .text 0, 'moc.' ; backwards

PPB_abs:
drive:       .byte 8
status:      .byte 0
inputbuf:    .word 0
argptr:		 .byte ?
commandlen:  .byte ?
command:     .fill 80
	.here
ccp_image_end:

