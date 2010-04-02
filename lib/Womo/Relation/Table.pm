
package Womo::Relation::Table;
use Womo::Class;
use Womo::Depot::Interface;

with 'Womo::Relation::Role';

has '_depot' => (
    init_arg => 'depot',
    is       => 'ro',
    does     => 'Womo::Depot::Interface',
    required => 1,
);

has '_table_name' => (
    init_arg => 'table_name',
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_sql {
    my $self = shift;

    my $table = $self->_table_name;
    my $col   = $self->heading;
    return 'select distinct ' . join( ', ', @$col ) . " from $table";
}

sub _db_conn {
    my $self = shift;
    return $self->_depot->db_conn;
}

1;
__END__

