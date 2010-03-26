
package Womo::Relation;
use Womo::Class;
use Womo::Depot::Interface;
use Set::Relation::V2;
use Womo::Relation::Iterator;

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
    isa => 'ArrayRef',
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

    return Womo::Relation::Iterator->new( relation => $self );
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
    return (blessed $self)->new(
        _expr    => [ $self, 'projection', @attributes ],
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
    return (blessed $self)->new(
        _expr    => [ $self, 'rename', %map ],
        heading => [ sort values %new_map ],
    );
}

sub restriction {
    my $self = shift;
    my $expr = shift;
    return (blessed $self)->new(
        _expr    => [ $self, 'restriction', $expr ],
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

