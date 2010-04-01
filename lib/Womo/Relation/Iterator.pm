
package Womo::Relation::Iterator;

use Womo::Class;
require Womo::Relation;

with 'MooseX::Iterator::Role';

has 'relation' => (
    is       => 'ro',
    isa      => 'Womo::Relation',
    required => 1,
);

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

