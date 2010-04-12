
package Womo::Relation::Role;
use Womo::Role;
use Set::Relation::V2;
use Set::Object qw(set);
use Moose::Util qw(does_role);
use Womo::SQL;


requires '_db_conn';
requires '_build_sql';

sub heading; # FIXME
has 'heading' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

sub _new_sql {
    my $self = shift;
    return Womo::SQL->new(@_);
}

sub _new_iterator {
    my $self = shift;

    return Womo::Relation::Iterator::STH->new(
#        relation => $self,
        sth      => $self->_new_sth,
    );
}

sub _new_sth {
    my $self = shift;

    my $sql = $self->_build_sql('a');
    print "-------------\n" . $sql->text . "\n";
    my $db_conn = $self->_db_conn;
    print join( ', ', map { "'$_'" } @{ $sql->bind } ) . "\n";
    print "---------------\n";
    my $sth = $db_conn->run( sub {
        my $sth = $_->prepare( $sql->text ) or die $_->errstr;
        $sth->execute( @{ $sql->bind } ) or die $sth->errstr;
        return $sth;
    });
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

    # TODO: validate args?
    my $attributes = $self->_array_arg(@_);

    return Womo::Relation::Projection->new(
        parent     => $self,
        attributes => $attributes,
        heading    => $attributes,
    );
}

sub _components {
    my $self = shift;
    return { map { $_ => 1 } @{ $self->heading } };
}

# TODO: the keys and values seem reversed, but this is how Set::Relation works
sub rename {
    my $self = shift;
    my $map  = $self->_hash_arg(@_);

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
        my $members = Core::join( ', ', $broke->members );
        confess "renaming to existing unrenamed attribute(s): $members";
    }

    return Womo::Relation::Rename->new(
        parent => $self,
        map    => {%$map},
        heading =>
            [ sort $orig->difference($rename)->union($new)->members ],
    );
}

# TODO: instead of only taking a CodeRef, also take some
# kind of SQL::Abstract expression (DBIx::Class::SQLAHacks)
sub restriction {
    my $self = shift;
    my $expr = @_ == 1 ? shift : { @_ };

    return Womo::Relation::Restriction->new(
        parent     => $self,
        expression => $expr,
        heading    => [ @{ $self->heading } ],
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

sub _ensure_same_headings {
    my $h1 = set( @{ $_[0]->heading } );
    my $h2 = set( @{ $_[1]->heading } );
    if ( !$h1->equal($h2) ) {
        confess "headings differ:\n["
            . Core::join( ',', @{ $_[0]->heading } ) . "]\n["
            . Core::join( ',', @{ $_[1]->heading } ) . ']';
    }
}

sub union {
    my $self = shift;

    # TODO: deal with is_empty

    return $self if ( @_ == 0 );
    my $others = $self->_array_arg_ensure_same_headings(@_);

    return $self->_reduce_op( $others, 'union', 'Womo::Relation::Union',
        [ @{ $self->heading } ],
    );
}

sub intersection {
    my $self = shift;

    confess 'TODO: infinite relation?' if ( @_ == 0 );
    my $others = $self->_array_arg_ensure_same_headings(@_);
    return $self->_reduce_op(
        $others, 'intersection',
        'Womo::Relation::Intersection',
        [ @{ $self->heading } ],
    );
}

sub join {
    my $self = shift;

    my $others = $self->_array_arg(@_);
    return $self if ( @$others == 0 );
    my $heading = set( map { @{ $_->heading } } ( $self, @$others ) );
    return $self->_reduce_op( $others, 'join', 'Womo::Relation::Join',
        [ sort $heading->members ],
    );
}

sub _reduce_op {
    my ( $self, $others, $op_method, $op_class, $heading ) = @_;

    # TODO: deal better with $others not doing Womo::Relation::Role (ie not SQL backed)
    my ( @does, @not );
    for my $r (@$others) {
        if ( does_role( $r, 'Womo::Relation::Role' ) ) {
            push @does, $r;
        }
        else {
            push @not, $r;
        }
    }

    if ( @not != 0 ) {
        my $one = shift @not;
        return ( @not ? $one->$op_method(@not) : $one )
            ->$op_method( ( @does ? $self->$op_method(@does) : $self ) );
    }

    if ( @$others == 1 ) {
        return $op_class->new(
            parent  => $self,
            other   => $others->[0],
            heading => $heading,
        );
    }
    my $one = shift @$others;
    return $self->$op_method($one)->$op_method($others);
}

sub _hash_arg {
    my $self = shift;
    my $arg
        = ( @_ == 1 && ref( $_[0] ) && ref( $_[0] ) eq 'HASH' )
        ? shift
        : {@_};
    return $arg;
}

sub _array_arg {
    my $self = shift;
    my $arg
        = ( @_ == 1 && ref( $_[0] ) && ref( $_[0] ) eq 'ARRAY' )
        ? shift
        : [@_];
    return $arg;
}

sub _array_arg_ensure_same_headings {
    my $self   = shift;
    my $others = $self->_array_arg(@_);
    $self->_ensure_same_headings($_) for (@$others);
    return $others;
}

sub insertion {
    my $self = shift;

    # TODO: make this lazy?
    return $self->_as_v2->insertion(@_);
}

# TODO: meh, ->new on what?
sub export_for_new {
    my $self = shift;
    return $self->_as_v2->export_for_new(@_);
}

# TODO: to satisfy Set::Relation
{
    my $meta   = __PACKAGE__->meta;
    my @method = (
        'antijoin',               'attr',
        'attr_names',             'body',
        'cardinality_per_group',  'classification',
        'cmpl_group',             'cmpl_proj',
        'cmpl_restr',             'cmpl_wrap',
        'composition',            'count',
        'count_per_group',        'degree',
        'deletion',               'diff',
        'empty',                  'exclusion',
        'extension',              'group',
        'has_attrs',              'has_key',
        'has_member',             'is_disjoint',
        'is_empty',               'is_nullary',
        'is_proper_subset',       'is_proper_superset',
        'is_subset',              'is_superset',
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
        'ungroup',                'unwrap',
        'which',                  'wrap'
    );
    for my $method (@method) {
        $meta->add_method(
            $method => sub { die "$method not implemented yet" } );
    }
}

with 'Set::Relation';

# timing issues
require Womo::Relation::Iterator::STH;
require Womo::Relation::Restriction;
require Womo::Relation::Projection;
require Womo::Relation::Rename;
require Womo::Relation::Union;
require Womo::Relation::Intersection;
require Womo::Relation::Join;

1;
__END__

