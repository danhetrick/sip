# sip

Takes a list of files and converts them into a Perl script that extracts the files when ran, with the ability to display text or files, check file integrity with MD5 hashes, run commands before and after extraction, and create 'silent' extractors. SIP's main purpose is NOT to be an alternative to par, but to be the basis for a Perl software installation system. Uses File::Basename, Digest::MD5, File::Find, File::Path, and Getopt::Mixed.

Usage:
sip.pl OPTIONS file,file,...

Options:

-v,--version Print version and exit

-h,--help Print this text

-n,--nobanner Do not print banner in output script

-N,--name text Changes the name displayed in the banner

-s,--silent Output script executes silently

-p,--text text Print text at beginning of output script

-P,--print filename Prints the contents of a text file at beginning of output script

-m,--md5 Verify file integrity. Output script will require Digest::MD5

-f,--force Force extraction of damaged files

-o,--output filename Write output to file

-w,--overwrite Automatically overwrite existing files with output

-r,--run command Execute a command after extraction

-R,--pre command Execute a command before extraction

-d,--dir path Add all files in directory to script

-D,--recursive path Add all files in directory (recursive) to script. Directory structure is recreated on extraction.

-t,--temp Extract all files to temp directory

-l,--location directory Extract files to the specified directory

-b,--noshebang Do not add shebang to output

-B,--shebang text Adds a shebang other than #!/usr/bin/perl
