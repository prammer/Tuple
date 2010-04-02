
package Womo::Relation::Rename;
use Womo::Class;

with 'Womo::Relation::Derived';

has '_map' => (
    init_arg => 'map',
    is       => 'ro',
    isa      => 'HashRef[Str]',
    required => 1,
);

sub _build_sql {
    my $self = shift;

    my $map = $self->_map;
    my $clause = join( ', ', map {"$map->{$_} $_"} sort keys %$map );
    return "select $clause from ( " . $self->_parent->_build_sql . ')';
}

1;

__END__

