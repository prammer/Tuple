
use warnings FATAL => 'all';
use strict;

use Test::Most tests => 23;

use Tuple;


{
    my $t = Tuple->new;
    isa_ok( $t, 'Tuple' );
    ok( $t->is_identical($t), 'empty is_identical to itself' );
    ok(
        $t->is_identical( Tuple->new ),
        'empty is_identical other empty'
    );
    is_deeply( [ $t->attributes ], [], 'no attributes' );
    cmp_ok( $t->degree, '==', 0, 'degree 0' );
    ok( !$t->has_attr('a'), 'no has a' );
}

{
    my $t1 = Tuple->new( a => 1, b => 2 );
    {
        my $t2 = Tuple->new( { a => 1, b => 2 } );
        ok( $t1->is_identical($t2), 'constructor hash vs ref' );
    }

    ok( $t1->is_identical($t1), 'is_identical to self' );
    cmp_bag( [ $t1->attributes ], [qw(a b)], 'correct attributes' );

    ok( $t1->has_attr('a'),  'has a' );
    ok( $t1->has_attr('b'),  'has b' );
    ok( !$t1->has_attr('c'), 'no has c' );

    cmp_ok( $t1->attr('a'), '==', 1, 'attr a' );
    cmp_ok( $t1->attr('b'), '==', 2, 'attr b' );
    dies_ok { $t1->attr('c') } 'no attr c';
    dies_ok { $t1->attr() } 'must pass someting to attr()';

    is_deeply( [ $t1->attrs(qw(a b)) ], [ 1, 2 ], 'attr array' );
    is_deeply( [ $t1->attrs(qw(b a)) ], [ 2, 1 ], 'attr array' );
    is_deeply( [ $t1->attrs( [qw(a b)] ) ], [ 1, 2 ], 'attr array' );
    is_deeply( [ $t1->attrs( [qw(b a)] ) ], [ 2, 1 ], 'attr array' );
    dies_ok { $t1->attrs(qw(a b c)) } 'no attr c';
    dies_ok { $t1->attrs( [qw(a b c)] ) } 'no attr c';

    cmp_ok( $t1->degree, '==', 2, 'degree 2' );
}

done_testing;
