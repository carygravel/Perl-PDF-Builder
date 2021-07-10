package PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode;

use strict;
use warnings;
use Carp;
use POSIX;
use base 'PDF::Builder::Basic::PDF::Filter::FlateDecode';

# VERSION
my $LAST_UPDATE = '3.023'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode - compress and uncompress
stream filters for CCITTFax as defined by https://tools.ietf.org/pdf/rfc804.pdf

See also
https://www.itu.int/rec/T-REC-T.4-200307-I/en
https://www.itu.int/rec/T-REC-T.6-198811-I/en
https://www.itu.int/rec/T-REC-T.563-199610-I
https://github.com/jesparza/peepdf/blob/c74dc65c0ac7e506bae4f2582a2435ec50741f40/ccitt.py

=cut

sub codeword{
    my ($bits) = @_;
    return oct("0b" . $bits), length $bits
}

use Readonly;
Readonly my @EOL => codeword('000000000001');
print Dumper(\@EOL);
Readonly my @RTC => codeword('000000000001' x 6);

use Data::Dumper;
Readonly my %WHITE_TERMINAL_ENCODE_TABLE => {
    0   => [codeword('00110101')],
        1   => [codeword('000111')],
        2   => [codeword('0111')],
        3   => [codeword('1000')],
        4   => [codeword('1011')],
        5   => [codeword('1100')],
        6   => [codeword('1110')],
        7   => [codeword('1111')],
        8   => [codeword('10011')],
        9   => [codeword('10100')],
        10  => [codeword('00111')],
        11  => [codeword('01000')],
        12  => [codeword('001000')],
        13  => [codeword('000011')],
        14  => [codeword('110100')],
        15  => [codeword('110101')],
        16  => [codeword('101010')],
        17  => [codeword('101011')],
        18  => [codeword('0100111')],
        19  => [codeword('0001100')],
        20  => [codeword('0001000')],
        21  => [codeword('0010111')],
        22  => [codeword('0000011')],
        23  => [codeword('0000100')],
        24  => [codeword('0101000')],
        25  => [codeword('0101011')],
        26  => [codeword('0010011')],
        27  => [codeword('0100100')],
        28  => [codeword('0011000')],
        29  => [codeword('00000010')],
        30  => [codeword('00000011')],
        31  => [codeword('00011010')],
        32  => [codeword('00011011')],
        33  => [codeword('00010010')],
        34  => [codeword('00010011')],
        35  => [codeword('00010100')],
        36  => [codeword('00010101')],
        37  => [codeword('00010110')],
        38  => [codeword('00010111')],
        39  => [codeword('00101000')],
        40  => [codeword('00101001')],
        41  => [codeword('00101010')],
        42  => [codeword('00101011')],
        43  => [codeword('00101100')],
        44  => [codeword('00101101')],
        45  => [codeword('00000100')],
        46  => [codeword('00000101')],
        47  => [codeword('00001010')],
        48  => [codeword('00001011')],
        49  => [codeword('01010010')],
        50  => [codeword('01010011')],
        51  => [codeword('01010100')],
        52  => [codeword('01010101')],
        53  => [codeword('00100100')],
        54  => [codeword('00100101')],
        55  => [codeword('01011000')],
        56  => [codeword('01011001')],
        57  => [codeword('01011010')],
        58  => [codeword('01011011')],
        59  => [codeword('01001010')],
        60  => [codeword('01001011')],
        61  => [codeword('00110010')],
        62  => [codeword('00110011')],
        63  => [codeword('00110100')],
        };
print Dumper(\%WHITE_TERMINAL_ENCODE_TABLE);

Readonly my %WHITE_TERMINAL_DECODE_TABLE => map { $WHITE_TERMINAL_ENCODE_TABLE{$_}[0].' '. $WHITE_TERMINAL_ENCODE_TABLE{$_}[1] => $_ } keys %WHITE_TERMINAL_ENCODE_TABLE;
print Dumper(\%WHITE_TERMINAL_DECODE_TABLE);

