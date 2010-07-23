
package Iterator::BulkWrap;

use Moose;
use warnings FATAL => 'all';
use Data::Stream::Bulk;
use namespace::autoclean;

with 'Iterator';

has 'bulk' => (
    is       => 'ro',
    does     => 'Data::Stream::Bulk',
    required => 1,
    handles  => [qw(
        is_done
    )],
);

has '_buf' => (
    init_arg  => undef,
    is        => 'rw',
    isa       => 'ArrayRef',
    predicate => '_has_buf',
    clearer   => '_clear_buf',
);

override BUILDARGS => sub {
    return +{ bulk => $_[1] } if ( @_ == 2 );
    return super();
};

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
    my $bulk = $self->bulk;
    my $array;
    while (1) {
        return if $bulk->is_done;
        $array = $bulk->next or next;
        last if @$array;
    }
    $self->_buf($array);
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

