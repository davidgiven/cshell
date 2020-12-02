	.include "c64.inc"
	.include "cshell.inc"

	.cpu "6502"
	CSHELL_HEADER

	ldy #PPB_ARGPTR
	lda (PPB),y
	tay

-
	lda (PPB),y
	beq +
	jsr CHROUT
	iny
	jmp -
+
	lda #13
	jsr CHROUT
	jmp (CSHELL)

