
package Pair;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

extends 'Hash';

override BUILDARGS => sub {
    my $class = shift;
    confess 'expecting 2 values but got ' . scalar(@_) if ( @_ != 2 );
    return super();
};

sub key   { ( keys( %{$_[0]} ) )[0] }
sub value { ( values( %{$_[0]} ) )[0] }

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

