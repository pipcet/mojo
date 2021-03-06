use Mojo::Base -strict;

use Test::More;

plan skip_all => 'set TEST_POD to enable this test (developer only!)'
  unless $ENV{TEST_POD};
plan skip_all => 'Test::Pod::Coverage 1.04+ required for this test!'
  unless eval 'use Test::Pod::Coverage 1.04; 1';

# DEPRECATED!
my @deprecated
  = qw(files is_status_class lib_dir parse parts rel_dir slurp spurt);
all_pod_coverage_ok({also_private => \@deprecated});
