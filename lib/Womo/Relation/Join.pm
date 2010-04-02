
package Womo::Relation::Join;
use Womo::Class;
use Set::Object qw(set);

with 'Womo::Relation::Derived';

has '_other' => (
    init_arg => 'other',
    is       => 'ro',
#TODO: other kinds of relations, like non-SQL
    does     => 'Womo::Relation::Role',
    required => 1,
);

sub _build_sql {
    my $self = shift;

    my $r1 = $self->_parent;
    my $r2 = $self->_other;

    # meh, this is ugly.  need to build SQL at the end with whole
    # clause, not piece by piece like this
    # the labels (a, b) will likely be a problem or at least confusing

    my $h1     = set( @{ $r1->heading } );
    my $h2     = set( @{ $r2->heading } );
    my $common = $h1->intersection($h2);
    my $d1     = $h1->difference($h2);
    my $d2     = $h2->difference($h1);
    my $l1     = 'a';
    my $l2     = 'b';

    my $select
        = "select "
        . join( ', ', ( map {"$l1.$_"} $d1->union($common)->members ), '' )
        . join( ', ', map {"$l2.$_"} $d2->members );
    my $a  = '( ' . $r1->_build_sql . " ) $l1";
    my $b  = '( ' . $r2->_build_sql . " ) $l2";
    my $on = join( 'and ', map {"$l1.$_ = $l2.$_"} $common->members );

    #    select ... from (...) a join (...) b on a.x = b.x, ...

    return "$select from\n$a\njoin\n$b\non $on";
}

1;

__END__

