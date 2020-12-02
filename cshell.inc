CSHELL = 2
PPB = 4

PPB_DRIVE = 0
PPB_STATUS = 1
PPB_ARGPTR = 2
PPB_COMMAND = 3

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