Readonly my %BLACK_TERMINAL_ENCODE_TABLE => {
        0   => [codeword('0000110111')],
        1   => [codeword('010')],
        2   => [codeword('11')],
        3   => [codeword('10')],
        4   => [codeword('011')],
        5   => [codeword('0011')],
        6   => [codeword('0010')],
        7   => [codeword('00011')],
        8   => [codeword('000101')],
        9   => [codeword('000100')],
        10  => [codeword('0000100')],
        11  => [codeword('0000101')],
        12  => [codeword('0000111')],
        13  => [codeword('00000100')],
        14  => [codeword('00000111')],
        15  => [codeword('000011000')],
        16  => [codeword('0000010111')],
        17  => [codeword('0000011000')],
        18  => [codeword('0000001000')],
        19  => [codeword('00001100111')],
        20  => [codeword('00001101000')],
        21  => [codeword('00001101100')],
        22  => [codeword('00000110111')],
        23  => [codeword('00000101000')],
        24  => [codeword('00000010111')],
        25  => [codeword('00000011000')],
        26  => [codeword('000011001010')],
        27  => [codeword('000011001011')],
        28  => [codeword('000011001100')],
        29  => [codeword('000011001101')],
        30  => [codeword('000001101000')],
        31  => [codeword('000001101001')],
        32  => [codeword('000001101010')],
        33  => [codeword('000001101011')],
        34  => [codeword('000011010010')],
        35  => [codeword('000011010011')],
        36  => [codeword('000011010100')],
        37  => [codeword('000011010101')],
        38  => [codeword('000011010110')],
        39  => [codeword('000011010111')],
        40  => [codeword('000001101100')],
        41  => [codeword('000001101101')],
        42  => [codeword('000011011010')],
        43  => [codeword('000011011011')],
        44  => [codeword('000001010100')],
        45  => [codeword('000001010101')],
        46  => [codeword('000001010110')],
        47  => [codeword('000001010111')],
        48  => [codeword('000001100100')],
        49  => [codeword('000001100101')],
        50  => [codeword('000001010010')],
        51  => [codeword('000001010011')],
        52  => [codeword('000000100100')],
        53  => [codeword('000000110111')],
        54  => [codeword('000000111000')],
        55  => [codeword('000000100111')],
        56  => [codeword('000000101000')],
        57  => [codeword('000001011000')],
        58  => [codeword('000001011001')],
        59  => [codeword('000000101011')],
        60  => [codeword('000000101100')],
        61  => [codeword('000001011010')],
        62  => [codeword('000001100110')],
        63  => [codeword('000001100111')],
        };

Readonly my %BLACK_TERMINAL_DECODE_TABLE => map { $BLACK_TERMINAL_ENCODE_TABLE{$_}[0].' '. $BLACK_TERMINAL_ENCODE_TABLE{$_}[1] => $_ } keys %BLACK_TERMINAL_ENCODE_TABLE;

Readonly my %WHITE_CONFIGURATION_ENCODE_TABLE => {
        64    => [codeword('11011')],
        128   => [codeword('10010')],
        192   => [codeword('010111')],
        256   => [codeword('0110111')],
        320   => [codeword('00110110')],
        384   => [codeword('00110111')],
        448   => [codeword('01100100')],
        512   => [codeword('01100101')],
        576   => [codeword('01101000')],
        640   => [codeword('01100111')],
        704   => [codeword('011001100')],
        768   => [codeword('011001101')],
        832   => [codeword('011010010')],
        896   => [codeword('011010011')],
        960   => [codeword('011010100')],
        1024  => [codeword('011010101')],
        1088  => [codeword('011010110')],
        1152  => [codeword('011010111')],
        1216  => [codeword('011011000')],
        1280  => [codeword('011011001')],
        1344  => [codeword('011011010')],
        1408  => [codeword('011011011')],
        1472  => [codeword('010011000')],
        1536  => [codeword('010011001')],
        1600  => [codeword('010011010')],
        1664  => [codeword('011000')],
        1728  => [codeword('010011011')],

        1792  => [codeword('00000001000')],
        1856  => [codeword('00000001100')],
        1920  => [codeword('00000001001')],
        1984  => [codeword('000000010010')],
        2048  => [codeword('000000010011')],
        2112  => [codeword('000000010100')],
        2176  => [codeword('000000010101')],
        2240  => [codeword('000000010110')],
        2340  => [codeword('000000010111')],
        2368  => [codeword('000000011100')],
        2432  => [codeword('000000011101')],
        2496  => [codeword('000000011110')],
        2560  => [codeword('000000011111')],
        };

