#!/usr/bin/perl
use warnings;
use strict;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode;
use Test::More tests => 2;

my $filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new();

# this is group 3, 1 row, 6 columns
my $in = pack('B*', '10101000');
my $out = pack('B*', '00000000000000010011010101000011101000011101000011100000');
# runlengths          |Pad|   EOL    || 0W   |1B|| 1W |1B|| 1W |1B|| 1W ||Pad|
# byte markers               |       |       |       |       |       |       |
is $filter->decode($out, 1, 6, blackIs1=>1), $in, 'CCITTFaxDecode decoded correctly';
#is $filter->encode($in, 1, 6, blackIs1=>1), $out, 'CCITTFaxDecode encoded correctly';
is unpack('B*',$filter->encode($in, 1, 6, blackIs1=>1)), unpack('B*',$out), 'CCITTFaxDecode encoded correctly';

# this is group 4, 1 row, 6 columns
# starts with white, so would expect to start with a white run with 0 length "00110101", then 1 black "010"
#my $out = pack('B*', '0010011010101000100011101000001001010000000000010000000000010000');
#                        | 0W   |1B|   | 1W |1B|
#                          26      51   11   6
