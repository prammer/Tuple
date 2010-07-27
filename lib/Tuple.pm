
package Tuple::Role;
use Moose::Role;
use warnings FATAL => 'all';
use Set::Object qw(set);
use Scalar::Util qw(reftype);
use namespace::autoclean;

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

# delegate to EnumMap
for my $method (qw(enums pairs map grep each)) {
    __PACKAGE__->meta->add_method(
        $method => sub {
            my $self = shift;
            return $self->EnumMap->$method(@_);
        }
    );
}

with qw(Any New);

sub tuples {
    require Array;
    return Array->new($_[0]);
}

sub keys {
    require Array;
    return Array->new( CORE::keys( %{ $_[0] } ) );
}

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
    return Array->new(
        map {
            ( exists $self->{$_} )
                or confess "not an attribute of this tuple: $_";
            $self->{$_}
        } @a
    );
}

sub exists {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $a ) = @_;
    return exists $self->{$a};
}

sub projection {
    my $self = shift;

    return $self->new(
        map {
            ( exists $self->{$_} )
                or confess "not an attribute of this tuple: $_";
            $_ => $self->{$_}
        } @_
    );
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

# flatten
# Hash ?
# HashRef ?


package Tuple;
use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with (
    'Tuple::Role',
);

sub WHICH {
    my $self = shift;
    return $self->EnumMap;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

