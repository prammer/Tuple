
package Womo::Relation::Iterator::CodeRef;

use Womo::Class;

with 'Womo::Relation::Iterator';

has '_code' => (
    init_arg => 'code',
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub next {
    my $self = shift;

    my $row = $self->_code->();
    return $row;
}

sub has_next {
    die;
}

sub peek {
    die;
}

1;
__END__

