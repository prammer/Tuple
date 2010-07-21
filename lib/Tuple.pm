
package Tuple::Role;
use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;
with qw(Any New);


package Tuple;
use Moose;
use Set::Object qw(set);
use warnings FATAL => 'all';
use namespace::autoclean;

with (
    'Tuple::Role',
);

sub attributes { return keys( %{ $_[0] } ) }
sub degree     { return scalar( keys( %{ $_[0] } ) ) }

sub enums {
    my $self = shift;
    require Enum;
    return [ map { Enum->new( $_ => $self->{$_} ) } keys %$self ];
}

sub pairs {
    my $self = shift;
    require Pair;
    return [ map { Pair->new( $_ => $self->{$_} ) } keys %$self ];
}

sub EnumMap {
    my $self = shift;
    require EnumMap;
    return EnumMap->new(%$self);
}

sub WHICH {
    my $self = shift;
    return $self->EnumMap;
}

sub attr {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $a ) = @_;
    ( exists $self->{$a} )
        or confess "not an attribute of this tuple: $a";
    return $self->{$a};
}

sub attrs {
    my $self = shift;
    my @a = ( @_ == 1 && ref($_[0]) eq 'ARRAY') ? @{$_[0]} : @_;

    return map {
        ( exists $self->{$_} )
            or confess "not an attribute of this tuple: $_";
        $self->{$_}
    } @a;
}

sub has_attr {
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
        my $hset = set( keys %$h );
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

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

