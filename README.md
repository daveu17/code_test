# Truss Software Engineering Interview submission

This is perl 5 code written by David Uebele based on Truss Software engineer interview question.

Information on this code test challenge was sent out Monday, Jun 25, with a 1 week deadline for submission.
The original README.md file is renamed to REQUIREMENTS.md and will be included in this repository.

# Details
This code should run on most perl 5 interpreters. 
The code is contained in a single file:
csv_daveu.pl

I tried to use only functions/libraries available on stock perl 5 installations to avoid requiring additional perl libraries.
This minimizes the requirements for custom library installation on the target machine.

I test ran this on MacOS (uname output):
   17.6.0 Darwin Kernel Version 17.6.0: Tue May  8 15:22:16 PDT 2018; root:xnu-4570.61.1~1/RELEASE_X86_64 x86_64
And on a fedora 28 system (I did not have quick acess to an ubuntu system).

The only change that may be required is to modify the first line of csv_daveu.pl to specify the location of perl on the system where this script will run.
As checked in, the path is set to perl on my Mac:
#!/opt/local/bin/perl

On the fedora 28 system, this should be changed to:
#!/usr/bin/perl
I think perl should be in a similar location on an ubuntu system.

Basic program flow is to read from STDIN (Perl automatically opens the file descripters STDIN, STDOUT, and STDERR).
The first line is assumed to be an all text header for the CSV file, and is passed through unmodified.

Then each line is parsed in a while loop (until STDIN is all read). 
The code was structured so that if errors are found in a entry line, the loop could use "next" prior to the print statement to avoid printing lines determined to be invalid.

Within the line, a simple split of the line based on commas is used, if it is determined that a value contains a comma,
then additional values are pulled from the array to re-join the value into a single field.  
The Address with comma is assumed to protected by double quotes only.

For the time/date modification, localtime is used as the baseline for converting to/from a human readable data and seconds since the epoch (typically Jan 1, 1970).  Since both translations use the same epoch starting point, it should work regardless of the systems timezone setting.


# Issues

With more time, and a larger input sample, error checking on input values should be added.  
This would be most important on the date and duration fields, to make them more robust to the math operations when they include bad data.

The UTF-8 encoding is not an area I'm strongly familiar, so I think I satisfied the requirements, but not 100% certain.
I'm especially not certain if the requirement to translate names to upper case correctly meshes with the UTF-8 encoding for all name types.

Values that contain commas are assumed to be protected by double quotes.  Values protected by single quotes or other characters would be not be correctly processed.

Some CSV formats can contain newlines. This parsing assumes one line per CSV entry.

Its possible that a value containing \",  could not be correctly rejoined into a single value entry.