Readonly my %WHITE_CONFIGURATION_DECODE_TABLE => map { $WHITE_CONFIGURATION_ENCODE_TABLE{$_}[0].' '. $WHITE_CONFIGURATION_ENCODE_TABLE{$_}[1] => $_ } keys %WHITE_CONFIGURATION_ENCODE_TABLE;

Readonly my %BLACK_CONFIGURATION_ENCODE_TABLE => {
        64    => [codeword('0000001111')],
        128   => [codeword('000011001000')],
        192   => [codeword('000011001001')],
        256   => [codeword('000001011011')],
        320   => [codeword('000000110011')],
        384   => [codeword('000000110100')],
        448   => [codeword('000000110101')],
        512   => [codeword('0000001101100')],
        576   => [codeword('0000001101101')],
        640   => [codeword('0000001001010')],
        704   => [codeword('0000001001011')],
        768   => [codeword('0000001001100')],
        832   => [codeword('0000001001101')],
        896   => [codeword('0000001110010')],
        960   => [codeword('0000001110011')],
        1024  => [codeword('0000001110100')],
        1088  => [codeword('0000001110101')],
        1152  => [codeword('0000001110110')],
        1216  => [codeword('0000001110111')],
        1280  => [codeword('0000001010010')],
        1344  => [codeword('0000001010011')],
        1408  => [codeword('0000001010100')],
        1472  => [codeword('0000001010101')],
        1536  => [codeword('0000001011010')],
        1600  => [codeword('0000001011011')],
        1664  => [codeword('0000001100100')],
        1728  => [codeword('0000001100101')],

        1792  => [codeword('00000001000')],
        1856  => [codeword('00000001100')],
        1920  => [codeword('00000001001')],
        1984  => [codeword('000000010010')],
        2048  => [codeword('000000010011')],
        2112  => [codeword('000000010100')],
        2176  => [codeword('000000010101')],
        2240  => [codeword('000000010110')],
        2340  => [codeword('000000010111')],
        2368  => [codeword('000000011100')],
        2432  => [codeword('000000011101')],
        2496  => [codeword('000000011110')],
        2560  => [codeword('000000011111')],
        };

Readonly my %BLACK_CONFIGURATION_DECODE_TABLE => map { $BLACK_CONFIGURATION_ENCODE_TABLE{$_}[0].' '. $BLACK_CONFIGURATION_ENCODE_TABLE{$_}[1] => $_ } keys %BLACK_CONFIGURATION_ENCODE_TABLE;

sub new {
    my ($class) = @_;
    my $self = {};
    $self->{decoded} = [];
    return bless $self, $class;
}

sub encode{
    my ($self, $stream, $rows, $columns, %config) = @_;
    my $k = $config{k} // 0;  # // is defined-or, added in Perl 5.10.
    my $eol = $config{eol} // 1;
    my $byteAlign = $config{byteAlign} // 0;
#    $columns = $config{columns} // 1728;
#    $rows = $config{rows} // 0;
    my $eob = $config{eob} // 1;
    my $blackIs1 = $config{blackIs1} // 0;
    my $damagedRowsBeforeError = $config{damagedRowsBeforeError} // 0;
    $byteAlign = 1; # FIXME: this overwrites the value passed to the sub
    $stream = unpack('B*', $stream);
    print "in encode with $stream\n";
    my ($white, $black) = (1,0);
    if ($blackIs1) {
        ($white, $black) = (0,1)
    }
    my $bitw = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Bit::Writer->new();
    my $pos = 0;
    my $col = 0;
    my $rowend = $columns;
    my ($current_color, $next_color) = ($white, $black);
    print "before eol ", sprintf("%0$EOL[1]b", $EOL[0]), "\n";
    $bitw->write( sprintf("%0$EOL[1]b", $EOL[0]), $byteAlign );

    while ($pos < $rowend) {
        print "in while pos $pos\n";
        my $codelen;
        if ($current_color == $white) {
            ($codelen, $pos) = $self->encode_white_bits($stream, $pos, $rowend, $current_color);
        }
        else {
            ($codelen, $pos) = $self->encode_black_bits($stream, $pos, $rowend, $current_color);
        }
        my ($code, $len) = @{$codelen};
        $bitw->write( sprintf("%0$len".'b', $code) );
        ($current_color, $next_color) = ($next_color, $current_color);
    }
    $bitw->flush;
    return $bitw->{data}
}

