#!/usr/bin/perl
use warnings;
use strict;
use English qw( -no_match_vars );
use IPC::Cmd qw(can_run run);
use File::Spec;
use Test::More tests => 12;

use PDF::Builder;

# Filename 3 tests ------------------
# tests 1 and 3 will mention TIFF_GT if Graphics::TIFF is installed and
# usable, otherwise they will display just TIFF. you can use this information
# if you are not sure about the status of Graphics::TIFF.

my $pdf = PDF::Builder->new('-compress' => 'none'); # common $pdf all tests
my $has_GT = 0; # global flag for all tests that need to know if Graphics::TIFF

# -silent shuts off one-time warning for rest of run
my $tiff = $pdf->image_tiff('t/resources/1x1.tif', -silent => 1);
if ($tiff->usesLib() == 1) {
    $has_GT = 1;
    isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF_GT',
        q{$pdf->image_tiff(filename)});
} else {
    isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
        q{$pdf->image_tiff(filename)});
}

is($tiff->width(), 1,
   q{Image from filename has a width});

my $gfx = $pdf->page()->gfx();
$gfx->image($tiff, 72, 144, 216, 288);
like($pdf->stringify(), qr/q 216 0 0 288 72 144 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Filehandle (old library only)  2 tests ------------------

$pdf = PDF::Builder->new();
open my $fh, '<', 't/resources/1x1.tif' or
   die "Couldn't open file t/resources/1x1.tif";
$tiff = $pdf->image_tiff($fh, -nouseGT => 1);
isa_ok($tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
    q{$pdf->image_tiff(filehandle)});

is($tiff->width(), 1,
   q{Image from filehandle has a width});

close $fh;

# LZW Compression  2 tests ------------------

$pdf = PDF::Builder->new('-compress' => 'none');

my $lzw_tiff = $pdf->image_tiff('t/resources/1x1-lzw.tif');
if ($lzw_tiff->usesLib() == 1) {
    isa_ok($lzw_tiff, 'PDF::Builder::Resource::XObject::Image::TIFF_GT',
        q{$pdf->image_tiff(), LZW compression});
} else {
    isa_ok($lzw_tiff, 'PDF::Builder::Resource::XObject::Image::TIFF',
        q{$pdf->image_tiff(), LZW compression});
}

$gfx = $pdf->page()->gfx();
$gfx->image($lzw_tiff, 72, 360, 216, 432);

like($pdf->stringify(), qr/q 216 0 0 432 72 360 cm \S+ Do Q/,
     q{Add TIFF to PDF});

# Missing file  1 test ------------------

$pdf = PDF::Builder->new();
eval { $pdf->image_tiff('t/resources/this.file.does.not.exist') };
ok($@, q{Fail fast if the requested file doesn't exist});

##############################################################
# common data for remaining tests
my $width = 1000;
my $height = 100;
my $tiff_f = 'test.tif';
my $pdfout = 'test.pdf';

# NOTE: following 4 tests use 'convert' tool from ImageMagick.
# They may require software installation on your system, and 
# will be skipped if the necessary software is not found.
#
# Some of the following tests will need ghostScript on Windows platforms.
# Note that GS installation MAY not permanently add GS to %Path% -- you
#   may have to do this manually

my ($convert, $gs);
# Linux-like systems usually have a pre-installed "convert" utility, while
# Windows must use ImageMagick. In addition, be careful NOT to run "convert"
# on Windows, as this is a HDD reformatter!
if      (can_run("magick")) {
    $convert = "magick convert";
} elsif ($OSNAME ne 'MSWin32' and can_run("convert")) {
    $convert = "convert";
}
# on Windows, ImageMagick can be 64-bit or 32-bit version, so try both. it's
#   needed for some magick convert operations, and also standalone, and 
#   usually must be installed.
# on Linux-like systems, it's usually just 'gs' and comes with the platform.
if      (can_run("gswin64c")) {
    $gs = "gswin64c";
} elsif (can_run("gswin32c")) {
    $gs = "gswin32c";
} elsif (can_run("gs")) {
    $gs = "gs";
}

# alpha layer handling ------------------
# convert and Graphics::TIFF needed

SKIP: {
    skip "No 'convert' utility available.", 1 unless 
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pngalpha -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=out.png $pdfout");
my $example = `$convert out.png -colorspace gray -depth 1 -resize 1x1 txt:-`;
my $expected = `$convert $tiff_f -depth 1 -resize 1x1 txt:-`;
# ----------

is($example, $expected, 'alpha');
}

# G4 (NOT converted to Flate) ------------------
# convert and Graphics::TIFF are needed

SKIP: {
    skip "No 'convert' utility available, or no Graphics::TIFF.", 1 unless
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -compress Group4 $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=out.png $pdfout");
my $example = `$convert out.png -depth 1 -resize 1x1 txt:-`;
$example =~ /gray\((\d+)\)/;
$example = $1;
my $expected = `$convert $tiff_f -depth 1 -resize 1x1 txt:-`;
$expected =~ /gray\((\d+)\)/;
$expected = $1;
# ----------

is($example, $expected, 'G4 (not converted to flate)');
}

# LZW convert to Flate ------------------
# convert needed for this test

SKIP: {
    skip "No 'convert' utility available.", 1 unless 
        defined $convert and defined $gs;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page;
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=out.png $pdfout");
my $example = `$convert out.png -depth 1 -alpha off -resize 1x1 txt:-`;
$example =~ /gray\((\d+)\)/;
$example = $1;
my $expected = `$convert $tiff_f -depth 1 -alpha off -resize 1x1 txt:-`;
$expected =~ /gray\((\d+)\)/;
$expected = $1;
# ----------

is($example, $expected, 'lzw (converted to flate)');
}

# read TIFF with colormap ------------------
# convert and Graphics::TIFF needed for this test

SKIP: {
    skip "No 'convert' utility available, or no Graphics::TIFF.", 1 unless
        defined $convert and $has_GT;

# .png file is temporary file (output, input, erased)
system("$convert rose: -type palette -depth 2 colormap.png");
system("$convert colormap.png $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page;
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();
pass 'successfully read TIFF with colormap';
}

##############################################################
# cleanup. all tests involving these files skipped?

unlink $pdfout, $tiff_f, 'colormap.png', 'out.png';
