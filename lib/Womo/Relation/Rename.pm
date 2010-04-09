
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
    my ( $self, $next_label ) = @_;

    my $map  = $self->_map;
    my $comp = $self->_parent->_components;
    delete $comp->{$_} for ( values %$map );
    my $clause = join( ', ',
        ( sort keys %$comp ),
        ( map { "$map->{$_} $_" } sort keys %$map ) );
    my $p_sql = $self->_parent->_build_sql($next_label);
    return $self->_new_sql(
        'text'       => "select $clause from ( " . $p_sql->text . ')',
        'bind'       => $p_sql->bind,
        'next_label' => $p_sql->next_label,
    );
}

1;
__END__