sub encode_white_bits{
#    my ($self, $bitr, $rowend, $color)=@_;
    my ($self, $stream, $pos, $rowend, $color)=@_;
    print "in encode_white_bits at $pos\n";
#    return $self->encode_color_bits( $bitr, \%WHITE_CONFIGURATION_ENCODE_TABLE, \%WHITE_TERMINAL_ENCODE_TABLE )
    return $self->encode_color_bits( $stream, $pos, $rowend, \%WHITE_CONFIGURATION_ENCODE_TABLE, \%WHITE_TERMINAL_ENCODE_TABLE, $color )
}

sub encode_black_bits{
#    my ($self, $bitr, $color)=@_;
    my ($self, $stream, $pos, $rowend, $color)=@_;
    print "in encode_black_bits at $pos\n";
#    return $self->encode_color_bits( $bitr, \%BLACK_CONFIGURATION_ENCODE_TABLE, \%BLACK_TERMINAL_ENCODE_TABLE )
    return $self->encode_color_bits( $stream, $pos, $rowend, \%BLACK_CONFIGURATION_ENCODE_TABLE, \%BLACK_TERMINAL_ENCODE_TABLE, $color )
}

sub encode_color_bits{
#    my ($self, $bitr, $config_words, $term_words, $color)=@_;
    my ($self, $stream, $pos, $rowend, $config_words, $term_words, $color)=@_;
    print "in encode_color_bits with $stream, pos $pos, rowend $rowend, color $color\n";
    my $bits = 0;
    my $check_conf = 1;

    my $run = $pos;
    while ($run < length($stream) and $run < $rowend) {
#    while ($run < length($stream)) {
        if (substr($stream, $run, 1) ne $color or $run == $rowend) {
#        if (substr($stream, $run, 1) ne $color) {
            print "returning from encode_color_bits with ", $run-$pos, " bits\n";
            return $term_words->{$run-$pos}, $run
        }
        ++$run;
    }
    print "returning from encode_color_bits with ", $run-$pos, " bits\n";
    return $term_words->{$run-$pos}, $run
}

sub decode{
    my ($self, $stream, $rows, $columns, %config) = @_;
    print "in decode with ", unpack('B*', $stream), "\n";
    my $k = $config{k} // 0;  # // is defined-or, added in Perl 5.10.
    my $eol = $config{eol} // 1;
    my $byteAlign = $config{byteAlign} // 0;
#    $columns = $config{columns} // 1728;
#    $rows = $config{rows} // 0;
    my $eob = $config{eob} // 1;
    my $blackIs1 = $config{blackIs1} // 0;
    my $damagedRowsBeforeError = $config{damagedRowsBeforeError} // 0;
    $byteAlign = 1; # FIXME: this overwrites the value passed to the sub
        
    my ($white, $black) = (1,0);
    if ($blackIs1) {
        ($white, $black) = (0,1)
    }            
    my $bitr = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Bit::Reader->new( $stream );
    my $bitw = PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Bit::Writer->new();

    print "before while rows=$rows. eod_p ", $bitr->eod_p(), "\n";
    print "bitr->eod_p() or $rows == 0 ", ($bitr->eod_p() or $rows == 0) ? 1 : 0, "\n";
    print "not (bitr->eod_p() or $rows == 0) ", not ($bitr->eod_p() or $rows == 0) ? 1 : 0, "\n";
    while (not ( $bitr->eod_p() or $rows == 0 )){
        print "in while\n";
        my $current_color = $white;
        if ($byteAlign and $bitr->pos % 8 != 0){
            $bitr->pos += 8 - ($bitr->pos % 8)
        }

        use Data::Dumper;
        print "RTC ", Dumper(\@RTC);
        print "before peek eob $eob rtc 0 $RTC[0] rtc 1 $RTC[1]\n";
        if ($eob and $bitr->pos + $RTC[1] <= $bitr->size and $bitr->peek($RTC[1]) == $RTC[0]){
            $bitr->pos += $RTC[1];
            last
        }

        print "before peek eol ", Dumper(\@EOL);
        my $peek_size = $EOL[1];
        if ($byteAlign) {
            $peek_size += $peek_size % 8
        }
        if ($bitr->peek($peek_size) == $EOL[0]){
            print "got eol. before pos update ", $bitr->pos, "\n";
            $bitr->pos($bitr->pos + $peek_size);
            print "after pos update ", $bitr->pos, "\n";
        }
        else{
            print "no eol at ", $bitr->pos, "\n";
            if ($eol){
                croak "No end-of-line pattern found (at bit pos ", $bitr->pos, "/", $bitr->size, ")";
            }
        }

        my $line_length = 0;
        while ($line_length < $columns){
            my $bit_length;
            if ($current_color == $white){
                $bit_length = $self->decode_white_bits($bitr)
            }
            else{
                $bit_length = $self->decode_black_bits($bitr)
            }
            if (not defined $bit_length){
                croak "Unfinished line (at bit pos ", $bitr->pos, '/', $bitr->size, ") , $bitw->{data}"
            }
            $line_length += $bit_length;
            if ($line_length > $columns){
                croak "Line is too long (at bit pos $bitr->pos/$bitr->size)"
            }

#            $bitw->write_run( ($current_color << $bit_length) - $current_color, $bit_length );
            if ($bit_length > 0) {
                $bitw->write_run( $current_color, $bit_length );
            }

            $current_color ^= 1
        }

        $rows -= 1
    }
    $bitw->flush;
    print "returning from decode with ", unpack('B*', $bitw->{data}), "\n";
    return $bitw->{data}
}

