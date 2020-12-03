; Sends a command to DOS and fetches the response.
;
; Syntax: dos <command>
;
; e.g. to delete a file: dos s:filename

	.include "c64.inc"
	.include "cshell.inc"

	.cpu "6502"
	CSHELL_HEADER

	; Open the connection to the drive

	ldy #PPB_DRIVE
	lda (PPB), y
	tax
	lda #15
	ldy #15
	jsr SETLFS

	lda #0
	jsr SETNAM

	jsr OPEN
	bcc +
	jsr print
	.null "Could not contact drive"
	jmp error
+

	; Write out the parameter string

	ldx #15
	jsr CHKOUT

	ldy #PPB_ARGPTR
	lda (PPB),y
	tay

-
	lda (PPB), y
	beq +
	jsr CHROUT
	iny
	jmp -
+

	ldx #0
	jsr CHKOUT
	
	; Read in and display any response, recording it in our buffer

	ldx #15
	jsr CHKIN

	ldy #0
-
	jsr READST
	and #$40		; check for EOF
	bne +

	jsr CHRIN
	sta buffer, y
	iny
	jsr CHROUT
	jmp -
+

	ldx #0
	jsr CHKOUT

	; Close the disk channel

	jsr CLOSE

	; If the error code is <20, return success

	ldy #0
	lda buffer
	cmp #'1'
	bcc +
	iny
+	tya
	ldy #PPB_STATUS
	sta (PPB), y

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

error:
	lda #1
	ldy #PPB_STATUS
	sta (PPB), y
	rts

buffer:

