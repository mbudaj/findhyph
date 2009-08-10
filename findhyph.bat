@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl
#line 15

use warnings;
use Getopt::Std;
$opt_l = 'kKsSvVzZoOuUiIA';             # defaults for Slovak and Czech
$opt_c = $opt_f = $opt_h = $opt_v = 0;
getopts('cfphvl:');

$version_msg = "findhyph version 2.0\n";
$help_msg = "\nUsage: findhyph [options] <yourtexfile.log>\n" .
            "\n" .
            "Options: -c           display hyphenated words in context\n" .
            "         -f           display font selectors\n" .
            "         -h           display this help message\n" .
            "         -v           display version\n" .
            "         -p           generate file with prepositions left at the end of line\n" .
            "         -l=STRING    use prepositions/conjunctions listed in STRING\n";

print ($version_msg) if $opt_v;
die ($help_msg) if $opt_h || !$ARGV[0];
$filename = $ARGV[0];
if ($filename =~ /\.(log|tex|dvi|ps|pdf)$/) {
  $filename = $`;
}
open(IN, "$filename.log") or die ("Can't read $filename.log: $!\n");
open(O1, ">$filename.hyph") or die ("Can't write $filename.hyph: $!\n");
if ($opt_p) {
  open(O2, ">$filename.prep") or die ("Can't write $filename.prep: $!\n");
}

$search = 0;
$pageno_allowed = 0;
$write_hyph_page = 0;
$write_prep_page = 0;
$act_text = "";

while(<IN>) {
  chomp;
  if (/^\@firstpass$/) {
    $pageno_allowed = 0;
    $endgraf = 0;
    $demerits = 1e10;
    $search = 1;
    $search_hyphens = 0;
    $act_break = 0;
    $act_text = "";
    @USED = ();
    %BREAKS = ();
    next;
  }
  if (/^\@secondpass$/) {
    $search_hyphens = 1;
    $act_break = 0;
    $act_text = "";
    @USED = ();
    %BREAKS = ();
    next;
  }
  if (/^\@emergencypass$/) {
    $act_break = 0;
    $act_text = "";
    @USED = ();
    %BREAKS = ();
    next;
  }
  if ($search && /^@@(\d+).+ t=(\d+) \-\> @@(\d+)/) {
    $act_break = $1;
    $BREAKS{$act_break}{'prev'} = $3;
    if ($endgraf && $2 < $demerits) {
      $max_break = $1;
      $demerits = $2;
    }
    $act_text .= "\@$act_break\@";
    next;
  }
  if ($search && /^@\\par via @@/) {
    $endgraf = 1;
    next;
  }
  if ($search && /^@\\discretionary via @@/) {
    $search_hyphens = 1;   # @firstpass may contain words hyphenated by user
    next;                  # using \discretionary
  }
  if ($search && /^@/) {
    next;
  }
  if ($search && $endgraf && $_ eq "") {
    $pageno_allowed = 1;
    do_hyph();
    $search = 0;
    next;
  }
  if ($search) {
    $act_text .= $_;
  } else {
    if ($pageno_allowed  && /\[(\-?\d+)(\.\-?\d+){0,9} ?(\]|\{|\<|$)/) {       # page number
      $pageno = $1;
      $pageno_allowed = 0;
      if ($write_hyph_page) {
        print O1 "[$pageno]\n\n";
        $write_hyph_page = 0;
      }
      if ($write_prep_page) {
        print O2 "[$pageno]\n\n";
        $write_prep_page = 0;
      }
    }
  }
}

close(O1);
close(O2) if $opt_p;

sub do_hyph {
  $br = $max_break;
  while (1) {
    $br = $BREAKS{$br}{'prev'};
    last if ($br == 0);
    $USED[$br] = 1;
  }

  for $i (1..$max_break-1) {
    if (not defined $USED[$i]) {
      $act_text =~ s/\@$i\@//;
    };
  }

  if ($opt_f) {
    $act_text =~ s/(\\\S+)\s+/$1\_/g;
  } else {
    $act_text =~ s/\\\S+\s+//g;  # usually font selector, but also backslash in the text
  }

  for $i (1..$max_break-1) {
    if (defined $USED[$i]) {
      if ($search_hyphens) {              # hyphenated words
        if ($act_text =~ /(\S+\@$i\@\S+)/) {        # only hyphenated words match
          $out_text = $1;
          if ($opt_c) {
            $context_before = $context_after = "";
            if ($act_text =~ /(\S+)\s+\S+\@$i\@/) {$context_before = $1;}
            if ($act_text =~ /\@$i\@\S+\s+(\S+)/) {$context_after = $1;}
            $out_text = "$context_before $out_text $context_after";
          }
          $out_text =~ s/-//g;
          $out_text =~ s/\@$i\@/-/g;
          $out_text =~ s/\@\d+\@//g;                 # very narrow columns
          print O1 "$out_text\n";
          $write_hyph_page = 1;
        }
      }
      if ($opt_p) {                        # prepositions
        if ($act_text =~ / (\S) \@$i\@/) {
          $out_text = $1;
          if ($out_text =~ /^[$opt_l]$/) {
            if ($opt_c) {
              $context_before = $context_after = "";
              if($act_text =~ /(\S+) \S \@$i\@/) {$context_before = $1;}
              if($act_text =~ /\@$i\@ ?(\S+)/) {$context_after = $1;}
              $out_text = "$context_before $out_text $context_after";
              $out_text =~ s/-//g;
              $out_text =~ s/\@\d+\@//g;                 # very narrow columns
            }
            print O2 "$out_text\n";
            $write_prep_page = 1;
          }
        }
      }
    }
  }
}

__END__

=head1 NAME

B<findhyph> -- find words hyphenated by TeX in a document

=head1 INSTALLATION

Copy B<findhyph> or B<findhyph.bat> (depending on OS used) to a directory 
included in system PATH. Perl interpreter is required to be in 
C</usr/bin/> for Unix-like systems or in PATH when using B<findhyph.bat>.

=head1 SYNOPSIS

=over 4

=item 1)

set C<\tracingparagraphs=1> in a TeX document F<foo.tex> and run:

=item 2)

B<tex> F<foo.tex>

=item 3)

B<findhyph [options]> F<foo.log>

=back

=head1 OPTIONS

=over 4

=item B<-c>

display hyphenated words in context

=item B<-f>

display font selectors and other strings starting with a backslash character

=item B<-v>

display program version

=item B<-p>

generate file containing information about one-letter prepositions and 
conjunctions left at the end of line

=item B<-l=STRING>

use prepositions/conjunctions listed in STRING instead of default list of 
prepositions and conjunctions C<kKsSvVzZoOuUiIA> used for Slovak and Czech
language

=back

=head1 OUTPUT FILES

=over 4

=item F<foo.hyph> 

List of hyphenated words. All punctuation characters, parentheses and
other character immediately preceding or following displayed words are included
in this list. TeX constructs which are too difficult to display (C<\hbox{}>,
C<\mark{}> etc.) are shown as C<[]>. Math mode is indicated by C<$> sign.

Page numbers in square brackets refer to LOG file and may occasionally differ
from the typeset document. The reason is that TeX may need to break more 
paragraphs than it would eventually fit on the page in order to find a page
break.

Words hyphenated in footnotes are listed before the words hyphenated in the 
paragraph in which the footnote is referenced.

=item F<foo.prep> 

List of prepositions if option B<-p> is used.

=back

=head1 HISTORY

=head4 1.0 (2001-04-08)

=over 4

=item * 

public release

=back

=head4 2.0 (2009-08-10)

=over 4

=item *

fixes in line breaks detection algorithm; support for third pass of line
breaking algorithm in TeX (positive \emergencystretch); support for 
discretionary breaks in the first pass

=item *

page number detection improved (recognized negative page numbers, compound page
numbers when C<\count1> to C<\count9> registers are non-zero
and C<[nn{mapfile}]>, C<[nnE<lt>pictureE<gt>]> and C<[nnE<lt>newlineE<gt>>
formats used by pdfTeX; false page number detection should be much more rare)

=item *

configurable list of prepositions and conjunctions

=item *

hyphenated words can be displayed in context

=item *

suggestions and testing by Pavel Striz

=back

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
any later version.

=head1 AUTHOR

Copyright (c) Martin Budaj E<lt>m.b@speleo.skE<gt> 2000, 2001, 2009

=cut

__END__
:endofperl
