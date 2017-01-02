package Mojo::Home;
use Mojo::Base -base;
use overload bool => sub {1}, '""' => sub { shift->to_string }, fallback => 1;

use Mojo::Util qw(class_to_path deprecated);
use Mojo::File 'path';
use Mojo::Util 'class_to_path';

has parts => sub { [] };

sub detect {
  my ($self, $class) = @_;

  # Environment variable
  return $self->parts(path($ENV{MOJO_HOME})->to_abs->to_array)
    if $ENV{MOJO_HOME};

  # Location of the application class
  if ($class && (my $path = $INC{my $file = class_to_path $class})) {
    $path =~ s/\Q$file\E$//;
    my @home = @{path($path)};

    # Remove "lib" and "blib"
    pop @home while @home && ($home[-1] =~ /^b?lib$/ || !length $home[-1]);

    # Turn into absolute path
    return $self->parts(path(@home)->to_abs->to_array);
  }

  # Current working directory
  return $self->parts(path->to_array);
}

sub lib_dir {
  my $path = path(@{shift->parts}, 'lib');
  return -d $path ? $path->to_string : undef;
}

# DEPRECATED!
sub list_files {
  deprecated
    'Mojo::Home::list_files is DEPRECATED in favor of Mojo::Util::files';
  my ($self, $dir, $options) = (shift, shift // '', shift);
  my $base = path(@{$self->parts}, split('/', $dir));
  $base->list_tree($options)->map(sub { join '/', @{$_->to_rel($base)} })
    ->to_array;
}

sub mojo_lib_dir { path(__FILE__)->dirname->child('..')->to_string }

sub new { @_ > 1 ? shift->SUPER::new->parse(@_) : shift->SUPER::new }

sub parse { shift->parts(path(shift)->to_array) }

# DEPRECATED!
sub rel_dir {
  deprecated
    'Mojo::Home::rel_dir is DEPRECATED in favor of Mojo::Home::rel_file';
  path(@{shift->parts}, split('/', shift))->to_string;
}

sub rel_file { path(@{shift->parts}, split('/', shift))->to_string }

sub to_string { path(@{shift->parts})->to_string }

1;

=encoding utf8

=head1 NAME

Mojo::Home - Home sweet home

=head1 SYNOPSIS

  use Mojo::Home;

  # Find and manage the project root directory
  my $home = Mojo::Home->new;
  $home->detect;
  say $home->lib_dir;
  say $home->rel_file('templates/layouts/default.html.ep');
  say "$home";

=head1 DESCRIPTION

L<Mojo::Home> is a container for home directories.

=head1 ATTRIBUTES

L<Mojo::Home> implements the following attributes.

=head2 parts

  my $parts = $home->parts;
  $home     = $home->parts(['home', 'sri', 'myapp']);

Home directory parts.

=head1 METHODS

L<Mojo::Home> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 detect

  $home = $home->detect;
  $home = $home->detect('My::App');

Detect home directory from the value of the C<MOJO_HOME> environment variable,
location of the application class, or the current working directory.

=head2 lib_dir

  my $path = $home->lib_dir;

Path to C<lib> directory of application.

=head2 mojo_lib_dir

  my $path = $home->mojo_lib_dir;

Path to C<lib> directory in which L<Mojolicious> is installed.

=head2 new

  my $home = Mojo::Home->new;
  my $home = Mojo::Home->new('/home/sri/my_app');

Construct a new L<Mojo::Home> object and L</"parse"> home directory if
necessary.

=head2 parse

  $home = $home->parse('/home/sri/my_app');

Parse home directory.

=head2 rel_file

  my $path = $home->rel_file('foo/bar.html');

Portably generate an absolute path relative to the home directory.

=head2 to_string

  my $str = $home->to_string;

Home directory.

=head1 OPERATORS

L<Mojo::Home> overloads the following operators.

=head2 bool

  my $bool = !!$home;

Always true.

=head2 stringify

  my $str = "$home";

Alias for L</"to_string">.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
