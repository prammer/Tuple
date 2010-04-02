
package Womo::Relation::Union;
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
    my $self = shift;

    return
          $self->_parent->_build_sql
        . ' union '
        . $self->_other->_build_sql;
}

1;

__END__

