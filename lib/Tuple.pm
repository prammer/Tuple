
package Tuple::Role;
use Moose::Role;
use warnings FATAL => 'all';
use Set::Object qw(set);
use Scalar::Util qw(reftype);
use namespace::autoclean;

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
    'Any',
    'New',
);

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

sub EnumMap {
    my $self = shift;
    require EnumMap;
    return EnumMap->new(%$self);
}

sub Hash {
    my $self = shift;
    require Hash;
    return Hash->new(%$self);
}

sub tuples {
    require Array;
    return Array->new($_[0]);
}

sub keys {
    require Array;
    return Array->new( CORE::keys( %{ $_[0] } ) );
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
    'Any',
    'New',
);

sub elems { return scalar( CORE::keys( %{ $_[0] } ) ) }

sub at {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $a ) = @_;
    ( exists $self->{$a} )
        or confess "not an attribute of this tuple: $a";
    return $self->{$a};
}

sub slice {
    my $self = shift;
    my @a
        = ( @_ == 1 && ( reftype( $_[0] ) || '' ) eq 'ARRAY' )
        ? @{ $_[0] }
        : @_;

    require Array;
    return Array->new( map { $self->at($_) } @a );
}

sub exists {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $a ) = @_;
    return exists $self->{$a};
}

sub projection {
    my $self = shift;

    return $self->new( map { $_ => $self->at($_) } @_ );
}

sub heading {
    my $self = shift;

    return set( $self->attributes );
}

# call this ->extension ? ->merge ?
sub extension {
    my $self = shift;

    return $self if @_ == 0;
    my @hrefs = $self->_components;
    if ( ref( $_[0] ) ) {
        push @hrefs, map { blessed($_) ? $_->_components : $_ } @_;
    }
    elsif ( @_ == 1 ) {
        confess 'bad args';
    }
    else {
        push @hrefs, {@_};
    }

    my $new_heading = $self->heading;
    my $intersect   = set();
    for my $h (@hrefs) {
        my $hset = set( CORE::keys %$h );
        $intersect->insert( $new_heading->intersection($hset) );
        $new_heading->insert($hset);
    }
    if ( $intersect->size > 0 ) {
        confess "not disjoint on: " . join( ', ', $intersect->members );
    }
    return $self->new( map { %$_ } @hrefs );
}

sub flat { %{ $_[0] } }


package Tuple;
use Moose;
use warnings FATAL => 'all';
use MooseX::Identity qw(is_identical);
use namespace::autoclean;

with (
    'Tuple::Role',
);

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

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

