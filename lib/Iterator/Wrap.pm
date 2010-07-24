
package Iterator::Wrap;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Iterator';

has 'iterator' => (
    is       => 'ro',
    does     => 'Iterator',
    required => 1,
);

has 'code' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

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
    my $it = $self->iterator;
    my @array;
    while (1) {
        return if !$it->has_next;
        local $_ = $it->next;
        @array = $self->code->($_);
        last if @array;
    }
    $self->_buf( \@array );
    return 1;
}

sub peek {
    my $self = shift;

    return if !$self->has_next;

    # we must have a non-empty array in _buf now
    return $self->_buf->[0];
}

__PACKAGE__->meta->make_immutable;
1;
__END__

