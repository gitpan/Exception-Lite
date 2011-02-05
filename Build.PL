use strict;
use warnings;
use Module::Build;

unshift @INC, "inc/";

my @aMoreInc=map { /^--inc=(.*)$/ ? $1 :() } @ARGV;
push @INC, @aMoreInc if @aMoreInc;

my $builder = Module::Build
  ->new( # command line options to hard-code data needed by
        module_name => 'Exception::Lite'
         , license => 'perl'
         , recursive_test_files => 1
         , requires => {'perl' => '>= 5.8.8'}

         , dist_author => 'Elizabeth Grace Frank-Backman'
         , dist_version => '0.999_001'
         
         , create_makefile_pl => 'traditional'

       );
$builder->create_build_script;  #generate Build
    1;
