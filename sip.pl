#!/usr/bin/perl
#
# sip.pl
#
# Sip Isn't Par
#
# A utility for combining any number of files into
# a Perl script that extracts it's contents upon
# execution.
#
# Usage:
# sip.pl [ OPTIONS ] file file ...
#
# Version: 0.45
# Author:  Dan Hetrick
# License: GPL
#
# Options:
#
# -v,--version              Print version and exit
# -h,--help                 Print this text
# -r,--run <file/cmd>       Execute a script/command after extraction
# -R,--pre <file/cmd>       Execute a script/command before extraction
# -n,--nobanner             Do not print banner in output script
# -N,--name <text>          Changes the displayed name in the banner
# -s,--silent               Output script executes silently
# -p,--text <text>          Print text at beginning of output script
# -P,--print <filename>     Prints the contents of a text file at
#                           at beginning of output script
# -m,--md5                  Verify file integrity
#                           Output script will require Digest::MD5
# -f,--force                Force extraction of damaged files
# -d,--dir <path>           Add all files in directory to script
# -D,--recursive <path>     Add all files in directory (recursive) to script
#                           Directory structure is recreated on extraction
# -t,--temp                 Extract all files to temp directory
# -l,--location <dir>       Extract all files to a specific directory
# -o,--output <filename>    Write output to file
# -w,--overwrite            Automatically overwrite existing files with output
# -b,--noshebang            Do NOT add shebang to output script
# -B,--shebang <text>       Use another shebang instead of #!/usr/bin/perl
#

use strict;
use File::Basename;
use File::Find;
use Digest::MD5;
use Getopt::Mixed "nextOption";
my $option;
my $value;

# ========
# SETTINGS
# ========

my $APPNAME            = "sip.pl";
my $VERSION            = "0.45";
my $output_file        = 0;
my $output_filename    = "";
my $verify_mode        = 0;
my $stub_delimiter     = '%%BREAK%%';
my $print_banner       = 1;
my $silent_mode        = 0;
my $text_mode          = 0;
my $text_display       = "";
my $print_mode         = 0;
my $print_display      = "";
my $run_mode           = 0;
my $run_file           = "";
my $pre_mode           = 0;
my $pre_file           = "";
my $force_mode         = 0;
my $add_dir            = 0;
my $add_dir_name       = "";
my $radd_dir           = 0;
my $radd_dir_name      = "";
my $temp_mode          = 0;
my $location_mode      = 0;
my $location_dir       = "";
my $overwrite_mode     = 0;
my $shebang_option     = 1;
my $alt_shebang_option = 0;
my $alt_shebang        = "";
my $package_name       = "Self Extracting Perl Archive";
my $banner             = "";

my @rFilelist = ();    # Contains local paths
my @DirTree   = ();    # Contains a list of directories to create
my @oFileList = ();    # Contains extracted paths
my $basedir   = "";

# ===========
# MAIN SCRIPT
# ===========

# Handle commandline options
Getopt::Mixed::init(
"v version>v l=s N=s name>N location>l t temp>t d=s dir>d D=s recursive>D r=s run>r f force>f R=s pre>R m md5>m o=s output>o P=s print>P p=s text>p h help>h n nobanner>n s silent>s w overwrite>w b noshebang>b B=s shebang>B"
);

