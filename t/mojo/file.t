use Mojo::Base -strict;

use Test::More;
use Cwd qw(abs_path getcwd);
use File::Basename qw(basename dirname);
use File::Spec::Functions qw(abs2rel catfile splitdir);
use Mojo::File qw(path tempdir);

# Constructor
is(Mojo::File->new, getcwd(), 'same path');
is path(), getcwd(), 'same path';
is path()->to_string, getcwd(), 'same path';
is path('/foo/bar'), '/foo/bar', 'same path';
is path('foo', 'bar', 'baz'), catfile('foo', 'bar', 'baz'), 'same path';

# Children
is path('foo', 'bar')->child('baz', 'yada'),
  catfile(catfile('foo', 'bar'), 'baz', 'yada'), 'same path';

# Array
is_deeply path('foo', 'bar')->to_array, [splitdir catfile('foo', 'bar')],
  'same structure';
is_deeply [@{path('foo', 'bar')}], [splitdir catfile('foo', 'bar')],
  'same structure';

# Absolute
is path('file.t')->to_abs, abs_path('file.t'), 'same path';

# Relative
is path('test.txt')->to_abs->to_rel(getcwd),
  abs2rel(abs_path('test.txt'), getcwd), 'same path';

# Basename
is path('file.t')->to_abs->basename, basename(abs_path 'file.t'), 'same path';

# Dirname
is path('file.t')->to_abs->dirname, dirname(abs_path 'file.t'), 'same path';

# Parent
is path('file.t')->to_abs->parent->to_string, path('file.t')->to_abs->dirname,
  'same path';

# Temporary directory
my $dir  = tempdir;
my $path = "$dir";
ok -d $path, 'directory exists';
undef $dir;
ok !-d $path, 'directory does not exist anymore';

# Make path
$dir = tempdir;
my $subdir = $dir->child('foo', 'bar');
ok !-d $subdir, 'directory does not exist anymore';
$subdir->make_path;
ok -d $subdir, 'directory exists';

# List tree
is_deeply path('does_not_exist')->list_tree->to_array, [], 'no files';
is_deeply path(__FILE__)->list_tree->to_array,         [], 'no files';
my $lib = path(__FILE__)->parent->child('lib', 'Mojo');
my @files = map { path($lib)->child(split '/') } (
  'BaseTest/Base1.pm',  'BaseTest/Base2.pm',
  'BaseTest/Base3.pm',  'DeprecationTest.pm',
  'LoaderException.pm', 'LoaderException2.pm',
  'LoaderTest/A.pm',    'LoaderTest/B.pm',
  'LoaderTest/C.pm'
);
is_deeply path($lib)->list_tree->map('to_string')->to_array, \@files,
  'right files';
my @hidden = map { path($lib)->child(split '/') } '.hidden.txt',
  '.test/hidden.txt';
is_deeply path($lib)->list_tree({hidden => 1})->map('to_string')->to_array,
  [@hidden, @files], 'right files';

# I/O
$dir = tempdir;
my $file = $dir->child('test.txt')->spurt('just works!');
is $file->slurp, 'just works!', 'right content';

done_testing();
