
package Iterator::Array;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

has '_array' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    traits   => ['Array'],
    handles  => {
        'next'     => 'shift',
        'has_next' => 'elements',
    },
);

with 'Iterator';

override BUILDARGS => sub {
    my $self = shift;
    return +{ _array => [@_] };
};

sub peek {
    my $self = shift;

    return $self->_array->[0];
}

__PACKAGE__->meta->make_immutable;
1;
__END__

