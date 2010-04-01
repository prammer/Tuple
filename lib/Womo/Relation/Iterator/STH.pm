
package Womo::Relation::Iterator::STH;

use Womo::Class;

with 'Womo::Relation::Iterator';

has '_sth' => (
    init_arg => 'sth',
    is       => 'ro',
#    isa => ???
    required => 1,
);

sub next {
    my $self = shift;

    my $row = $self->_sth->fetchrow_hashref;
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

