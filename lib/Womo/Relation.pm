
{
package Womo::Relation::Role;
use Womo::Role;
use Moose::Util qw(does_role);
use Seq;
use List::AllUtils qw(any all);
use Set::Object qw(set);
use Womo::Relation::Util;
use Womo::ASTNode;

with 'Any';

sub each   { die }
sub elems  { die }
sub enums  { die }
sub grep   { die }
sub map    { die }
sub pairs  { die }
sub tuples { die }

requires 'eager';
requires '_ast';

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

sub _has_same_heading { goto &Womo::Relation::Util::has_same_heading; }

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

sub projection   { goto &Womo::Relation::Util::projection; }
sub rename       { goto &Womo::Relation::Util::rename; }
sub restriction  { goto &Womo::Relation::Util::restriction; }
sub union        { goto &Womo::Relation::Util::union; }
sub intersection { goto &Womo::Relation::Util::intersection; }
sub insertion    { goto &Womo::Relation::Util::insertion; }
sub join         { goto &Womo::Relation::Util::join; }

}


{
package Womo::Relation::Role::FromDepot;
use Womo::Role;
use Womo::Relation::Util;
use Seq;

sub _ast {}
has '_ast' => (
    init_arg => 'ast',
    is       => 'ro',
    isa      => 'Womo::ASTNode',
    required => 1,
    coerce   => 1,
);

with 'Womo::Relation::Role';

sub _build_heading {
    my $self = shift;
    return Seq->new( @{ $self->_ast->{'heading'} } );
}

#sub _new_iterator {
#    my $self = shift;
#    return $self->_depot->new_iterator( $self->_ast );
#}

sub _members {
    my $self = shift;

    my $it = Womo::Relation::Util::new_iterator($self->_ast);
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

}


{
package Womo::Relation::InMemory;
use Womo::Class;
use List::AllUtils qw(any zip);

has '_set' => (
    is  => 'ro',
    isa => 'ArrayRef',
);

has '_ast' => (
    init_arg => 'ast',
    is       => 'ro',
    isa      => 'Womo::ASTNode',
    coerce   => 1,
);

with 'Womo::Relation::Role';

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $class = shift;

    return { _set => [], heading => Seq->new, } if ( @_ == 0 );

    if (@_ == 1 && ref($_[0]) && ref($_[0]) eq 'ARRAY') {
    }
    else {
        return $class->$orig(@_);
    }

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
};

sub BUILD { }
after 'BUILD' => sub {
    my $self = shift;
    $self->heading or confess 'need heading';
    if ( !$self->_set ) {
        $self->_ast or confess 'need either the set of items or an ast';
    }
};

sub eager {
    my $self = shift;

    require Array;
    return Array->new( @{ $self->_set } );
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