sub decode_white_bits{
    my ($self, $bitr)=@_;
    print "in decode_white_bits\n";
    return $self->decode_color_bits( $bitr, \%WHITE_CONFIGURATION_DECODE_TABLE, \%WHITE_TERMINAL_DECODE_TABLE )
}

sub decode_black_bits{
    my ($self, $bitr)=@_;
    print "in decode_black_bits\n";
    return $self->decode_color_bits( $bitr, \%BLACK_CONFIGURATION_DECODE_TABLE, \%BLACK_TERMINAL_DECODE_TABLE )
}

sub decode_color_bits{
    my ($self, $bitr, $config_words, $term_words)=@_;
    my $bits = 0;
    my $check_conf = 1;

    while ($check_conf){
        $check_conf = 0;

#        for my $i (2.. 14){
#            my $codeword = $bitr->peek($i);
#            print "checking '$codeword $i'\n";
#            print Dumper($config_words);
#            my $config_value = $config_words->{"$codeword $i"};
#            if (defined $config_value){
#                print "found $config_value\n";
#                $bitr->pos += $i;
#                $bits += $config_value;
#                if ($config_value == 2560){
#                    $check_conf = 1
#                }
#                last
#            }
#            else {
#                print "not found\n";
#            }
#        }
        for my $i (2.. 14){
            my $codeword = $bitr->peek($i);
            my $term_value = $term_words->{"$codeword $i"};
            if (defined $term_value){
                $bitr->pos($bitr->pos + $i);
                $bits += $term_value;
                print "returning $bits bits\n";
                return $bits
              }
        }
    }
    return
}

package PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Bit::Writer;

use strict;
use warnings;
use Carp;

sub new {
    my ($class) = @_;
    my $self = {};
    $self->{data} = '';
    $self->{last_byte} = '';
    return bless $self, $class;
}

