
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
    my @a;
    while ( $self->has_next ) {
        my $item = $self->next;
        push @a, $item;
    }
    return Array->new(@a);
}

sub flatten {
    my $self = shift;
    return $self->eager->flatten;
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

# which of these do we want? and what do they return?
# sub Seq
# sub Array

1;
__END__

