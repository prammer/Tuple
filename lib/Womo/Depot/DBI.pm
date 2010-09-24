
package Womo::Depot::DBI;

use Womo::Class;
use Set::Relation::V2;
use Womo::Relation;
use Womo::SQL;
use Womo::Relation::Iterator::STH;
use Womo::Relation::Iterator::CodeRef;
use Set::Object qw(set);
use SQL::Abstract;
use Womo::ASTNode;
use Seq;

# TODO: the structure of this is very SQL specific
# "table_name, column_name" vs "relvar_name, attribute_name" etc
has 'catalog' => (
    is       => 'ro',
    isa      => 'HashRef', # TODO
    required => 1,
    lazy     => 1,
    builder  => '_build_catalog',
);

has 'database' => (
    is       => 'ro',
    isa      => 'HashRef', # TODO
    required => 1,
    lazy     => 1,
    builder  => '_build_database',
);

# this is after the "has" to satisfy the "requires"
with qw(MooseX::Role::DBIx::Connector Womo::Depot::Interface Any);

sub _build_catalog {
    my $self = shift;

    # TODO SQLite specific
    # TODO: toss sqlite*master tables

    my $sth = $self->db_conn->run( sub {
        $_->column_info( undef, undef, '%', '%' );
    });

#    ->primary_key_info
#    ->statistict_info( '%', '%', '%', 1, 0);

    my $all = $sth->fetchall_arrayref;
    my $x = Set::Relation::V2->new( [
        [qw(table_name column_name type_name nullable ordinal_position)],
        [ map { [ @$_[ 2, 3, 5, 10, 16 ] ] } @$all ],
    ]);

    return { columns => $x };
}

sub _build_database {
    my $self = shift;
    my $c
        = $self->catalog->{columns}
        ->projection( [qw(table_name column_name)] )
        ->group( 'columns' => [qw(column_name)] );

    my $db = {};
    # TODO: use an iterator?
    for my $t ( @{ $c->members } ) {
        my $columns = $t->{columns}->attr('column_name');
        # TODO: memory leak, circular references
        # relation has depot, depot has database which has relation
        # make database a lazy Tuple to fix?
        $db->{ $t->{table_name} } = Womo::Relation->new(
            ast => {
                'type'    => 'table',
                'heading' => Seq->new(sort @$columns),
                'args'    => [ $self, $t->{table_name}, ],
            },
        );
#        $db->{ $t->{table_name} } = Womo::Relation::Table->new(
#            depot      => $self,
#            heading    => [ sort @$columns ],
#            table_name => $t->{table_name},
#        );
    }

    return $db;
}

#__PACKAGE__->meta->make_immutable;
1;
__END__

