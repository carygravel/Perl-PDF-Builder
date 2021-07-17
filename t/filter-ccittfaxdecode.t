#!/usr/bin/perl
use warnings;
use strict;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode;
use Test::More tests => 6;

my $filter = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode->new();

# group 3, 1 row, 6 columns
my $in = pack('B*', '10101000');
my $out = pack('B*', '00000000000000010011010101000011101000011101000011100000');
# runlengths          |Pad|   EOL    || 0W   |1B|| 1W |1B|| 1W |1B|| 1W ||Pad|
# byte markers               |       |       |       |       |       |       |
is $filter->decode_group3($out, 1, 6, blackIs1=>1), $in, '1 row of CCITTFaxDecode group 3 decoded correctly';
#is $filter->encode_group3($in, 1, 6, blackIs1=>1), $out, '1 row of CCITTFaxDecode group 3 encoded correctly';
is unpack('B*',$filter->encode_group3($in, 1, 6, blackIs1=>1)), unpack('B*',$out), '1 row of CCITTFaxDecode group 3 encoded correctly';

# group 3, 2 row, 6 columns
$in = pack('B*', '1010100001010100');
#                 |  r1  ||  r2  |
$out = pack('B*', '000000000000000100110101010000111010000111010000111000000000000100011101000011101000011101000000');
# runlengths       |Pad|   EOL    || 0W   |1B|| 1W |1B|| 1W |1B|| 1W |P|   EOL    || 1W |1B|| 1W |1B|| 1W |1B|pad |
# byte markers            |       |       |       |       |       |       |       |       |       |       |       |
#is $filter->decode_group3($out, 2, 6, blackIs1=>1), $in, '2 rows of CCITTFaxDecode group 3 decoded correctly';
is unpack('B*',$filter->decode_group3($out, 2, 6, blackIs1=>1)), unpack('B*',$in), '2 rows of CCITTFaxDecode group 3 decoded correctly';
#is $filter->encode_group3($in, 2, 6, blackIs1=>1), $out, '2 rows of CCITTFaxDecode group 3 encoded correctly';
is unpack('B*',$filter->encode_group3($in, 2, 6, blackIs1=>1)), unpack('B*',$out), '2 rows of CCITTFaxDecode group 3 encoded correctly';

# this is group 4, 1 row, 6 columns
# starts with white, so would expect to start with a white run with 0 length "00110101", then 1 black "010"
$in = pack('B*', '10101000');
$out = pack('B*', '0010011010101000100011101000001001010000000000010000000000010000');
#                  |H|| 0W   |1B||H|| 1W |1B||VL2 |VL1V0       EOFB           |pad|
# byte markers            |       |       |       |       |       |       |       |
#is $filter->decode_group4($out, 1, 6, blackIs1=>1), $in, '1 row of CCITTFaxDecode group 4 decoded correctly';
is unpack('B*',$filter->decode_group4($out, 1, 6, blackIs1=>1)), unpack('B*',$in), '1 row of CCITTFaxDecode group 4 decoded correctly';
#is $filter->encode_group4($in, 2, 6, blackIs1=>1), $out, '2 rows of CCITTFaxDecode group 3 encoded correctly';
is unpack('B*',$filter->encode_group4($in, 1, 6, blackIs1=>1)), unpack('B*',$out), '1 rows of CCITTFaxDecode group 4 encoded correctly';
