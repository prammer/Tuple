
package Iterator::ArrayBuffer;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Iterator';

requires '_get_more';

has '_buf' => (
    init_arg  => undef,
    is        => 'rw',
    isa       => 'ArrayRef',
    predicate => '_has_buf',
    clearer   => '_clear_buf',
);

sub next {
    my $self = shift;

    return if !$self->has_next;

    # we must have a non-empty array in _buf now
    my $array = $self->_buf;
    my $item  = shift @$array;
    $self->_clear_buf if ( @$array == 0 );
    return $item;
}

sub has_next {
    my $self = shift;

    return 1 if $self->_has_buf;

    # see if we can fill _buf with a non-empty array
    my $more = $self->_get_more or return;
    return if @$more == 0;
    $self->_buf($more);
    return 1;
}

sub peek {
    my $self = shift;

    return if !$self->has_next;

    # we must have a non-empty array in _buf now
    return $self->_buf->[0];
}

1;
__END__

