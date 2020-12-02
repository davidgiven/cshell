	.include "c64.inc"
	.include "cshell.inc"

	.cpu "6502"
	BASIC_HEADER

	cmp #'c'
	bne not_cshell
	cpx #'s'
	bne not_cshell
	cpy #'h'
	bne not_cshell

	jsr print
	.null 'This program is running from CShell.'
	rts

not_cshell:
	jsr print
	.null 'This program is running from Basic.'
	rts
	
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


