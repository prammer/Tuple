
use warnings FATAL => 'all';
use strict;

use Test::Most;

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
    is_deeply( [ $t->keys ], [], 'no keys' );
    cmp_ok( $t->degree, '==', 0, 'degree 0' );
    cmp_ok( $t->elems, '==', 0, 'elems 0' );
    ok( !$t->has_attr('a'), 'no has a' );
    ok( !$t->exists('a'), 'no has a' );
}

{
    my $t1 = Tuple->new( a => 1, b => 2 );
    {
        my $t2 = Tuple->new( { a => 1, b => 2 } );
        ok( $t1->is_identical($t2), 'constructor hash vs ref' );
    }

    ok( $t1->is_identical($t1), 'is_identical to self' );
    cmp_bag( [ $t1->keys ], [qw(a b)], 'correct keys' );

    ok( $t1->has_attr('a'),  'has a' );
    ok( $t1->exists('a'),  'has a' );
    ok( $t1->has_attr('b'),  'has b' );
    ok( !$t1->has_attr('c'), 'no has c' );
    ok( !$t1->exists('c'), 'no has c' );

    cmp_ok( $t1->attr('a'), '==', 1, 'attr a' );
    cmp_ok( $t1->at('a'), '==', 1, 'attr a' );
    cmp_ok( $t1->attr('b'), '==', 2, 'attr b' );
    dies_ok { $t1->attr('c') } 'no attr c';
    dies_ok { $t1->at('c') } 'no attr c';
    dies_ok { $t1->attr() } 'must pass someting to attr()';

    is_deeply( [ $t1->attrs(qw(a b)) ], [ 1, 2 ], 'attr array' );
    is_deeply( [ $t1->slice(qw(a b)) ], [ 1, 2 ], 'attr array' );
    is_deeply( [ $t1->attrs(qw(b a)) ], [ 2, 1 ], 'attr array' );
    is_deeply( [ $t1->attrs( [qw(a b)] ) ], [ 1, 2 ], 'attr array' );
    is_deeply( [ $t1->attrs( [qw(b a)] ) ], [ 2, 1 ], 'attr array' );
    is_deeply( [ $t1->slice( [qw(b a)] ) ], [ 2, 1 ], 'attr array' );
    dies_ok { $t1->attrs(qw(a b c)) } 'no attr c';
    dies_ok { $t1->attrs( [qw(a b c)] ) } 'no attr c';

    cmp_ok( $t1->degree, '==', 2, 'degree 2' );
    cmp_ok( $t1->elems, '==', 2, 'elems 2' );
}

{
    my $t = Tuple->new( a => 1, b => 2 );
    my @e = $t->enums->flat;
    cmp_bag( \@e, [ Enum->new( 'a', 1 ), Enum->new( 'b', 2 ) ] );
    my @p = $t->pairs->flat;
    cmp_bag( \@p, [ Pair->new( 'a', 1 ), Pair->new( 'b', 2 ) ] );
    my @t = $t->tuples->flat;
    is_deeply( \@t, [$t] );
    my $em = $t->EnumMap;
    isa_ok($em, 'EnumMap');
    my $h = $t->Hash;
    isa_ok($h, 'Hash');
}

done_testing;
