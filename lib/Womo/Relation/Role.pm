
package Womo::Relation::Role;
use Womo::Role;
use Set::Relation::V2;
use Set::Object qw(set);

requires '_db_conn';

has '_heading' => (
    init_arg => 'heading',
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

sub _new_iterator {
    my $self = shift;

    return Womo::Relation::Iterator::STH->new( relation => $self, sth => $self->_new_sth, );
}

sub _new_sth {
    my $self = shift;

    my $sql     = $self->_build_sql;
#    print "\n$sql\n";
    my $db_conn = $self->_db_conn;
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
    my $attributes = [@_];

    return Womo::Relation::Projection->new(
        parent     => $self,
        attributes => $attributes,
        heading    => $attributes,
    );
}

sub _components {
    my $self = shift;
    return { map { $_ => 1 } @{ $self->_heading } };
}

sub rename {
    my ( $self, $map ) = @_;

    my $comp = $self->_components;
    for my $attr ( values %$map ) {
        confess "'$attr' is not an attribute of this relation"
            if ( !$comp->{$attr} );
    }

    # check for values %$map in keys %$comp but not in keys %$map
    my $orig   = set( keys %$comp );
    my $new    = set( keys %$map );
    my $rename = set( values %$map );
    my $broke  = $orig->intersection($new)->difference($rename);
    if ( $broke->size > 0 ) {
        my $members = join( ', ', $broke->members );
        confess "renaming to existing unrenamed attribute(s): $members";
    }

    return Womo::Relation::Rename->new(
        parent  => $self,
        map     => {%$map},
        heading => [ sort $new->members ],
    );
}

# TODO: instead of only taking a CodeRef, also take some
# kind of SQL::Abstract expression (DBIx::Class::SQLAHacks)
sub restriction {
    my $self = shift;
    my $expr = shift;

    return Womo::Relation::Restriction->new(
        parent     => $self,
        expression => $expr,
        heading    => [ @{ $self->_heading } ],
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

sub cardinality {
    my $self = shift;

    # TODO: select count(*) ... ??
    return $self->_as_v2->cardinality;
}

# TODO: to satisfy Set::Relation
{
    my $meta   = __PACKAGE__->meta;
    my @method = (
        'antijoin',                     'attr',
        'attr_names',                   'body',
        'cardinality_per_group',        'classification',
        'cmpl_group',                   'cmpl_proj',
        'cmpl_restr',                   'cmpl_wrap',
        'composition',                  'count',
        'count_per_group',              'degree',
        'deletion',                     'diff',
        'empty',                        'exclusion',
        'export_for_new',               'extension',
        'group',                        'has_attrs',
        'has_key',                      'has_member',
        'heading',                      'insertion',
        'intersection',                 'is_disjoint',
        'is_empty',                     'is_nullary',
        'is_proper_subset',             'is_proper_superset',
        'is_subset',                    'is_superset',
        'join',                         'join_with_group',
        'keys',                         'limit',
        'limit_by_attr_names',          'map',
        'outer_join_with_exten',        'outer_join_with_group',
        'outer_join_with_static_exten', 'outer_join_with_undefs',
        'product',                      'quotient',
        'rank',                         'rank_by_attr_names',
        'restr_and_cmpl',               'semidiff',
        'semijoin',                     'semijoin_and_diff',
        'slice',                        'static_exten',
        'static_subst',                 'static_subst_in_restr',
        'static_subst_in_semijoin',     'subst_in_restr',
        'subst_in_semijoin',            'substitution',
        'summary',                      'symmetric_diff',
        'tclose',                       'ungroup',
        'union',                        'unwrap',
        'which',                        'wrap'
    );
    for my $method (@method) {
        $meta->add_method( $method => sub { die 'not implemented yet' } );
    }
}

with 'Set::Relation';

# timing issues
require Womo::Relation::Iterator::STH;
require Womo::Relation::Restriction;
require Womo::Relation::Projection;
require Womo::Relation::Rename;

1;
__END__

