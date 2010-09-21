
{
package Womo::Relation::Role;
use Womo::Role;
use Moose::Util qw(does_role);
use Seq;
use List::AllUtils qw(any all);
use Set::Object qw(set);

with 'Any';

sub each   { die }
sub elems  { die }
sub enums  { die }
sub grep   { die }
sub map    { die }
sub pairs  { die }
sub tuples { die }

requires 'eager';

sub flat {
    my $self = shift;
    return $self->eager->flat;
}

around _is_identical_class => sub {
    my $orig = shift;
    my $self = shift;
    return 1 if $self->$orig(@_);
    return 1 if ( does_role( $_[0], 'Womo::Relation::Role' ) );
    return 0;
};

has 'heading' => (
    is       => 'ro',
    isa      => 'Seq',    # Seq[Str] ?
    required => 1,
    lazy     => 1,
    builder => '_build_heading',
);

around _is_identical_value => sub {
    shift;
    my ( $self, $other ) = @_;

    return if !$self->_has_same_heading($other);
    my $a1 = $self->eager;
    my $a2 = $other->eager;
    return if ( $self->cardinality != $other->cardinality );
    return $self->contains( $other->flat );
};

sub contains {
    my ( $self, @items ) = @_;

    return 1 if ( @items == 0 );    # all sets contain the empty set
    my @all = $self->flat;
    return all {
        my $item = $_;
        any { $_->is_identical($item) } @all;
    }
    @items;
}

sub cardinality {
    my $self = shift;

    return $self->eager->elems;
    # TODO: select count(*) ... ??
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

sub _ensure_same_headings {
    if ( !$_[0]->_has_same_heading( $_[1] ) ) {
        confess "headings differ:\n["
            . Core::join( ',', @{ $_[0]->heading } ) . "]\n["
            . Core::join( ',', @{ $_[1]->heading } ) . ']';
    }
}

sub _has_same_heading {
    my $h1 = set( @{ $_[0]->heading } );
    my $h2 = set( @{ $_[1]->heading } );
    return $h1->equal($h2);
}


}


{
package Womo::Relation::Role::FromDepot;
use Womo::Role;
use Womo::Depot::Interface;
use Womo::ASTNode;
use Moose::Util qw(does_role);
use Set::Object qw(set);
use Seq;

with 'Womo::Relation::Role';

has '_ast' => (
    init_arg => 'ast',
    is       => 'ro',
    isa      => 'Womo::ASTNode',
    required => 1,
    coerce   => 1,
);

has '_depot' => (
    init_arg => 'depot',
    is       => 'ro',
    does     => 'Womo::Depot::Interface',
    required => 1,
#    handles  => { '_db_conn' => 'db_conn' },
);

sub _build_heading {
    my $self = shift;
    return Seq->new( @{ $self->_ast->{'heading'} } );
}

sub _new_iterator {
    my $self = shift;
    return $self->_depot->new_iterator( $self->_ast );

    return Womo::Relation::Iterator::STH->new(
#        relation => $self,
        sth      => $self->_new_sth,
    );
}

sub _new_sth {
    my $self = shift;
    return $self->_depot->new_sth( $self->_ast );

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

sub _members {
    my $self = shift;

    my $it = $self->_new_iterator or die;
    my @all;
    while ( my $row = $it->next ) {
        push @all, $row;
    }
    return \@all;
}

sub eager {
    my $self = shift;

    require Array;
    return Array->new( @{ $self->_members } );
}

sub _new_relation {
    my $self = shift;
    return $self->meta->name->new(@_);
}

sub projection {
    my $self = shift;

    my $attributes = $self->_array_arg(@_);
    {
        my $a     = set(@$attributes);
        my $h     = set( @{ $self->heading } );
        my $broke = $a->difference($h);
        if ( $broke->size > 0 ) {
            my $members = Core::join( ', ', $broke->members );
            confess "not attribute(s) of this relation: $members";
        }
    }

    return $self->_new_relation(
        'ast' => {
            'type'    => 'operator',
            'op'      => 'projection',
            'args'    => [ $self->_ast, $attributes, ],
            'heading' => $attributes,
        },
        'depot' => $self->_depot,
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

    return $self->_new_relation(
        'ast' => {
            'type' => 'operator',
            'op'   => 'rename',
            'args' => [ $self->_ast, {%$map}, ],
            'heading' =>
                [ sort $orig->difference($rename)->union($new)->members ],
        },
        'depot' => $self->_depot,
    );
}

# TODO: instead of only taking a CodeRef, also take some
# kind of SQL::Abstract expression (DBIx::Class::SQLAHacks)
sub restriction {
    my $self = shift;
    my $expr = @_ == 1 ? shift : {@_};

    return $self->_new_relation(
        'ast' => {
            'type'    => 'operator',
            'op'      => 'restriction',
            'args'    => [ $self->_ast, $expr, ],
            'heading' => [ @{ $self->heading } ],
        },
        'depot' => $self->_depot,
    );
}

sub union {
    my $self = shift;

    # TODO: deal with is_empty

    return $self if ( @_ == 0 );
    my $others = $self->_array_arg_ensure_same_headings(@_);

    return $self->_reduce_op( $others, 'union', [ @{ $self->heading } ], );
}

sub intersection {
    my $self = shift;

    confess 'TODO: infinite relation?' if ( @_ == 0 );
    my $others = $self->_array_arg_ensure_same_headings(@_);
    return $self->_reduce_op( $others, 'intersection',
        [ @{ $self->heading } ],
    );
}

sub join {
    my $self = shift;

    my $others = $self->_array_arg(@_);
    return $self if ( @$others == 0 );
    my $heading = set( map { @{ $_->heading } } ( $self, @$others ) );
    return $self->_reduce_op( $others, 'join', [ sort $heading->members ],
    );
}

sub _reduce_op {
    my ( $self, $others, $op, $heading ) = @_;

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
        return ( @not ? $one->$op(@not) : $one )
            ->$op( ( @does ? $self->$op(@does) : $self ) );
    }

    return $self->_new_relation(
        'ast' => {
            'type'    => 'operator',
            'op'      => $op,
            'args'    => [ map { $_->_ast } ( $self, @$others ) ],
            'heading' => $heading,

        },
        'depot' => $self->_depot,
    );
}


}


{
package Womo::Relation::InMemory;
use Womo::Class;
use List::AllUtils qw(any zip);

with 'Womo::Relation::Role';

has '_set' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    return { _set => [], heading => Seq->new, } if ( @_ == 0 );

    #XXX: do we want ->new(...) or ->new([...]) ?
    my $items = shift;
    ( @_ == 0 ) or confess 'expecting single ARRAY';
    ( ( ref($items) || '' ) eq 'ARRAY' )
        or confess 'expecting single ARRAY';
    return { _set => [], heading => Seq->new, } if ( @$items == 0 );


    my $set = [];
    my $heading;
    require Tuple;
    if ( ref( $items->[0] ) eq 'ARRAY' ) {
        ( ref( $items->[1] ) eq 'ARRAY' ) or confess 'bad args';
        ( @$items == 2 ) or confess 'bad args';
        $heading = $items->[0];
        $items   = $items->[1];
        while ( my $item = shift @$items ) {
            confess "bad value: $item" if ( !ref $item );
            ( ref($item) eq 'ARRAY' ) or confess "bad value: $item";
            $item = Tuple->new( zip @$heading, @$item )
                or confess 'failed to create Tuple';
            next if any { $item->is_identical($_) } @$set;
            push @$set, $item;
        }
        $heading = Seq->new( CORE::sort @$heading );
    }
    elsif ( ref( $items->[0] ) eq 'HASH' or ref( $items->[0] ) eq 'Tuple' ) {
        while ( my $item = shift @$items ) {
            confess "bad value: $item" if ( !ref $item );
            if ( ref($item) eq 'HASH' ) {
                $item = Tuple->new($item)
                    or confess 'failed to create Tuple';
            }
            elsif ( !ref($item) ) {
                confess "bad value: $item";
            }
            $item->isa('Tuple') or confess "bad value: $item";
            $heading ||= $item->heading;
            $heading->is_identical( $item->heading )
                or confess 'inconsistent headings (keys)';
            next if any { $item->is_identical($_) } @$set;
            push @$set, $item;
        }
    }
    else {
        confess 'bad args';
    }

    return { _set => $set, heading => $heading, };
}

sub eager {
    my $self = shift;

    require Array;
    return Array->new( @{ $self->_set } );
}

sub union {
    die;
    my $self = shift;

    # TODO: deal with is_empty

    return $self if ( @_ == 0 );
    my $others = $self->_array_arg_ensure_same_headings(@_);

    return $self->_reduce_op( $others, 'union', [ @{ $self->heading } ], );
}

}


{
package Womo::Relation;
use Womo::Class;

with 'Womo::Relation::Role::FromDepot';

#sub _is_identical_value {
#    my ( $self, $other ) = @_;
#
#    # TODO: compare ast and depot
#}



}

1;
__END__

