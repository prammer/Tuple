
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
    my ( $self, $next_label ) = @_;

    my $p_sql = $self->_parent->_build_sql($next_label);

    return $self->_new_sql(
        'lines' => [
            "select distinct " . join( ", ", @{ $self->_attributes } ),
            'from (', $p_sql, ')'
        ],
        'bind'       => $p_sql->bind,
        'next_label' => $p_sql->next_label,
    );
}

1;

__END__

