
package Iterator;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

with(
    'MooseX::Iterator::Role',
    'Any',
);

sub eager {
    my $self = shift;
    require Array;
    my $a = Array->new;
    while ( $self->has_next ) {
        my $item = $self->next;
        push @$a, $item;
    }
    return $a;
}

sub flat {
    my $self = shift;
    return $self->eager->flat;
}

sub map {
    my ( $self, $code ) = @_;
    require Iterator::Map;
    return Iterator::Map->new( iterator => $self, code => $code, );
}

sub grep {
    my ( $self, $code ) = @_;
    return $self->map( sub { $code->($_) ? $_ : () } );
}

# map but with return values ignored.  is this useful?  call it ->for ?
# it implies eagerness I guess.  dunno what else makes sense
sub each {
    my ( $self, $sub ) = @_;
    while ( $self->has_next ) {
        local $_ = $self->next;
        $sub->($_);
    }
    return;
}

sub enums {
    my $self = shift;
    require Enum;
    my $i = 0;
    return $self->map( sub { Enum->new( $i++ => $_ ) } );
}

sub pairs {
    my $self = shift;
    require Pair;
    my $i = 0;
    return $self->map( sub { Pair->new( $i++ => $_ ) } );
}

sub tuples {
    my $self = shift;
    require Tuple;
    my $i = 0;
    return $self->map( sub { Tuple->new( key => $i++, value => $_ ) } );
}

sub elems {
    my $self = shift;
    return $self->eager->elems;
}

1;
__END__

