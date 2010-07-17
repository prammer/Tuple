
package Enum::Role;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;
with qw(Any New);

sub BUILDARGS {
    my $class = shift;
    confess 'expecting 2 values but got ' . scalar(@_) if ( @_ != 2 );
    return Moose::Object::BUILDARGS( $class, @_ );
}

sub key {
    confess 'too many arguments' if @_ > 1;
    return ( keys( %{ $_[0] } ) )[0];
}

sub value {
    confess 'too many arguments' if @_ > 1;
    return ( values( %{ $_[0] } ) )[0];
}


package Enum;

use Moose;
use warnings FATAL => 'all';
use MooseX::Identity qw(is_identical);
use namespace::autoclean;

with 'Enum::Role';

sub _is_identical_value {
    my ( $self, $other ) = @_;

    return 0 if !is_identical( $self->key,   $other->key );
    return 0 if !is_identical( $self->value, $other->value );
    return 1;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

