all: cshell echo.com brk.com hybrid.com dos.com

cshell: cshell.asm
	64tass --cbm-prg -a -o $@ -L $(patsubst %.asm,%.lst,$<) $<

%.com: %.asm cshell.inc c64.inc
	64tass --cbm-prg -a -o $@ -L $(patsubst %.asm,%.lst,$<) $<

