all: cshell.prg echo.com brk.com

cshell.prg: cshell.asm
	64tass --cbm-prg -a -o $@ -L $(patsubst %.asm,%.lst,$<) $<

echo.com: echo.asm
	64tass --cbm-prg -a -o $@ -L $(patsubst %.asm,%.lst,$<) $<

brk.com: brk.asm
	64tass --cbm-prg -a -o $@ -L $(patsubst %.asm,%.lst,$<) $<

