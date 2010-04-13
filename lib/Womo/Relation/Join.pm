
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
    my ( $self, $next_label ) = @_;

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
    my $r1_sql = $r1->_build_sql($next_label);
    my $r2_sql = $r2->_build_sql( $r1_sql->next_label );
    $next_label = $r2_sql->next_label;
    my $l1 = $next_label++;
    my $l2 = $next_label++;

    my $select
        = "select "
        . join( ', ', ( map { "$l1.$_ $_" } sort $d1->union($common)->members ),
        '' )
        . join( ', ', map { "$l2.$_ $_" } sort $d2->members );
    my @on = ();
    if ( $common->size > 0 ) {
        @on = (
            'on ('
                . join( ' and ',
                map { "$l1.$_ = $l2.$_" } sort $common->members )
                . ')'
        );
    }

#    my $a  = '( ' . $r1_sql->text . " ) $l1";
#    my $b  = '( ' . $r2_sql->text . " ) $l2";
    #    select ... from (...) a join (...) b on a.x = b.x, ...
    return $self->_new_sql(
        'lines' => [
            $select, 'from', '(',
                $r1_sql,
            ") $l1",
            'join', '(',
                $r2_sql,
            ") $l2",
            @on,
        ],
        'bind'       => $r1_sql->combine_bind($r2_sql),
        'next_label' => $next_label,
    );
}

1;

__END__

