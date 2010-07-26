
package EnumMap::Role;
use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

sub __enum_pair {
    my ($self, $class) = @_;
    require Iterator::Code;
    my $h = {%$self};
    return Iterator::Code->new(sub {
        my $k = ( keys(%$h) )[0];
        return if !defined $k;
        return $class->new( $k, delete $h->{$k}, );
    });
}

sub enums {
    my $self = shift;
    require Enum;
    return $self->__enum_pair('Enum');
#    return [ map { Enum->new( $_ => $self->{$_} ) } keys %$self ];
}

sub pairs {
    my $self = shift;
    require Pair;
    return $self->__enum_pair('Pair');
#    return [ map { Pair->new( $_ => $self->{$_} ) } keys %$self ];
}

sub elems  { scalar( keys( %{ $_[0] } ) ) }

sub tuples {
    my $self = shift;
    require Tuple;
    require Iterator::Code;
    my $h = {%$self};
    return Iterator::Code->new(sub {
        my $k = ( keys(%$h) )[0];
        return if !defined $k;
        return Tuple->new( key => $k, value => delete $h->{$k}, );
    });
}

# delegate to pairs
for my $method (qw(map grep each)) {
    __PACKAGE__->meta->add_method(
        $method => sub {
            my $self = shift;
            return $self->pairs->$method(@_);
        }
    );
}

with (
#    'Moose::Autobox::Hash',
    'Any',
    'New',
);


package EnumMap;

use Moose;
use warnings FATAL => 'all';
use MooseX::Identity qw(is_identical);
use namespace::autoclean;

with 'EnumMap::Role';

#sub put    { confess 'cannot modify' }
#sub delete { confess 'cannot modify' }

sub _is_identical_value {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $e1, $e2 ) = @_;

    return 0 if ( $e1->elems != $e2->elems );
    for my $key ( keys %$e1 ) {
        return 0 if !exists $e2->{$key};
        return 0 if !is_identical( $e1->{$key}, $e2->{$key} );
    }
    return 1;
}

#sub WHICH { return $_[0] }

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

