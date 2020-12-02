	.include "c64.inc"
	.include "cshell.inc"

	TOP = $a000

	.cpu "6502"
	* = $800

	ldy #PPB_ARGV
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

