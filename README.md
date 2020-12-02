CShell
======


What?
-----

CShell is a very simple DOS shell for the Commodore 64. It allows running
machine code programs directly from disk without needing to go through Basic,
with command line parameter passsing and exit status codes. It's intended for
scripting multiple commands together (although this bit isn't done yet).


How?
----

Build it with 64tass, and then copy CSHELL and all the .COM files onto a
Commodore 64 disk (I use Vice with an emulated drive for testing). Then do:

    LOAD "CSHELL",8
	RUN

...to start the environment.

Now, typeing 'echo' will try to load and run the file 'ECHO.COM'. Command line
parameters work.

Typing '#9' which change drive to device 9.

Look at `echo.asm` for a minimal example of how to write a CShell program. In essence:

  - Programs are simple .PRG files which are loaded at 0x0801. The entry point
	is 0x080d, making them compatible with the normal Basic machine code stub.
	A program can detect whether it's being run under CShell by looking for
	'C', 'S' and 'H' in A, X and Y respectively on startup. See `hybrid.asm`
	for an example.
  - Zero page address 0x0002 contains a pointer back to CShell. Call this when
	you're finished (or do a `rts`).
  - Zero page address 0x0004 contains a pointer to the Program Parameter Block,
	which is where you can find the current drive, exit status, command line
	arguments etc.


Where?
------

- [Check out the GitHub repository](http://github.com/davidgiven/cshell) and
  build from source.

- [Ask a question by creating a GitHub
  issue](https://github.com/davidgiven/cshell/issues/new), or just email me
  directly at [dg@cowlark.com](mailto:dg@cowlark.com). (But I'd prefer you
  opened an issue, so other people can see them.)


Who?
----

Cowgol was written mostly by me, David Given.  Feel free to contact me by email
at [dg@cowlark.com](mailto:dg@cowlark.com). You may also [like to visit my
website](http://cowlark.com); there may or may not be something interesting
there.


License?
--------

CShell is  open source software available [under the 2-clause BSD
license](https://github.com/davidgiven/cshell/blob/master/COPYING). Simplified
summary: do what you like with it, just don't claim you wrote it.

