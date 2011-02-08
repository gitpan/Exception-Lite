use strict;
use warnings;
use Module::Build;

unshift @INC, "inc/";

if (grep { m{^--fakeprereqs$} } @ARGV) {
  push @INC, '/tmp/CPAN_build/Exception-Lite/prereqs';
}

my $builder = Module::Build
  ->new( # command line options to hard-code data needed by
        module_name => 'Exception::Lite'
         , license => 'perl'
         , recursive_test_files => 1
         , requires => {'perl' => '>= 5.8.8'}

         , dist_author => 'Elizabeth Grace Frank-Backman'
         , dist_version => '0.999_004'
         , dist_abstract => 'light weight exception handling class with smart stack tracing, chaining, and localization support'
         , create_makefile_pl => 'traditional'

       );
$builder->create_build_script;  #generate Build
    1;
