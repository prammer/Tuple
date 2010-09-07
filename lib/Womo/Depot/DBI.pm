
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
with qw(MooseX::Role::DBIx::Connector Womo::Depot::Interface);

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
        $db->{ $t->{table_name} } = Womo::Relation->new(
            ast => {
                'type'    => 'table',
                'name'    => $t->{table_name},
                'heading' => [ sort @$columns ],
            },
            depot => $self,
        );
#        $db->{ $t->{table_name} } = Womo::Relation::Table->new(
#            depot      => $self,
#            heading    => [ sort @$columns ],
#            table_name => $t->{table_name},
#        );
    }

    return $db;
}

sub new_iterator {
    my $self = shift;
    my $ast = shift or confess 'must pass ast';

    if ( _ast_can_full_sql($ast) ) {
        return Womo::Relation::Iterator::STH->new(
            sth => $self->_new_sth($ast), );
    }

    if ( $ast->type eq 'operator' ) {
        return $self->_new_iterator_op($ast);
    }

    die "not implemented";
}

sub _new_iterator_op {
    my $self = shift;
    my $ast  = $_[0];

    my $method = '_new_iterator_' . $ast->op;
    if ( !$self->can($method) ) {
#        $DB::single = 1;
        die "not implemented " . $ast->op;
    }
    return $self->$method(@_);
}

sub _new_iterator_restriction {
    my ( $self, $ast ) = @_;

    my $parent_it = $self->new_iterator( $ast->args->[0] );
    my $want      = $ast->args->[1];
    return Womo::Relation::Iterator::CodeRef->new(

        code => sub {
            while (1) {
                my $next = $parent_it->next or return;
                local $_ = $next;
                return $next if $want->($next);
            }
        }
    );
}

sub _new_iterator_projection {
    my ( $self, $ast ) = @_;

    my $parent_it = $self->new_iterator( $ast->args->[0] );
    my @attr      = @{ $ast->args->[1] };
    return Womo::Relation::Iterator::CodeRef->new(

        code => sub {
            while (1) {
                my $next = $parent_it->next or return;
                my %new;
                @new{@attr} = @$next{@attr};
                return \%new;
            }
        }
    );
}

sub _ast_can_full_sql {
    my $ast = shift or die;
    for my $sub ( _sub_ast($ast) ) {
        return 0 if !_ast_can_full_sql($sub);
    }
    return 0
        if ( $ast->type eq 'operator'
        && $ast->op eq 'restriction'
        && ref( $ast->args->[1] ) eq 'CODE' );
    return 1;
}

sub _sub_ast {
    my $ast = shift or die;
    grep { blessed($_) && blessed($_) eq 'Womo::ASTNode' } @{ $ast->args };
}

sub _new_sql {
    my $self = shift;
    return Womo::SQL->new(@_);
}

sub _build_sql {
    my $self = shift;
    my $ast = $_[0];

    if ($ast->type eq 'table') {
        return $self->_build_sql_table(@_);
    }
    elsif ($ast->type eq 'operator') {
        my $method = '_build_sql_' . $ast->op;
        return $self->$method(@_);
    }
    else {
        die 'wha!?';
    }
}

sub _build_sql_table {
    my ( $self, $ast, $next_label ) = @_;

    # TODO: if heading includes any key, leave off distinct
    my $table = $ast->{name};
    my $col   = $ast->{heading};
    return $self->_new_sql(
        'lines' =>
            [ 'select distinct ' . join( ', ', @$col ) . " from $table" ],
        'bind'       => [],
        'next_label' => $next_label,
    );
}

sub _build_sql_restriction {
    my ( $self, $ast, $next_label ) = @_;

    my $sql = SQL::Abstract->new;
    my ( $stmt, @bind ) = $sql->where( $ast->{args}->[1] );
    my @table;
    if ( $ast->{args}->[0]->{type} eq 'table' ) {
        @table = ( $ast->{args}->[0]->{name} );
    }
    else {
        my $p_sql = $self->_build_sql( $ast->{args}->[0], $next_label );
        $next_label = $p_sql->next_label,
        @table = ( '(', $p_sql, ')' );
        unshift @bind, @{ $p_sql->bind };
    }

    return $self->_new_sql(
        'lines'      => [ 'select distinct * from', @table, $stmt, ],
        'bind'       => \@bind,
        'next_label' => $next_label,
    );
}

sub _build_sql_projection {
    my ( $self, $ast, $next_label ) = @_;

    if ( $ast->{args}->[0]->{type} eq 'table' ) {
        my $table = $ast->{args}->[0]->{name};
        return $self->_new_sql(
            'lines' => [
                "select distinct " . join( ", ", @{ $ast->{heading} } ),
                "from $table",
            ],
            'bind'       => [],
            'next_label' => $next_label,
        );
    }

    my $p_sql = $self->_build_sql( $ast->{args}->[0], $next_label );
    return $self->_new_sql(
        'lines' => [
            "select distinct " . join( ", ", @{ $ast->{heading} } ),
            'from (', $p_sql, ')',
        ],
        'bind'       => $p_sql->bind,
        'next_label' => $p_sql->next_label,
    );
}

