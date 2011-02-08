use strict;
use warnings;
#use Test::More qw(no_plan);
use Test::More tests => 135;
use Carp;
use Scalar::Util;

#------------------------------------------------------------------

BEGIN { use_ok('Exception::Lite', qw(:common))
          or BAIL_OUT;
      };
my $TEST_CLASS='Exception::Lite';

#==================================================================
# TEST SUITES
#==================================================================

#------------------------------------------------------------------

sub testNew {
  my ($sClass, $sSuperclass, $sMsg, $hProperties, $xStringify) = @_;

  # verify that we can make the class

  is(declareExceptionClass($sClass, $sSuperclass), $sClass
     , "declareExceptionClass($sClass)");

  # verify that we get the right type of exception

  my $e = $sClass->new($sMsg,  %$hProperties); my $iLine = __LINE__;

  is(ref($e), $sClass, "the new object belongs to class $sClass");
  if ($sSuperclass) {
    is($e->isa($sSuperclass)?1:0,1, "->isa($sSuperclass)");
  }

  # verify that our exception acts like a string in string context

  testStringify("new $sClass object", $e, $sMsg, 0);
  testStringify("new $sClass object", $e, $sMsg, 1);
  testStringify("new $sClass object", $e, $sMsg
                , sub { "***$_[0]***" });
  testStringify("new $sClass object", $e, $sMsg, \&carp, 1);

  # test numeric conversion - eval because there will be a fatal
  # exception if it can't find the proper operators
  eval {
    my $eCopy=$sClass->new($sMsg, %$hProperties);
    is($e+0, Scalar::Util::refaddr($e)
       , "\$e+0 is equal to its refaddr");
    ok($e == $e, "Exception == exception works");
    ok($e != $eCopy, "Exception != exception works");

    local $Exception::Lite::STRINGIFY=0;
    ok($e eq $eCopy, "e eq e(copy) when stringify=0");
    local $Exception::Lite::STRINGIFY=1;
    ok($e ne $eCopy, "e ne e(copy) when stringify>0");


    return 1;
  } or do {
    my $e=$@; diag("Warning! $e");
  };

  # test methods other than getProperties

  is(ref($e), $sClass, "the new object belongs to class $sClass");
  testMethods($e, $sMsg, $hProperties, $iLine, undef);

  # test dying
  eval {
    die $sClass->new("Junk");
  } or do {
    my $e=$@;
    is( (ref($e) && $e->isa($sClass))?1:0, 1
        , "caught a thrown instance of the class");
    testStringify("caught exception:", $e, 'Junk', 0);
  };

  # chained exception
  my $e2 = $sClass->new($e);  $iLine = __LINE__;
  testMethods($e2, $sMsg, {}, $iLine, $e);

  # chained exception with its own message and properties
  my $k = 'nanana';
  my $v = 'yayaya';
  my $sNewMsg = "***$sMsg***";
  my $e3 = $sClass->new($e, $sNewMsg, $k => $v); $iLine = __LINE__;
  testMethods($e3, $sNewMsg, { $k => $v }, $iLine, $e);

  # test propagation using $@=$e; die;
  eval {
    eval {
      eval {
        $iLine = __LINE__; die $sClass->new('Dying...');
      } or do {
        my $e=$@;
        my $aPropagation = $e->getPropagation();
        is(scalar(@$aPropagation), 0, "$sClass: ->getPropagation() == 0");
        $iLine = __LINE__; $@=$e; die;
      };
    } or do {
      my $e=$@;
      my $aPropagation = $e->getPropagation();
      is(scalar(@$aPropagation), 1, "$sClass: ->getPropagation() == 1");
      is($aPropagation->[0]->[0], __FILE__
         , "$sClass: ->getPropagation()->[0]->[0]");
      is($aPropagation->[0]->[1],$iLine
         , "$sClass: ->getPropagation()->[0]->[1]");
      $iLine = __LINE__; $@=$e; die;
    };
  } or do {
    my $e=$@;
    my $aPropagation = $e->getPropagation();
    is(scalar(@$aPropagation), 2, "$sClass: ->getPropagation() == 1");
    is($aPropagation->[1]->[0], __FILE__
       , "$sClass: ->getPropagation()->[1]->[0]");
    is($aPropagation->[1]->[1],$iLine
       , "$sClass: ->getPropagation()->[1]->[1]");
  };

  # test propagation using die $e->rethrow();

  eval {
    eval {
      eval {
        $iLine = __LINE__; die $sClass->new('Dying...');
      } or do {
        my $e=$@;
        my $aPropagation = $e->getPropagation();
        is(scalar(@$aPropagation), 0, "$sClass: ->getPropagation() == 0");
        $iLine = __LINE__; die $e->rethrow(undef, a => "aaa");
      };
    } or do {
      my $e=$@;
      my $aPropagation = $e->getPropagation();
      is(scalar(@$aPropagation), 1, "$sClass: ->getPropagation() == 1");
      is($aPropagation->[0]->[1],$iLine
         , "$sClass: ->getPropagation()->[0]->[1]");
      is($e->getProperty('a'), 'aaa'
         , "$sClass:->getProperty(a) returns value set on rethrow #1");
      $iLine = __LINE__; die $e->rethrow(undef, a => "bbb");
    };
  } or do {
    my $e=$@;
    my $aPropagation = $e->getPropagation();
    is(scalar(@$aPropagation), 2, "$sClass: ->getPropagation() == 1");
    is($aPropagation->[1]->[1],$iLine
       , "$sClass: ->getPropagation()->[1]->[1]");
    is($e->getProperty('a'), 'bbb'
       , "$sClass:->getProperty(a) returns value set on rethrow #2");
  };

}

