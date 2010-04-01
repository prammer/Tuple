
package Womo::Relation;
use Womo::Class;
use Womo::Depot::Interface;
use Set::Relation::V2;
require Womo::Relation::Iterator;
require Womo::Relation::Operator;

has '_depot' => (
    init_arg => 'depot',
    is       => 'ro',
    does     => 'Womo::Depot::Interface',
);

has '_table_name' => (
    init_arg => 'table_name',
    is       => 'ro',
    isa      => 'Str',
);

has '_expr' => (
    is  => 'ro',
    isa => 'Womo::Relation::Operator',
);

has '_heading' => (
    init_arg => 'heading',
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

# TODO: make sure we have depot+table_name or expr ??

sub _new_iterator {
    my $self = shift;

    return Womo::Relation::Iterator->new( relation => $self, sth => $self->_new_sth, );
}

sub _new_operator {
    my $self = shift;
    return Womo::Relation::Operator->new( @_, relation => $self, );
}

{
    my $to_sql = {
        'projection' => sub {
            my @attributes = @_;
            return
                  "select distinct "
                . join( ", ", @attributes )
                . " from ("
                . $_->_build_sql . ")",
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
            return "select $clause from ( " . $_->_build_sql . ')';
        },
        'restriction' => sub {
            my $expr = shift;
            return $_->_build_sql . " where " . $expr;
        },
    };

    sub _build_sql {
        my $self = shift;

        my $r    = $self;
        my $expr = $r->_expr;
        if ($expr) {
            my ( $inner, $oper, $args ) = map { $expr->$_ } qw(relation name args);
            local $_ = $inner;
            return $to_sql->{$oper}->(@$args);
        }
        my $table = $r->_table_name or die 'must have table_name';
        my $col   = $r->_heading    or die 'must have heading';
        return 'select distinct ' . join( ', ', @$col ) . " from $table";
    }
}

sub _new_sth {
    my $self = shift;

    my $sql     = $self->_build_sql;
#    print "\n$sql\n";
    my $db_conn = $self->_depot->db_conn;
    my $sth = $db_conn->run( sub { $_->prepare($sql); } );
    $sth->execute or die;
    return $sth;
}

sub members {
    my $self = shift;

    my $it = $self->_new_iterator or die;
    my @all;
    while ( my $row = $it->next ) {
        push @all, $row;
    }
    return \@all;
}

sub projection {
    my $self       = shift;
    my @attributes = @_;
    return ( blessed $self)->new(
        _expr => $self->_new_operator(
            name => 'projection',
            args => \@attributes,
        ),
        heading => [@attributes],
    );
}

sub rename {
    my $self = shift;
    my %map  = @_;
    my %old_map;
    my @old_attr = @{ $self->_heading };
    @old_map{@old_attr} = @old_attr;
    my %new_map = ( %old_map, %map );
    return ( blessed $self)->new(
        _expr => $self->_new_operator( name => 'rename', args => [%map], ),
        heading => [ sort values %new_map ],
    );
}

# TODO: instead of only taking a CodeRef, also take some
# kind of SQL::Abstract expression
sub restriction {
    my $self = shift;
    my $expr = shift;
    return ( blessed $self)->new(
        _expr => $self->_new_operator(
            name => 'restriction',
            args => [$expr],
        ),
        heading => [ @{ $self->_heading } ],
    );
}

sub _as_v2 {
    my $self = shift;
    return Set::Relation::V2->new( $self->members );
}

sub is_identical {
    my ( $self, $other ) = @_;
    return 1 if ( $self == $other );
    return $self->_as_v2->is_identical(
        Set::Relation::V2->new( $other->members ) );
}

# TODO: to satisfy Set::Relation
{
    my $meta   = __PACKAGE__->meta;
    my @method = (
        'antijoin',               'attr',
        'attr_names',             'body',
        'cardinality',            'cardinality_per_group',
        'classification',         'cmpl_group',
        'cmpl_proj',              'cmpl_restr',
        'cmpl_wrap',              'composition',
        'count',                  'count_per_group',
        'degree',                 'deletion',
        'diff',                   'empty',
        'exclusion',              'export_for_new',
        'extension',              'group',
        'has_attrs',              'has_key',
        'has_member',             'heading',
        'insertion',              'intersection',
        'is_disjoint',            'is_empty',
        'is_nullary',             'is_proper_subset',
        'is_proper_superset',     'is_subset',
        'is_superset',            'join',
        'join_with_group',        'keys',
        'limit',                  'limit_by_attr_names',
        'map',                    'outer_join_with_exten',
        'outer_join_with_group',  'outer_join_with_static_exten',
        'outer_join_with_undefs', 'product',
        'quotient',               'rank',
        'rank_by_attr_names',     'restr_and_cmpl',
        'semidiff',               'semijoin',
        'semijoin_and_diff',      'slice',
        'static_exten',           'static_subst',
        'static_subst_in_restr',  'static_subst_in_semijoin',
        'subst_in_restr',         'subst_in_semijoin',
        'substitution',           'summary',
        'symmetric_diff',         'tclose',
        'ungroup',                'union',
        'unwrap',                 'which',
        'wrap'
    );
    for my $method (@method) {
        $meta->add_method( $method => sub { die 'not implemented yet' } );
    }
}

with 'Set::Relation';

1;
__END__

