
package Womo::Relation::Iterator;

use Womo::Class;
use Womo::Relation;

with 'MooseX::Iterator::Role';

has 'relation' => (
    is       => 'ro',
    isa      => 'Womo::Relation',
    required => 1,
);

# TODO: not sure this belongs here
has '_sql' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    builder  => '_build_sql',
);

{
    my $to_sql = {
        'projection' => sub {
            my @attributes = @_;
            return
                  "select distinct "
                . join( ", ", @attributes )
                . " from ("
                . $_->_sql . ")",
                ;
        },
        'rename' => sub {
            my %map = @_;

            # meh! this is repeated from sub rename above
            my %old_map;
            my @old_attr = @{ $_->_heading };
            @old_map{@old_attr} = @old_attr;
            my %new_map = ( %old_map, %map );

            my $clause = join( ', ',
                map { "$_ $new_map{$_}" } sort keys %new_map );
            return "select $clause from ( " . $_->_sql . ')';
        },
        'restriction' => sub {
            my $expr = shift;
            return $_->_sql . " where " . $expr;
        },
    };

    sub _build_sql {
        my $self = shift;

        # TODO: relying on private methods
        my $r    = $self->relation;
        my $expr = $r->_expr;
        if ($expr) {
            my ( $inner, $oper, @args ) = @$expr;
            local $_ = $inner;
            return $to_sql->{$oper}->(@args);
        }
        my $table = $r->_table_name or die 'must have table_name';
        my $col   = $r->_heading    or die 'must have heading';
        return 'select distinct ' . join( ', ', @$col ) . " from $table";
    }
}

has '_sth' => (
    is       => 'ro',
    required => 1,
    lazy     => 1,
    builder  => '_new_sth',
);

sub _new_sth {
    my $self = shift;

    #TODO: uses private method
    my $sql     = $self->_sql;
#    print "\n$sql\n";
    my $db_conn = $self->relation->_depot->db_conn;
    my $sth = $db_conn->run( sub { $_->prepare($sql); } );
    $sth->execute or die;
    return $sth;
}

sub next {
    my $self = shift;

    my $row = $self->_sth->fetchrow_hashref;
    return $row;
}

sub has_next {
    die;
}

sub peek {
    die;
}

1;
__END__

