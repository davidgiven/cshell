	.include "c64.inc"
	.include "cshell.inc"

	.cpu "6502"
	* = $800

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
	jmp (2)