#------------------------------------------------------------------

sub testClassFormat {
  my ($sClass, $aMakeMsg, $aTestSuite) = @_;
  my $sContext = "$sClass(@$aMakeMsg)";
  my $ePrevious;
  my $iChainedTests=0;

  declareExceptionClass($sClass, undef, $aMakeMsg);
  foreach my $aTest (@$aTestSuite) {
    my ($sMsg, $hProperties, $bChained) = @$aTest;
    my $e;

    if ($bChained) {
      $e = $sClass->new($ePrevious, %$hProperties);
      is($e->getChained, $ePrevious, "$sContext: ->getChained()");
      $iChainedTests++;
    } else {
      $e = $sClass->new(%$hProperties);
      is($e->getChained, undef, "$sContext: ->getChained()");
    }

    is($e->getMessage, $sMsg, "$sContext: ->getMessage()");
    $ePrevious=$e;
  }

  if (!$iChainedTests) {
    diag("Warning: no chained tests for $sContext");
  }
}

#---------------------------------------------------------------

sub testCustomizedClass {
 my ($sClass, $sSuperClass)=@_;
 my $sContext = "testCustomizedClass: $sClass";

 my $aFormat = ['%s likes %s', qw(name food)];
 declareExceptionClass($sClass, $sSuperClass, $aFormat,1);

 ok($sClass->can('_p_getSubclassData')
    , "$sContext: _p_getSubclassData is defined");
 is($sClass->can('getMessage'), $sSuperClass->can('getMessage')
    , "$sContext: getMessage() is inherited and may be overridden");

 my $sCustom = "{ package $sClass;"
   .'sub _new {$_[0]->_p_getSubclassData()->{when}=time()}'
   .'sub getWhen {$_[0]->_p_getSubclassData()->{when}}'
   .'sub getMessage { '
       .'$_[0]->SUPER::getMessage() . " when=". $_[0]->getWhen() }'
   .'}';
 eval $sCustom;
 ok($sClass->can('getMessage') != $sSuperClass->can('getMessage')
    , "$sContext: getMessage() is no longer inherited after custom "
    ."methods are defined");

 my $e=$sClass->new(name=>'Joe', food=>'peanutbutter');
 like($e->getMessage(), qr{\w+ likes \w+ when=\d+$});
}

#---------------------------------------------------------------

sub testObjectFormat {
  my ($sClass, $aMakeMsg, $aTestSuite) = @_;
  my $sContext = "$sClass(@$aMakeMsg[1..$#$aMakeMsg])";

  declareExceptionClass($sClass, undef, $aMakeMsg);
  foreach my $aTest (@$aTestSuite) {
    my ($sMsg, $sFormat, $hProperties) = @$aTest;
    my $e = $sClass->new($sFormat, %$hProperties);
    is($e->getMessage, $sMsg, "$sContext: ->getMessage()");
  }
}

#---------------------------------------------------------------