sub _build_sql_rename {
    my ( $self, $ast, $next_label ) = @_;

    my $map  = $ast->{args}->[1];
    my $comp = set( @{ $ast->{args}->[0]->{heading} } )
        ->difference( values %$map );
    my $clause = join( ', ',
        ( sort $comp->members ),
        ( map { "$map->{$_} $_" } sort keys %$map ) );
    if ( $ast->{args}->[0]->{type} eq 'table' ) {
        return $self->_new_sql(
            'lines' => [
                "select distinct $clause from "
                    . $ast->{args}->[0]->{name},
            ],
            'bind'       => [],
            'next_label' => $next_label,
        );
    }
    my $p_sql = $self->_build_sql( $ast->{args}->[0], $next_label );
    return $self->_new_sql(
        'lines'      => [ "select $clause from (", $p_sql, ')', ],
        'bind'       => $p_sql->bind,
        'next_label' => $p_sql->next_label,
    );
}

sub _all_sql_reduce_bind {
    my ( $self, $to_reduce, $next_label ) = @_;
    my @sql;
    for my $ast ( @{$to_reduce} ) {
        push @sql, $self->_build_sql( $ast, $next_label );
        $next_label = $sql[-1]->next_label;
    }
    my $bind = [ map { @{ $_->bind } } @sql ];
    return ( \@sql, $bind );
}

sub _build_sql_union {
    my ( $self, $ast, $next_label ) = @_;

    my ( $sql, $bind ) = $self->_all_sql_reduce_bind( $ast->{args}, $next_label );
    $sql = [ map { ( $_, 'union' ) } @$sql ];
    pop @$sql;
    return $self->_new_sql(
        'lines'      => $sql,
        'bind'       => $bind,
        'next_label' => $next_label,
    );
}

sub _build_sql_intersection {
    my ( $self, $ast, $next_label ) = @_;

    my ( $sql, $bind ) = $self->_all_sql_reduce_bind( $ast->{args}, $next_label );
    $sql = [ map { ( $_, 'intersect' ) } @$sql ];
    pop @$sql;
    return $self->_new_sql(
        'lines'      => $sql,
        'bind'       => $bind,
        'next_label' => $next_label,
    );
}

sub _build_sql_join {
    my ( $self, $ast, $next_label ) = @_;

    my @chunks = map {
        my $h = set( @{ $_->{heading} } );
        my $to_join_sql = $self->_build_sql( $_, $next_label );
        $next_label = $to_join_sql->next_label;
        { 'sql' => $to_join_sql, 'heading' => $h, 'ast' => $_, };
    } @{ $ast->{args} };

    $_->{label} = $next_label++ for (@chunks);

    my @select;
    my $selected = set();
    my $previous;
    my @table_joins;
    my %labeled_attribute;
    for my $chunk (@chunks) {
        my $to_select = $chunk->{heading}->difference($selected);
        my $common    = $chunk->{heading}->intersection($selected);
        my $l         = $chunk->{label};
        push @select, map { "$l.$_ $_" } sort $to_select->members;
        $labeled_attribute{$_} = "$l.$_" for ( $to_select->members );
        $selected = $selected->union($to_select);
        my @this;
        if ( $chunk->{ast}->{type} eq 'table' ) {
            @this = ( $chunk->{ast}->{name} . " $l" );
        }
        else {
            @this = ( '(', $chunk->{sql}, ") $l" );
        }
        if ($previous) {
            unshift @this, 'join';

            if ( $common->size > 0 ) {
                my @on = (
                    'on ('
                        . join( ' and ',
                        map { "$l.$_ = $labeled_attribute{$_}" }
                        sort $common->members )
                        . ')'
                );
                push @this, @on;
            }
        }
        push @table_joins, @this;
        $previous = $chunk;
    }

    my $bind = [ map { @{ $_->{sql}->bind } } @chunks ];

    return $self->_new_sql(
        'lines' => [
            'select distinct', join( ', ', @select ),
            'from', @table_joins,
        ],
        'bind'       => $bind,
        'next_label' => $next_label,
    );
}


sub _new_sth {
    my $self = shift;
    my $ast = shift or confess 'must pass ast';

    my $sql = $self->_build_sql( $ast, 'a');
    print "-------------\n" . $sql->text . "\n";
    my $db_conn = $self->db_conn;
    print join( ', ', map { "'$_'" } @{ $sql->bind } ) . "\n";
    print "---------------\n";
    my $sth = $db_conn->run( sub {
        my $sth = $_->prepare( $sql->text ) or die $_->errstr;
        $sth->execute( @{ $sql->bind } ) or die $sth->errstr;
        return $sth;
    });
    return $sth;
}

#__PACKAGE__->meta->make_immutable;
1;
__END__

