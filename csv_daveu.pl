#!/opt/local/bin/perl

use strict;
use warnings;

use Time::Local;
use POSIX;
use Encode;
use utf8;

# NOTES and areas to refine if this script is used in the future.
# I'm not certain I've captured utf-8 validation corectly, 
# I have not used utf-8 data streams before
# Also, this could use more error checking for invalid or null entries, especially 
# for the entries performing math operations on time/date values.
 
# Capture and print header line of CSV input, this does not need to be parsed
# like the rest of the lines in the input stream.
my $header = <STDIN>;

print $header;

# expected header, parsing will be based on these fields in this order:
# Timestamp,Address,ZIP,FullName,FooDuration,BarDuration,TotalDuration,Notes

# initialize variables.
my $line = "";          # each line of input stream
my @entries = ();       # array of each line split on commas (rejoin some values)
my $raw_timestamp = ""; # original timestamp in stream.
my $final_timestamp = ""; # converted timestamp for output.
my $address;              # address value (may need rejoin due to commas in values
my $raw_zip;            # Raw zip code 
my $val_zip;            # validated zip code (pad with leading 0 if needed)
my $raw_name;           # Raw name (may include utf-8
my $val_name;           # upper case name.  not certain utf-8 values translate correctly
my $foo_dur;            # foo duration, convert to floating point seconds value
my $bar_dur;            # bar duration, convert to floating point seconds value
my $tot_dur;            # total duration, addition of foo and bar
my $notes;              # last value in stream, free format, do not change, may have comma
my $first_char;         # pull first char, to check for quotes (comma in value).

# Process body of CSV input

while ($line = <STDIN>) {

# utf validation of whole line, uncertain if this is best approach:
$line = Encode::encode( 'UTF-8', $line );

# basic split of line into values seperated by commas
@entries = split(/,/ , $line);

# Proccess timestamp, incoming pacific time, outgoing Eastern time.
$raw_timestamp = shift(@entries);
$final_timestamp = &timestamp_conv($raw_timestamp);

# Process address, possible comma in string, and utf-8 validation
$address = shift(@entries);
# Check for " as first char, indicating comma protected by quote.
$first_char = substr $address,0,1;
# Perhaps change this to regex to capture single and double quote?
if ("$first_char" eq'"') {
   while (substr($address,-1,1) ne '"' ) {
      $address = $address . ",";
      $address = $address . shift(@entries);
   }
}

# Zip code, insure 5 character, prepend with 0 if less than 5 chars
$raw_zip = shift(@entries);

$val_zip = sprintf("%05d",$raw_zip);

# upper case name:
# Using single var here, again, possibly do better translation and error checking here.
$raw_name = shift(@entries);
$val_name = decode( 'UTF-8', $raw_name );
$val_name = uc $val_name;
# $val_name = encode( 'UTF-8', $val_name );

# The columns `FooDuration` and `BarDuration` are in HH:MM:SS.MS
#  format (where MS is milliseconds); please convert them to a floating
#  point seconds format.
# The column "TotalDuration" is filled with garbage data. For each
#  row, please replace the value of TotalDuration with the sum of
#  FooDuration and BarDuration.
$foo_dur = shift(@entries);
$foo_dur = &dur_conv($foo_dur);

$bar_dur = shift(@entries);
$bar_dur = &dur_conv($bar_dur);
# Throw away total duration, replace with sub of foo and bar duration
$tot_dur = shift(@entries);
$tot_dur = $bar_dur + $foo_dur;

# convert to floating point strings, 3 points after decimal:
$foo_dur = sprintf("%.3f", $foo_dur / 1000 );
$bar_dur = sprintf("%.3f", $bar_dur / 1000 );
$tot_dur = sprintf("%.3f", $tot_dur / 1000 );

# Process notes, possible comma in string, possible no notes at all but at least the 
# end of line (\n) character, 
# Just pull the rest of the array from the split until the array is empty, 
# adding commas back in as needed to restore to original.
if ( @entries ) {
   $notes = shift(@entries) ;
   while ( @entries ) {
      $notes = $notes . ",";
      $notes = $notes . shift(@entries);
   }
}

# output values, all translations done, if error checking to be added, insert here
# if wanted to not print some lines or go to STDERR;

print "$final_timestamp,$address,$val_zip,$val_name,$foo_dur,$bar_dur,$tot_dur,$notes";

}


#   functions:

# Duration conversion, one arg, parse the time in HH:MM:SS.MS format
# return the time in milliseconds, divide by 1000 and floating point value
# handled in main body so that easier to do math for total duration.
# That formatting could have been done here.
# also, could improve checking for miss-formated values. If bad value, should return
# some error to go STDERR and some signal that this line should be skipped.

sub dur_conv()  {

my ($in_t) = @_;  # incoming arg
my $ms = 0;       # milliseconds
my $ss = 0;       # Seconds
my $mm = 0;       # Minutes
my $hh = 0;       # Hours
my $retval;       # retval (in milliseconds)

# conversion, 1000 secs in millisec, then 60 time for mm and hours
# MS = 1
# SS = 1000
# MM = 60000
# HH = 36000000

($hh, $mm, $ss, $ms) = ($in_t =~ m/(\d+):(\d+):(\d+).(\d+)/ );

$hh = $hh * 36000000;
$mm = $mm * 60000;
$ss = $ss * 1000;

$retval = $hh + $mm + $ss + $ms;
return $retval;

}

# The Timestamp column should be formatted in ISO-8601 format.
# The Timestamp column should be assumed to be in US/Pacific time;
#   please convert it to US/Eastern.
# Takes on incoming arg, the original timestamp, returns Eastern Time ISO-8601 format.
# depends on POSIX and Time::Local standard libs for strftime and timelocal

sub timestamp_conv()  {
my ($in_t) = @_;

my $yy;      # Year
my $mm;      # month
my $dd;      # Day
my $hour;    # hour
my $min;     # minutes
my $sec;     # seconds
my $pm = ""; # am/pm value
my $epoch_seconds ;  # seconds since epoch, for doing math and re-convert to human readable


($mm, $dd, $yy, $hour, $min, $sec, $pm) = ($in_t =~ m|(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+) ([AP])| );
# calculate epoch seconds at midnight on that day in this timezone
# Correct month to 0-11 not 1-12
$mm--;
# correct hour values, add pm, change hour 24 to hour 0
$hour += 12 if ( "$pm" eq "P");
$hour = 0 if ( "$hour" eq "24");
$epoch_seconds = timelocal($sec, $min, $hour, $dd, $mm, $yy);

# adjust from Pacfic to Eastern time, add 3 hours (60 sec * 60 minute * 60 hour * 3 TMZ )
# Since we use localtime for both conversions, should work out regardless or timezone 
# user.

$epoch_seconds += 10800;

# 1994-11-05T08:15:30-05:00
return strftime('%Y-%m-%dT%H:%M:%S-05:00', localtime($epoch_seconds));

}