sub testStringify {
  my ($sContext, $e, $sMsg, $xStringify, $bTrapWarning) = @_;
  local $Exception::Lite::STRINGIFY=$xStringify;

  my $sStringify;

  if ($bTrapWarning) {
    eval {
      my $sWarning;

      local $SIG{__WARN__}= sub { $sWarning=$_[0]; };

      do {return "$e"};
      like($sWarning, qr/\Q$sMsg\E/
         , $sContext . ': "$e" - checking warning');

      do {return "".$e};
      like($sWarning, qr/\Q$sMsg\E/
         , $sContext . ': "".$e - checking warning');

      do {return "x:".$e};
      like($sWarning, qr/\Q$sMsg\E/
         , $sContext . ': "x:".$e - checking warning');

      do {return $e eq 0};
      like($sWarning, qr/\Q$sMsg\E/
         , $sContext . ': $e eq ... - checking warning');
    };
  } else {
    $sStringify= !$xStringify
      ? $sMsg
      : ref($xStringify) eq 'CODE'
        ? $xStringify->($sMsg)
        : Exception::Lite::_dumpMessage($e);

    is("$e", $sStringify, $sContext . ': "$e"' );
    is("".$e, $sStringify, $sContext . ': "".$e');
    is("x:".$e, "x:".$sStringify, $sContext . ': "x:".$e');
    is($e, $sStringify, $sContext . ': $e eq ...');
  }
}

#------------------------------------------------------------------

sub testWarningsAndExceptions {
  my $sContext = 'testWarningsAndExceptions';
  my $sTest;
  my $sExceptionClass='testWarningsAndExceptions::A';

  declareExceptionClass($sExceptionClass, [ "%s %s %s", qw(a) ]);

  {
    my $sWarn;
    local $SIG{__WARN__} = sub { $sWarn=$_[0] if !defined($sWarn); };

    # odd number of parameters
    $sTest="$sContext: Verifying odd number of parameters message";
    $sWarn=undef;
    $sExceptionClass->new('a');
    like($sWarn, qr{added an unnecessary message}, $sTest);

    # format string with too many placeholders
    # This feature relies on our knowing in advance the warnings
    # spewed by sprintf in different Perl releases. It may fail
    # on newer releases if the list of sought for messages is
    # not updated for newer releases (updates should be placed in
    # _sprintf in Exception/Lite.pm)

    $sTest="$sContext: Verifying warning for class "
         ."definition with missing args/too many placeholders "
         ."in format string";
    $sWarn=undef;
    $sExceptionClass->new(a => 'x');
    like($sWarn, qr{too many placeholders}, $sTest);

    $sTest = "$sContext: Verifying die on redefinition";
    eval {
      declareExceptionClass($sExceptionClass);
      fail("$sTest - didn't die");
      return 1;
    } or do {
      my $e=$@;
      like("$e", qr{is already defined}, $sTest);
    };
  }
}

#==================================================================
# SUBTESTS
#==================================================================

#---------------------------------------------------------------

sub testMethods {
  my ($e, $sMsg, $hProperties, $iLine, $eChained) = @_;

  # test location of throw

  is($e->getPackage(), __PACKAGE__, "->getPackage()");
  is($e->getFile(), __FILE__, "->getFile()");
  is($e->getLine(), $iLine, "->getLine()");
  is($e->getSubroutine(), 'main::testNew', "->getSubroutine()");
  is($e->getChained(), $eChained, "->getChained()");

  # test message

  is($e->getMessage(), $sMsg, "->getMessage()");

  # test properties

  while (my ($k,$v) = each (%$hProperties)) {
    is($e->getProperty($k), $v, "->getProperty($k)");
  }
}

#==================================================================
# TEST PLAN
#==================================================================

testNew('X', undef, 'Hello World'
        , { name => 'danny', location => 'israel' });
testNew('A', 'X', 'Morning has broken');

testClassFormat('Z', [ '%s, %s!', qw(greeting name)]
   , [[  'Hello, World!', {greeting=>'Hello',name=>'World'}]
      ,[ 'Boker tov, Ayala!', {greeting=>'Boker tov', name=>'Ayala'} ]
      ,[ 'Boker tov, <undef>!', {greeting=>'Boker tov'} ]
      ,[ '<undef>, Ayala!', {name => 'Ayala'}, 1 ]
     ]);
testCustomizedClass('Preferences::A::B::C','Z');
testWarningsAndExceptions();

