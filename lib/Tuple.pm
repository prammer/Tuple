
package Tuple;
use Moose;
use Set::Object qw(set);
use MooseX::Identity qw(is_identical);
use warnings FATAL => 'all';
use namespace::autoclean;

with 'MooseX::Identity::Role';

override BUILDARGS => sub {
    # TODO: Readonly?
    return +{ _components => super() };
};

has '_components' => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => {
        degree     => 'count',
        attributes => 'keys',
        flatten    => 'elements',
    },
);

sub pairs {
    my $self = shift;
    require Pair;
    my $c = $self->_components;
    return ( map { Pair->new( $_ => $c->{$_} ) } keys %$c );
}

sub _is_identical_value {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $t1, $t2 ) = @_;

    my $h1 = $t1->heading;
    my $h2 = $t2->heading;
    return if ( $h1->not_equal($h2) );
    for my $a ( $h1->members ) {
        return if ( !is_identical( $t1->attr($a), $t2->attr($a) ) );
    }
    return 1;
}

sub attr {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $a ) = @_;
    my $c = $self->_components;
    ( exists $c->{$a} )
        or confess "not an attribute of this tuple: $a";
    return $c->{$a};
}

sub attrs {
    my $self = shift;
    my @a = ( @_ == 1 && ref($_[0]) eq 'ARRAY') ? @{$_[0]} : @_;

    my $c = $self->_components;
    return map {
        ( exists $c->{$_} )
            or confess "not an attribute of this tuple: $_";
        $c->{$_}
    } @a;
}

sub has_attr {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $a ) = @_;
    return exists $self->_components->{$a};
}

sub projection {
    my $self = shift;

    my $c = $self->_components;
    return (blessed $self)->new(
        map {
            ( exists $c->{$_} )
                or confess "not an attribute of this tuple: $_";
            $_ => $c->{$_}
        } @_
    );
}

sub heading {
    my $self = shift;

    return set( $self->attributes );
}

# call this ->extension ?
sub union {
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
    return (blessed $self)->new( map { %$_ } @hrefs );
}

# flatten
# Hash ?
# HashRef ?

__PACKAGE__->meta->make_immutable;
1;
__END__

