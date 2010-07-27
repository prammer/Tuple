
package Enum::Role;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;
override 'BUILDARGS' => sub {
    my $class = shift;
    confess 'expecting 2 values but got ' . scalar(@_) if ( @_ != 2 );
    return super();
};

sub key {
    confess 'too many arguments' if @_ > 1;
    return ( keys( %{ $_[0] } ) )[0];
}

sub value {
    confess 'too many arguments' if @_ > 1;
    return ( values( %{ $_[0] } ) )[0];
}

sub Tuple {
    my $self = shift;
    require Tuple;
    return Tuple->new( key => $self->key, value => $self->value );
}

sub tuples {
    my $self = shift;
    require Array;
    return Array->new( $self->Tuple );
}

sub elems  {1}

sub Array {
    my $self = shift;
    require Array;
    return Array->new($self);
}

# delegate to Array
for my $method (qw(map grep each)) {
    __PACKAGE__->meta->add_method(
        $method => sub {
            my $self = shift;
            return $self->Array->$method(@_);
        }
    );
}

with (
    'Any',
    'New',
#    'Moose::Autobox::Hash',
);


package Enum;

use Moose;
use warnings FATAL => 'all';
use MooseX::Identity qw(is_identical);
use namespace::autoclean;

with 'Enum::Role';

#sub put    { confess 'cannot modify' }
#sub delete { confess 'cannot modify' }

sub _is_identical_value {
    my ( $self, $other ) = @_;

    return 0 if !is_identical( $self->key,   $other->key );
    return 0 if !is_identical( $self->value, $other->value );
    return 1;
}

#sub WHICH { return $_[0] }

sub Pair {
    my $self = shift;
    require Pair;
    return Pair->new( $self->key, $self->value );
}

sub pairs {
    my $self = shift;
    require Array;
    return Array->new( $self->Pair );
}

sub enums {
    my $self = shift;
    return $self->Array;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

