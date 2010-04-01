
package Womo::Relation::Projection;
use Womo::Class;

with 'Womo::Relation::Derived';

has '_attributes' => (
    init_arg => 'attributes',
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

sub _build_sql {
    my $self = shift;

    return
          "select distinct "
        . join( ", ", @{ $self->_attributes } )
        . " from ("
        . $self->_parent->_build_sql . ")",
        ;
}

1;

__END__

