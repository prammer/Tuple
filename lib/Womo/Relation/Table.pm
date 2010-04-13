
package Womo::Relation::Table;
use Womo::Class;
use Womo::Depot::Interface;

has '_depot' => (
    init_arg => 'depot',
    is       => 'ro',
    does     => 'Womo::Depot::Interface',
    required => 1,
    handles  => { '_db_conn' => 'db_conn' },
);

# after "has" to satisfy "requires"
with 'Womo::Relation::Role';

has '_table_name' => (
    init_arg => 'table_name',
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_sql {
    my ( $self, $next_label ) = @_;

    # TODO: if heading includes any key, leave off distinct
    my $table = $self->_table_name;
    my $col   = $self->heading;
    return $self->_new_sql(
        'lines' =>
            [ 'select distinct ' . join( ', ', @$col ) . " from $table" ],
        'bind'       => [],
        'next_label' => $next_label,
    );
}

1;
__END__

