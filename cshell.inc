; Zero page addresses

CSHELL = 2
PPB = 4

; Offsets into the PPB

PPB_DRIVE = 0
PPB_STATUS = 1
PPB_INPUTBUF = 2
PPB_ARGPTR = 4
PPB_COMMAND = 5

CSHELL_HEADER .macro
	* = $801
	.text 'cshell'
	* = $80d
entry:
.endm

BASIC_HEADER .macro
	* = $801
	.word +, 1
	.null $9e, format("%d", entry)
+	.word 0
entry:
.endm