sub write {
    my ($self, $data, $byteAlign) = @_;
    my $length = length($data);
    print "in write with data $data length $length at last_byte $self->{last_byte}\n";

    my $pad = ($length + length($self->{last_byte})) % 8;
    print "pad $pad\n";
    if ($byteAlign and $pad != 0){
        $data = ('0' x $pad).$data;
        $length = length($data);
        print "padded to data $data length $length at last_byte $self->{last_byte}\n";
    }

    if ($length == 8 and $self->{last_byte} eq '') {
        $self->{data} .= pack('B*', $data);
        return
    }

    while ($length > 0){
        print "data $data length $length packed", pack('B*', $self->{data}), " last_byte $self->{last_byte}\n";
        my $buflen = 8 - length $self->{last_byte};
        if ($length >= $buflen) {
            print ">=8\n";
#            $self->{last_byte} |= ($data >> $length) & ((1 << (8 - $self->{bit_ptr})) - 1);
            $self->{last_byte} .= substr($data, 0, $buflen);
            $length -= $buflen;
            $data = substr $data, $buflen;

#            $data &= (1 << $length) - 1;
#            $self->{data} .= chr($self->{last_byte});
            $self->{data} .= pack('B*', $self->{last_byte});
            $self->{last_byte} = '';
        }
        else {
            print "<8\n";
#            if ($self->{last_byte} eq '') {
#                $self->{last_byte} = 0;
#                $self->{last_byte} = pack('B*', '00000000');
#                print "init last_byte $self->{last_byte}\n";
#            }
#            $self->{last_byte} |= ($data & ((1 << $length) - 1)) << (8 - $self->{bit_ptr} - $length);
            $self->{last_byte} .= $data;

            if (length($self->{last_byte}) == 8){
#                $self->{data} += chr($self->{last_byte});
                $self->{data} .= pack('B*', $self->{last_byte});
                $self->{last_byte} = '';
            }

            $length = 0;
        }
    }
    print "after data ", pack('B*', $self->{data}), " last_byte $self->{last_byte}\n";
    return;
}
    
sub write_run {
    my ($self, $data, $length) = @_;
    print "in write_run with data $data length $length last_byte $self->{last_byte}\n";
    $self->write($data x $length);
    print "after last_byte $self->{last_byte}\n";
    return;
}

sub flush {
    my ($self) = @_;
    if (length $self->{last_byte} > 0) {
        $self->write_run('0', 8 - length $self->{last_byte});
    }
    return;
}

package PDF::Builder::Basic::PDF::Filter::CCITTFaxDecode::Bit::Reader;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $data) = @_;
    print "in new with ", unpack('B*', $data), "\n";
    my $self = {};
    $self->{data} = $data;
    ($self->{byte_ptr}, $self->{bit_ptr}) = (0, 0);
    return bless $self, $class;
}

sub reset {
    my ($self) = @_;
    ($self->{byte_ptr}, $self->{bit_ptr}) = (0, 0)
}

sub eod_p {
    my ($self) = @_;
    use Data::Dumper;
    print "eod_p returning ", $self->{byte_ptr} >= length $self->{data} ? 1 : 0, "\n";
    return $self->{byte_ptr} >= length $self->{data}
}

sub size {
    my ($self) = @_;
    print "bytes ", length($self->{data}), "\n";
    print "size returning ", length($self->{data}) << 3, "\n";
    return length($self->{data}) << 3
}

sub pos {
    my ($self, $bits) = @_;
    # getter
    if (not defined $bits){
        return ($self->{byte_ptr} << 3) + $self->{bit_ptr}
    }
    # setter
    if ($bits > $self->size) {
        croak "Pointer position out of data"
    }

    my $pbyte = $bits >> 3;
    my $pbit = $bits - ($pbyte <<3);
    ($self->{byte_ptr}, $self->{bit_ptr}) = ($pbyte, $pbit);
    return;
}

sub peek {
    my ($self, $length) = @_;
    print "peeking length $length from pos ", $self->pos, " available ", $self->size, "\n";
    if ($length <= 0){
        croak "Invalid read length"
    }
    elsif (( $self->pos + $length ) > $self->size){
        croak "Insufficient data"
    }

    my $n = 0;
    my ($byte_ptr, $bit_ptr) = ($self->{byte_ptr}, $self->{bit_ptr});

    while ($length > 0){
        my $byte = ord( substr($self->{data}, $byte_ptr, 1) );

        if ($length > 8 - $bit_ptr){
            $length -= 8 - $bit_ptr;
            $n |= ( $byte & ((1 << (8 - $bit_ptr)) - 1) ) << $length;

            $byte_ptr += 1;
            $bit_ptr = 0;
        }
        else {
            $n |= ($byte >> (8 - $bit_ptr - $length)) & ((1 << $length) - 1);
            $length = 0
        }
    }
    print "peek returning $n\n";
    return $n
}

sub read {
    my ($self, $length) = @_;
    my $n = $self->peek($length);
    $self->pos += $length;
    return $n
}

1;