while ( ( $option, $value ) = nextOption() ) {
    if ( $option =~ /v/ ) { print "$VERSION\n"; exit; }
    if ( $option =~ /r/ ) { $run_mode           = 1; $run_file      = $value; }
    if ( $option =~ /R/ ) { $pre_mode           = 1; $pre_file      = $value; }
    if ( $option =~ /d/ ) { $add_dir            = 1; $add_dir_name  = $value; }
    if ( $option =~ /D/ ) { $radd_dir           = 1; $radd_dir_name = $value; }
    if ( $option =~ /l/ ) { $location_mode      = 1; $location_dir  = $value; }
    if ( $option =~ /a/ ) { $alt_shebang_option = 1; $alt_shebang   = $value; }
    if ( $option =~ /N/ ) { $package_name   = $value; }
    if ( $option =~ /w/ ) { $overwrite_mode = 1; }
    if ( $option =~ /m/ ) { $verify_mode    = 1; }
    if ( $option =~ /t/ ) { $temp_mode      = 1; }
    if ( $option =~ /f/ ) { $force_mode     = 1; }
    if ( $option =~ /n/ ) { $print_banner   = 0; }
    if ( $option =~ /b/ ) { $shebang_option = 0; }
    if ( $option =~ /s/ ) { $silent_mode    = 1; }
    if ( $option =~ /p/ ) { $text_mode      = 1; $text_display = $value; }
    if ( $option =~ /P/ ) { $print_mode     = 1; $print_display = $value; }
    if ( $option =~ /o/ ) { $output_file    = 1; $output_filename = $value; }

    if ( $option =~ /h/ ) {
        Usage();
    }
}

Getopt::Mixed::cleanup();

my @files;

if ( $add_dir == 1 ) {
    if($add_dir_name=~/,/) {
        my @ads=split(',',$add_dir_name);
    foreach my $dir (@ads)
    {
        push(@files,GetFileList($dir));
    }
    } else {
        push(@files,GetFileList($add_dir_name));
    }
}

if ( $radd_dir == 1 ) {
    if($radd_dir_name=~/,/) {
        my @ads=split(',',$radd_dir_name);
    foreach my $dir (@ads)
    {
        push(@files,GetFileListRecursive($dir));
    }
    } else {
        push(@files,GetFileListRecursive($radd_dir_name));
    }
}

push( @files, @ARGV );

if ( ( $output_file == 1 ) && ( -e $output_filename ) ) {
    if ( $overwrite_mode == 0 ) {
        print "File $output_filename already exists.\n";
        print "Replace [y/n] ? ";
        my $retval = <STDIN>;
        if ( $retval =~ /y/ ) {
            open( FILE, ">$output_filename" ) or die "Error writing file.";
            print FILE "";
            close FILE;
        }
        else {
            exit;
        }
    }
    else {
        open( FILE, ">$output_filename" ) or die "Error writing file.";
        print FILE "";
        close FILE;
    }
}

if ( $#files >= 0 ) {
    MakeArchiveScript(@files);
}
else {
    Usage();
}

# ===================
# SUPPORT SUBROUTINES
# ===================

# Usage()
#
# Displays application usage.
#
sub Usage {
    print "\nSIP - Sip Isn't Par\n";
    print "Version: $VERSION\n";
    print "Author:  Dan Hetrick\n";
    print "License: GPL\n";
    print "Combines any number of files into a single Perl script that\n";
    print "extracts its contents on execution.\n\n";
    print "Usage: $0 [ OPTIONS ] file file ...\n\n";
    print "Options:\n\n";
    print "-v,--version              Print version and exit\n";
    print "-h,--help                 Print this text\n";
    print
      "-r,--run <file/cmd>       Execute a script/command after extraction\n";
    print
      "-R,--pre <file/cmd>       Execute a script/command before extraction\n";
    print "-n,--nobanner             Do not print banner in output script\n";
    print "-N,--name <text>          Changes the package name in the banner\n";
    print "-s,--silent               Output script executes silently\n";
    print
      "-p,--text <text>          Print text at beginning of output script\n";
    print "-P,--print <filename>     Prints the contents of a text file at\n";
    print "                          at beginning of output script\n";
    print "-m,--md5                  Verify file integrity\n";
    print "                          Output script will require Digest::MD5\n";
    print "-f,--force                Force extraction of damaged files\n";
    print "-t,--temp                 Extract all files to temp directory\n";
    print
      "-l,--location <dir>       Extract all files to a specific directory\n";
    print "-d,--dir <path>           Add all files in directory to script\n";
    print
"-D,--recursive <path>     Add all files in directory (recursive) to script\n";
    print
"                          Directory structure is recreated on extraction\n";
    print "-o,--output <filename>    Write output to file\n";
    print
"-w,--overwrite            Automatically overwrite existing files with output\n";
    print "-b,--noshebang            Do NOT add shebang to output script\n";
    print "-B,--shebang <text>       Use another shebang instead of "
      . '#!/usr/bin/perl' . "\n\n";
    print "Multiple directories can be passed to SIP with the -d and -D tags.\n";
    print "Seperate each directory with a comma, like '/home/use,/usr,...'.\n";
    print "\n";
    exit;
}

