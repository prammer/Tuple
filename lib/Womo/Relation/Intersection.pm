
package Womo::Relation::Intersection;
use Womo::Class;

with 'Womo::Relation::Derived';

has '_other' => (
    init_arg => 'other',
    is       => 'ro',
#TODO: other kinds of relations, like non-SQL
    does     => 'Womo::Relation::Role',
    required => 1,
);

sub _build_sql {
    my ( $self, $next_label ) = @_;

    my $p_sql = $self->_parent->_build_sql($next_label);
    my $o_sql = $self->_other->_build_sql( $p_sql->next_label );
    return $self->_new_sql(
        'text' => join( ' ', $p_sql->text, 'intersect', $o_sql->text ),
        'bind'       => $p_sql->combine_bind($o_sql),
        'next_label' => $o_sql->next_label,
    );
}

1;

__END__

