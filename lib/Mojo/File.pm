package Mojo::File;
use Mojo::Base -strict;
use overload
  '@{}'    => sub { shift->to_array },
  bool     => sub {1},
  '""'     => sub { ${$_[0]} },
  fallback => 1;

use Carp 'croak';
use Cwd qw(abs_path getcwd);
use Exporter 'import';
use File::Basename ();
use File::Copy     ();
use File::Find     ();
use File::Path     ();
use File::Spec;
use File::Temp ();
use Mojo::Collection;
use Mojo::Util;
use Scalar::Util 'blessed';

our @EXPORT_OK = ('path', 'tempdir');

sub basename { scalar File::Basename::basename ${$_[0]} }

sub child {
  my $self = shift;
  return $self->new($self, @_);
}

sub dirname { scalar File::Basename::dirname ${$_[0]} }

sub list_tree {
  my ($self, $options) = (shift, shift // {});

  # This may break in the future, but is worth it for performance
  local $File::Find::skip_pattern = qr/^\./ unless $options->{hidden};

  my %files;
  my $want = sub { $files{$File::Find::name}++ };
  my $post = sub { delete $files{$File::Find::dir} };
  File::Find::find {wanted => $want, postprocess => $post, no_chdir => 1},
    $$self
    if -d $$self;

  return Mojo::Collection->new(map { $self->new($_) } sort keys %files);
}

sub make_path {
  my $self = shift;
  File::Path::make_path $$self, @_
    or croak qq{Can't make directory "$$self": $!};
  return $self;
}

sub move_to {
  my ($self, $to) = @_;
  File::Copy::move($$self, $to)
    or croak qq{Can't move file "$$self" to "$to": $!};
  return $self->new($to);
}

sub new {
  my $class = shift;
  my $self = bless \my $dummy, ref $class || $class;

  unless (@_) { $$self = getcwd }

  elsif (@_ > 1) { $$self = File::Spec->catfile(@_) }

  elsif (blessed $_[0] && $_[0]->isa('File::Temp::Dir')) { $$self = $_[0] }

  else { $$self = shift }

  return $self;
}

sub parent { $_[0]->new(scalar File::Basename::dirname ${$_[0]}) }

sub path { __PACKAGE__->new(@_) }

sub slurp { Mojo::Util::slurp(${shift()}) }

sub spurt {
  my $self = shift;
  Mojo::Util::spurt(shift, $$self);
  return $self;
}

sub tap { shift->Mojo::Base::tap(@_) }

sub tempdir { __PACKAGE__->new(File::Temp->newdir(@_)) }

sub to_abs { $_[0]->new(abs_path ${$_[0]}) }

sub to_array { [File::Spec->splitdir(${shift()})] }

sub to_rel { $_[0]->new(File::Spec->abs2rel(${$_[0]}, $_[1])) }

sub to_string {"${$_[0]}"}

1;