# MakeArchiveScript(@list_of_files)
#
# Takes a list of files, builds the
# script stub, calls MakePerlArchive(),
# and returns a Perl script
#
sub MakeArchiveScript {
    my (@file_list) = @_;
    my @stub        = <DATA>;
    my $filecount   = $#file_list + 1;
    my $retval      = "";
    my $border      = '*' x length($package_name);
    $banner = 'print "\n' . $border . '\n";';
    $banner .= 'print "' . $package_name . '\n";';
    $banner .= 'print "' . $border . '\n\n";';
    $banner .= 'print "Created with !APPNAME !VERSION\n\n";';
    $banner .= 'print "Files: !FILECOUNT\n\n";';
    my $stubs = join( '', @stub );
    my @stb = split( "$stub_delimiter", $stubs );

    if ( $shebang_option == 1 ) {
        if ( $alt_shebang_option == 1 ) {
            $retval .= $alt_shebang . "\n";
        }
        else {
            $retval .= '#!/usr/bin/perl' . "\n";
        }
    }
    if ( $verify_mode == 1 ) {
        $retval .= $stb[0];
    }
    else {
        $retval .= $stb[1];
    }
    if ( $print_banner == 1 ) {
        if ( $silent_mode == 1 ) {
            $retval =~ s/!BANNER//g;
        }
        else {
            $retval =~ s/!BANNER/$banner/g;
        }
    }
    else {
        $retval =~ s/!BANNER//g;
    }
    if ( $radd_dir == 1 ) { $retval =~ s/!FILEPATH/use File::Path;/g; }
    else { $retval =~ s/!FILEPATH//g; }
    $retval =~ s/!APPNAME/$APPNAME/g;
    $retval =~ s/!VERSION/$VERSION/g;
    $retval =~ s/!FILECOUNT/$filecount/g;
    if ( $temp_mode == 1 ) { $retval .= 'chdir "$ENV{TMP}";'; }
    if ( $location_mode == 1 ) {
        $retval .= 'chdir "' . $location_dir . '";';
    }

    if ( $text_mode == 1 ) {
        $retval .= 'print "' . $text_display . '\n";';
    }
    if ( $print_mode == 1 ) {
        if ( -e "$print_display" ) {
            open( FILE, "<$print_display" )
              or die "Error opening $print_display.";
            my @pd = <FILE>;
            close FILE;
            foreach my $ln (@pd) {
                chomp $ln;
                $retval .= 'print "' . $ln . '\n";';
            }
        }
        else {
            print "Input file doesn't exist.\n";
            exit;
        }
    }
    WriteOutput($retval);
    MakePerlArchive(@file_list);
}

# MakePerlArchive(@file_list)
#
# Takes an array of
# files as an argument, and returns
# a Perl script that will extract
# those files into the current
# directory
#
sub MakePerlArchive {
    my (@archive_list) = @_;
    my $packsubs       = "";
    my $retval         = "";
    my $hash           = "";
    if ( $pre_mode == 1 ) {
        if ( $silent_mode == 0 ) {
            $retval .= 'print `' . $pre_file . '`;';
        }
        else {
            $retval .= 'my $retval=`' . $pre_file . '`;';
        }

    }
    if ( $radd_dir == 1 ) {
        my $rs = join( ',', @DirTree );
        $rs =~ s/,/','/g;
        $rs = "'$rs'";
        $retval .= 'mkpath([' . $rs . '],0,0777);';
    }
    WriteOutput($retval);
    $retval = "";
    my $ofCount = 0;
    foreach my $file (@archive_list) {
        my $original_filename = $file;
        if ( $verify_mode == 1 ) { $hash = HashFile($original_filename); }
        my $outputfilename = basename($file);
        if ( $radd_dir == 1 ) {
            $outputfilename = $oFileList[$ofCount];
        }
    if(length($outputfilename)==0) { next; }
        my $subname = random_string(10);
        $retval .= '$file=' . "'" . $outputfilename . "';";
        if ( $verify_mode == 1 ) { $retval .= '$hash="' . $hash . '";' }
        $retval .= '$packed_data=' . $subname . '();' . "\n";
        $retval .= 'open(FILE,">$file") || die "Error writing file - $!\n";';
        $retval .= 'binmode FILE;';
        $retval .= 'print FILE $packed_data;';
        $retval .= 'close FILE;';
        WriteOutput($retval);
        $retval = "";

        if ( $verify_mode == 1 ) {
            $retval .= 'if(VerifyFile($hash,$file)==0) { ';
            if ( $silent_mode == 0 ) {
                $retval .= 'print "$file is damaged.\n";';
            }
            if ( $force_mode == 0 ) {
                if ( $silent_mode == 0 ) {
                    $retval .= ' print "$file not extracted.\n"; ';
                }
                $retval .= ' unlink $file; } else {';
            }
            else {
                if ( $silent_mode == 0 ) {
                    $retval .= ' print "$file extracted anyway.\n"; ';
                }
                $retval .= ' } else {';
            }
            if ( $silent_mode == 0 ) {
                $retval .= ' print "Extracted $file\n";';
            }
            $retval .= ' } ' . "\n";
        }
        else {
            if ( $silent_mode == 0 ) {
                $retval .= 'print "Extracted $file\n";';
            }
        }
        WriteOutput($retval);
        $retval = "";
        WriteOutput( PackBinaryFile( $original_filename, $subname ) );
        $ofCount++;
    }
    if ( $silent_mode == 0 ) {
        $retval .= 'print "\n";';
    }
    if ( $run_mode == 1 ) {
        $retval .= 'exec "' . $run_file . '";';
    }
    WriteOutput($retval);
}

# PackBinaryFile($filename,$subroutine_name)
#
# Loads a file, packs it, and makes a Perl
# subroutine to unpack it.
#
# Found on comp.lang.perl.misc in a post by
# Jonathan Stowe (gellyfish@gellyfish.com)
#
sub PackBinaryFile {
    my $file    = shift || die "$0: No file specified\n";
    my $subname = shift || die "$0: No subname specified\n";
    open( FILE, $file ) || die "Couldnt open $file - $!\n";
    binmode FILE;
    my $imgdata = do { local $/; <FILE> };
    my $uustring = pack "u", $imgdata;
    return <<EOSUB;
sub $subname
{
  return unpack "u", <<'EOIMG';
$uustring
EOIMG
}
EOSUB
}

# PackData($data)
#
# Takes a Perl script, and packs it into
# a single eval() statement
#
sub PackData {
    my $data = shift || die "$0: No data specified\n";
    my $uustring = pack "u", $data;
    return <<EOSUB;
eval unpack "u", <<'EOIMG';
$uustring
EOIMG
EOSUB
}

# random_string($length)
#
# Creates a "random" string
# of the specified length
#
sub random_string {
    my $length = shift || 2;
    my @chars = ( 'a' .. 'z', 'A' .. 'Z' );
    join( '', map { $chars[ rand() * @chars ] } ( 1 .. $length ) );
}

# HashFile($file)
#
# Opens a file, reads it in,
# and returns a MD5 hash
# of the file.
#
sub HashFile {
    my ($filename) = @_;
    open( FILE, $filename ) || die "Couldnt open $filename - $!\n";
    binmode FILE;
    my $fdata = do { local $/; <FILE> };
    close FILE;
    my $md5 = Digest::MD5->new;
    $md5->add($fdata);
    return $md5->hexdigest;

}

# GetFileList($directory)
#
# Returns an array containing all
# the files in a directory, non-
# recursively.
#
sub GetFileList {
    my ($directory_name) = @_;
    my @file_list = ();
    opendir( TDIR, "$directory_name" )
      or die "Error opening directory $directory_name.";
    my @tdir = grep { -f "$directory_name/$_" } readdir(TDIR);
    closedir(TDIR);
    foreach my $ent (@tdir) {
        push( @file_list, "$directory_name/$ent" );
    }
    return @file_list;
}

# foundafile($filename)
#
# Helper sub for GetFileListRecursive()
#
sub foundafile {
    my $filename = $_;
    my $fullpath = $File::Find::name;

    if ( -e $filename ) {
        if ( -f $filename ) {
            push( @rFilelist, $fullpath );
            my $opath = $fullpath;
            $opath =~ s/$basedir/./g;
            push( @oFileList, $opath );
        }

    }
}

# GetFileListRecursive($directory)
#
# Returns an array containing all
# the files in a directory,
# recursively.
#
sub GetFileListRecursive {
    my ($directory_name) = @_;
    $basedir = $directory_name;
    find( \&foundafile, "$directory_name" );
    my @ofl;
    foreach my $fn (@oFileList) {
        if ( $fn ne '.' ) { push( @DirTree, dirname($fn) ) }
    }
    my @cleaned    = ();
    my %duplicates = ();
    @cleaned = grep { !$duplicates{$_}++ } @DirTree;
    @DirTree = @cleaned;
    return @rFilelist;
}

# WriteOutput($stuff_to_write)
#
# Writes output to either STDOUT or to file
#
sub WriteOutput {
    my ($data) = @_;
    if ($output_file) {
        open( FILE, ">>$output_filename" ) or die "Error writing file.";
        print FILE $data;
        close FILE;
    }
    else {
        print "$data";
    }
}

# =================
# POD DOCUMENTATION
# =================

=head1 NAME

SIP (Sip Is not Par) v0.45

=head1 DESCRIPTION

SIP is an archiving tool.  It can combine any number of files into a single Perl script the extracts the files upon execution.

=head1 USAGE

C<$ perl sip.pl [ OPTIONS] file file ...>

Options:

B<-v,--version>

Print version and exit

B<-h,--help>

Print this text

B<-r,--run <file/cmd>>

Execute a script/command after extraction

B<-R,--pre <file/cmd>>

Execute a script/command before extraction

B<-n,--nobanner>

Do not print banner in output script

B<-N,--name <text>>

Changes the displayed name in the banner

B<-s,--silent>

Output script executes silently

B<-p,--text <text>>

Print text at beginning of output script

B<-P,--print <filename>>

Prints the contents of a text file at beginning of output script

B<-m,--md5>

Verify file integrity.  Output script will require Digest::MD5

B<-f,--force>

Force extraction of damaged files

B<-d,--dir <path>>

Add all files in directory to script. To add multiple directories, seperate them by comma.

B<-D,--recursive <path>>

Add all files in directory (recursive) to script.   Directory structure is recreated on extraction. To add multiple directories, seperate them by comma.

B<-t,--temp>

Extract all files to temp directory

B<-l,--location <dir>>

Extract all files to a specific directory

B<-o,--output <filename>>

Write output to file

B<-w,--overwrite>

Automatically overwrite existing files with output

B<-b,--noshebang>

Do NOT add shebang to output script

B<-B,--shebang <text>>

Use another shebang instead of #!/usr/bin/perl

=cut

__DATA__
use strict;
use Digest::MD5;
!FILEPATH
my $file;
my $packed_data;
my $hash;
sub VerifyFile { my($ohash,$filename)=@_; if($ohash==HashFile($filename)) { return 1; } return 0; }
sub HashFile { my($filename)=@_; open( FILE, $filename ) || die "Couldnt open $filename - $!\n"; binmode FILE; my $fdata = do { local $/; <FILE> }; close FILE; my $md5 = Digest::MD5->new; $md5->add($fdata); return $md5->hexdigest; }
!BANNER
%%BREAK%%
use strict;
!FILEPATH
my $file;
my $packed_data;
!BANNER
