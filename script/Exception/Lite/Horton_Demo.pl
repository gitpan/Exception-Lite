use strict;
use warnings;
use Test::More;
use Exception::Lite qw(declareExceptionClass);

#==================================================================
# EXCEPTION DEMO
#==================================================================

# -----------------------------------------
# Setup
# -----------------------------------------

use threads;


declareExceptionClass('Foo');
sub notAWhatButAWho {
  my @aDummy=(3);

  weKnowBetterThanYou
    (\@aDummy
     , 'rot, rot, rot'
     , 'Wikerson brothers'
     , 'triculous tripe'
     , 'There will be no more talking to hoos who are not!'
     , 'black bottom birdie'
     , 'from the three billionth flower'
     , 'Mrs Tucanella returns with Wikerson uncles and cousins'
     , 'sound off! sound off! come make yourself known!'
     , 'Apartment 12J', 'Jo Jo the young lad'
     ,'the whole world was saved by the tiny Yopp! of the '
     . 'smallest of all'
    );
  push @aDummy, 2;
}
sub weKnowBetterThanYou {
  my $aDummies = shift;
  my $iCountDummies=scalar @$aDummies;
  my $sWords = $_[0];

  eval {
    hoo('Dr Hoovey','hoo-hoo scope','Mrs Tucanella','Uncle Nate');
    return 1;
  } or do {
    my $e=$@;
    die Foo->new($e,'Mayhem! and then ...');
  }
}
sub hoo { eval { horton('15th of May', 'Jungle of Nool'
                        , 'a small speck of dust on a small clover'
                        , 'a person\'s a person no matter how small'
                       );
                 return 1;
               } or do { die; } }
sub horton { die Foo->new("Horton hears a hoo!"); }

# -----------------------------------------
# Run demo
# -----------------------------------------

sub runDemo {
  diag("\n");  # put new line at end of test counter line

  my $t;

  $t=threads->new(sub {
    diag("\n---------------------------------------------------\n"
         . "Sample exception STRINGIFY=4 running on thread "
         . threads->tid .
         "\n---------------------------------------------------\n"
        );
    $Exception::Lite::STRINGIFY=4;
    eval { notAWhatButAWho() } or do {my $e=$@; diag("$e"); };
  });
  $t->join();

  $t = threads->new(sub {
    diag("\n---------------------------------------------------\n"
         . "Sample exception STRINGIFY=3 running on thread "
         . threads->tid
         . "\nFILTER=OFF" .
         "\n---------------------------------------------------\n"
        );
    my $iSave=$Exception::Lite::FILTER_TRACE;
    $Exception::Lite::FILTER_TRACE=0;
    $Exception::Lite::STRINGIFY=3;
    eval { notAWhatButAWho() } or do {my $e=$@; diag("$e"); };
    $Exception::Lite::FILTER_TRACE=$iSave;
  });
  $t->join();

  $t = threads->new(sub {
    diag("\n---------------------------------------------------\n"
         . "Sample exception STRINGIFY=3 running on thread "
         . threads->tid
         . "\nFILTER=ON" .
         "\n---------------------------------------------------\n"
        );

    $Exception::Lite::STRINGIFY=3;
    eval { notAWhatButAWho() } or do {my $e=$@; diag("$e"); };
  });
  $t->join();

  $t = threads->new(sub {
    diag("\n---------------------------------------------------\n"
         . "Sample exception STRINGIFY=2 running on thread "
         . threads->tid .
         "\n---------------------------------------------------\n"
        );
    $Exception::Lite::STRINGIFY=2;
    eval { notAWhatButAWho() } or do {my $e=$@; diag("$e"); };
  });
  $t->join();

  $t = threads->new(sub {
    diag("\n---------------------------------------------------\n"
         . "Sample exception STRINGIFY=1 running on thread "
         . threads->tid .
         "\n---------------------------------------------------\n"
        );
    $Exception::Lite::STRINGIFY=1;
    eval { notAWhatButAWho() } or do {my $e=$@; diag("$e"); };
  });
  $t->join();

  $t = threads->new(sub {
    diag("\n---------------------------------------------------\n"
         . "Sample exception STRINGIFY=0 running on thread "
         . threads->tid .
         "\n---------------------------------------------------\n"
        );
    $Exception::Lite::STRINGIFY=0;
    eval { notAWhatButAWho() } or do {my $e=$@; diag("$e"); };
  });
  $t->join();

  # mark end of demo
  diag("\n----------------------------\n"
      ."End of demo. Goodbye!"
      ."\n----------------------------\n"
      );
}

#==================================================================
# MAIN PROGRAM
#==================================================================

runDemo();
1;
