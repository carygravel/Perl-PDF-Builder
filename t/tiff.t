#!/usr/bin/perl
use warnings;
use strict;
use English qw( -no_match_vars );
use IPC::Cmd qw(can_run run);
use File::Spec;
use File::Temp;
use version;
use Test::More tests => 18;

use PDF::Builder;
# 0: allow use of Graphics::TIFF, 1: force non-GT usage
my $noGT = 0;

# Filename 3 tests ------------------
# tests 1 and 3 will mention TIFF_GT if Graphics::TIFF is installed and
# usable, otherwise they will display just TIFF. you can use this information
# if you are not sure about the status of Graphics::TIFF.

my $pdf = PDF::Builder->new('-compress' => 'none'); # common $pdf all tests
my $has_GT = 0; # global flag for all tests that need to know if Graphics::TIFF

# -silent shuts off one-time warning for rest of run
my $tiff = $pdf->image_tiff('t/resources/1x1.tif', -silent => 1, -nouseGT => $noGT);
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

my $lzw_tiff = $pdf->image_tiff('t/resources/1x1-lzw.tif', -nouseGT => $noGT);
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
eval { $pdf->image_tiff('t/resources/this.file.does.not.exist', -nouseGT => $noGT) };
ok($@, q{Fail fast if the requested file doesn't exist});

##############################################################
# common data for remaining tests
my $width = 1000;
my $height = 100;
my $directory = File::Temp->newdir();
my $tiff_f = File::Spec->catfile($directory, 'test.tif');
my $pdfout = File::Spec->catfile($directory, 'test.pdf');
my $pngout = File::Spec->catfile($directory, 'out.png');

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
# check if reasonably recent version
$convert = check_version($convert, '-version', 'ImageMagick ([0-9.]+)', '6.9.7');
# $convert undef if not installed, can't parse format, version too low
# will skip "No 'convert' utility"

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
# check if reasonably recent version
$gs = check_version($gs, '-v', 'Ghostscript ([0-9.]+)', '9.25.0');
# $convert undef if not installed, can't parse format, version too low
# will skip "No 'convert' utility"

# alpha layer handling ------------------
# convert and Graphics::TIFF needed

SKIP: {
    skip "No 'convert' utility available, or no Graphics::TIFF.", 1 unless
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox($width, $height);
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pngalpha -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
my $example = `$convert $pngout -colorspace gray -depth 1 txt:-`;
my $expected = `$convert $tiff_f -depth 1 txt:-`;
# ----------

is($example, $expected, 'alpha + flate');
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
my $img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image($img, 0, 0, $width, $height);
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
my $example = `$convert $pngout -depth 1 txt:-`;
my $expected = `$convert $tiff_f -depth 1 txt:-`;
# ----------

is($example, $expected, 'G4 (not converted to flate)');
}

# LZW (NOT converted to Flate) ------------------
# convert and Graphics::TIFF needed for these two tests

SKIP: {
    skip "No 'convert' utility available, or no Graphics::TIFF.", 4 unless
        defined $convert and defined $gs and $has_GT;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
my $example = `$convert $pngout -depth 1 -alpha off txt:-`;
my $expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'single-strip lzw (not converted to flate) with GT');

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -define tiff:rows-per-strip=50 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip lzw (not converted to flate) with GT');

$width = 20;
$height = 20;
system("$convert -depth 8 -size 2x2 pattern:gray50 -scale 1000% -alpha off -define tiff:predictor=2 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 0);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 8 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 8 -alpha off txt:-`;
# ----------

is($example, $expected, 'lzw+horizontal predictor (not converted to flate) with GT');
$width = 1000;
$height = 100;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pngalpha -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -colorspace gray -depth 1 txt:-`;
$expected = `$convert $tiff_f -depth 1 txt:-`;
# ----------

is($example, $expected, 'alpha + lzw');
}

SKIP: {
    skip "No 'convert' utility available.", 2 unless
        defined $convert and defined $gs;

system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f, -nouseGT => 1);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
my $example = `$convert $pngout -depth 1 -alpha off txt:-`;
my $expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'single-strip lzw (not converted to flate) without GT');

$width = 20;
$height = 20;
system("$convert -depth 8 -size 2x2 pattern:gray50 -scale 1000% -alpha off -define tiff:predictor=2 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
$page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
$img = $pdf->image_tiff($tiff_f, -nouseGT => 1);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
$example = `$convert $pngout -depth 1 -alpha off txt:-`;
$expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'lzw+horizontal predictor (not converted to flate) without GT');
$width = 1000;
$height = 100;
}

SKIP: {
   #skip "currently fails due to bug inherited from PDF::API2", 1;
    skip "multi-strip lzw without GT is not supported", 1;
system("$convert -depth 1 -gravity center -pointsize 78 -size ${width}x${height} caption:\"A caption for the image\" -background white -alpha off -define tiff:rows-per-strip=50 -compress lzw $tiff_f");
# ----------
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page();
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f, -nouseGT => 1);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();

# ----------
system("$gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -g${width}x${height} -dPDFFitPage -dUseCropBox -sOutputFile=$pngout $pdfout");
my $example = `$convert $pngout -depth 1 -alpha off txt:-`;
my $expected = `$convert $tiff_f -depth 1 -alpha off txt:-`;
# ----------

is($example, $expected, 'multi-strip lzw (not converted to flate) without GT');
}

# read TIFF with colormap ------------------
# convert and Graphics::TIFF needed for this test

SKIP: {
    skip "No 'convert' utility available, or no Graphics::TIFF.", 1 unless
        defined $convert and $has_GT;

# .png file is temporary file (output, input, erased)
my $colormap = File::Spec->catfile($directory, 'colormap.png');
system("$convert rose: -type palette -depth 2 $colormap");
system("$convert $colormap $tiff_f");
$pdf = PDF::Builder->new(-file => $pdfout);
my $page = $pdf->page;
$page->mediabox( $width, $height );
$gfx = $page->gfx();
my $img = $pdf->image_tiff($tiff_f, -nouseGT => $noGT);
$gfx->image( $img, 0, 0, $width, $height );
$pdf->save();
$pdf->end();
pass 'successfully read TIFF with colormap';
}

##############################################################
# cleanup. all tests involving these files skipped?

# check non-Perl utility versions
sub check_version {
    my ($cmd, $arg, $regex, $min_ver) = @_;

    # was the check routine already defined (installed)?
    if (defined $cmd) {
	# should match dotted version number
	if (`$cmd $arg` =~ m/$regex/) {
	    if (version->parse($1) >= version->parse($min_ver)) {
		return $cmd;
	    }
	}
    }
    return; # cmd not defined (not installed) so return undef
}
