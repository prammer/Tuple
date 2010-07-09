
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

    return 1 if $self->_has_buf;
    my $item = $self->_code->();
    return 0 if !defined $item;
    $self->_buf($item);
    return 1;
}

sub peek {
    die;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

