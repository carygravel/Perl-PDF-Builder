#!/usr/bin/perl
use warnings;
use strict;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode;
use Test::More tests => 5;

my $filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new();

# group 3, 1 row, 6 columns
my $in = pack('B*', '10101000');
my $out = pack('B*', '00000000000000010011010101000011101000011101000011100000');
# runlengths          |Pad|   EOL    || 0W   |1B|| 1W |1B|| 1W |1B|| 1W ||Pad|
# byte markers               |       |       |       |       |       |       |
is $filter->decode($out, 1, 6, blackIs1=>1), $in, '1 row of CCITTFaxDecode group 3 decoded correctly';
#is $filter->encode($in, 1, 6, blackIs1=>1), $out, '1 row of CCITTFaxDecode group 3 encoded correctly';
is unpack('B*',$filter->encode($in, 1, 6, blackIs1=>1)), unpack('B*',$out), '1 row of CCITTFaxDecode group 3 encoded correctly';

# group 3, 2 row, 6 columns
$in = pack('B*', '1010100001010100');
#                 |  r1  ||  r2  |
$out = pack('B*', '000000000000000100110101010000111010000111010000111000000000000100011101000011101000011101000000');
# runlengths       |Pad|   EOL    || 0W   |1B|| 1W |1B|| 1W |1B|| 1W |P|   EOL    || 1W |1B|| 1W |1B|| 1W |1B|pad |
# byte markers            |       |       |       |       |       |       |       |       |       |       |       |
#                                                                48 51
#is $filter->decode($out, 2, 6, blackIs1=>1), $in, '2 rows of CCITTFaxDecode group 3 decoded correctly';
is unpack('B*',$filter->decode($out, 2, 6, blackIs1=>1)), unpack('B*',$in), '2 rows of CCITTFaxDecode group 3 decoded correctly';
#is $filter->encode($in, 2, 6, blackIs1=>1), $out, '2 rows of CCITTFaxDecode group 3 encoded correctly';
is unpack('B*',$filter->encode($in, 2, 6, blackIs1=>1)), unpack('B*',$out), '2 rows of CCITTFaxDecode group 3 encoded correctly';

# this is group 4, 1 row, 6 columns
# starts with white, so would expect to start with a white run with 0 length "00110101", then 1 black "010"
$in = pack('B*', '10101000');
$out = pack('B*', '0010011010101000100011101000001001010000000000010000000000010000');
#                  | 0W   |1B|   | 1W |1B|
#                    26      51   11   6
is $filter->decode($out, 1, 6, blackIs1=>1), $in, '1 row of CCITTFaxDecode group 4 decoded correctly';
