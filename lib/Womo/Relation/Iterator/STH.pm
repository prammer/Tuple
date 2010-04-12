
package Womo::Relation::Iterator::STH;

use Womo::Class;

with 'Womo::Relation::Iterator';

has '_sth' => (
    init_arg => 'sth',
    is       => 'ro',
#    isa => ???
    required => 1,
    clearer => '_clear_sth',
);

sub next {
    my $self = shift;

    my $sth = $self->_sth or return;
    if ( $sth->{Active} and my $row = $sth->fetchrow_hashref() ) {
        return $row;
    }
    $sth->finish;
    $self->_clear_sth;
    return;
}

sub has_next {
    die;
}

sub peek {
    die;
}

1;
__END__

