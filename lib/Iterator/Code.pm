
package Iterator::Code;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Iterator';

has '_code' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has '_buf' => (
    is        => 'rw',
    predicate => '_has_buf',
    clearer   => '_clear_buf',
);

override BUILDARGS => sub {
    return +{ _code => $_[1] };
};

sub next {
    my $self = shift;

    if ($self->_has_buf) {
        my $item = $self->_buf;
        $self->_clear_buf;
        return $item;
    }
    my $item = $self->_code->();
    return $item;
}

sub has_next {
    my $self = shift;

    return ( defined $self->peek ) ? 1 : 0;
}

sub peek {
    my $self = shift;

    return $self->_buf if $self->_has_buf;
    my $item = $self->_code->();
    return if !defined $item;
    $self->_buf($item);
    return $item;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

