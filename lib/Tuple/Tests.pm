
package Tuple::Tests;

use warnings FATAL => 'all';
use strict;

use Test::Most;
use Test::Moose;

sub test_identity {
    my $class = shift or die;

    use_ok($class);

    my $t = $class->new;
    ok( $t->is_identical( $class->new ),
        'empty is_identical other empty' );

    {
        my $t1 = $class->new( a => 1, b => 2 );
        {
            my $t2 = $class->new( { a => 1, b => 2 } );
            ok( $t1->is_identical($t2), 'constructor hash vs ref' );
        }
    }
}

sub test_does {
    my $class = shift or die;

    use_ok($class);
    does_ok($class, 'Tuple::Role');

    {
        my $t = $class->new;
        isa_ok( $t, $class );
        does_ok( $t, 'Tuple::Role' );
        ok( $t->is_identical($t), 'empty is_identical to itself' );
        is_deeply( $t->keys, [], 'no keys' );
        cmp_ok( $t->elems, '==', 0, 'elems 0' );
        ok( !$t->exists('a'), 'no has a' );
    }

    {
        my $t1 = $class->new( a => 1, b => 2 );
        does_ok($t1, 'Tuple::Role');
        ok( $t1->is_identical($t1), 'is_identical to self' );
        cmp_bag( [ $t1->keys->flat ], [qw(a b)], 'correct keys' );

        is_deeply( [ sort $t1->flat ], [ 1, 2, 'a', 'b' ], 'flat' );

        ok( $t1->exists('a'),  'has a' );
        ok( $t1->exists('b'),  'has b' );
        ok( !$t1->exists('c'), 'no has c' );

        cmp_ok( $t1->at('a'), '==', 1, 'at a' );
        cmp_ok( $t1->at('b'), '==', 2, 'at b' );
        dies_ok { $t1->at() } 'must pass someting to at()';

        is_deeply( $t1->slice(qw(a b)), [ 1, 2 ], 'slice array' );
        is_deeply( $t1->slice(qw(b a)), [ 2, 1 ], 'slice array' );
        is_deeply( $t1->slice( [qw(a b)] ), [ 1, 2 ], 'slice array' );
        is_deeply( $t1->slice( [qw(b a)] ), [ 2, 1 ], 'slice array' );
        is_deeply( $t1->slice( [qw(b a)] ), [ 2, 1 ], 'slice array' );

        cmp_ok( $t1->elems, '==', 2, 'elems 2' );

        cmp_bag( [ $t1->values->flat ], [ 1, 2 ], 'values' );
    }

    {
        my $t = $class->new( a => 1, b => 2 );
        my @e = $t->enums->flat;
        cmp_bag( \@e, [ Enum->new( 'a', 1 ), Enum->new( 'b', 2 ) ] );
        my @p = $t->pairs->flat;
        cmp_bag( \@p, [ Pair->new( 'a', 1 ), Pair->new( 'b', 2 ) ] );
#        my @t = $t->tuples->flat;
#        is_deeply( \@t, [$t] );
        my $em = $t->EnumMap;
        isa_ok( $em, 'EnumMap' );
        my $h = $t->Hash;
        isa_ok( $h, 'Hash' );
    }
}

sub test_no_key_fail {
    my $class = shift or die;

    my $t = $class->new( a => 1, b => 2 );
    dies_ok { $t->at('c') } 'no at c';
    dies_ok { $t->slice(qw(a b c)) } 'no slice c';
    dies_ok { $t->slice( [qw(a b c)] ) } 'no slice c';
}

sub test_tie {
    my $class = shift or die;
    my $t = $class->new( a => 1, b => 2 );
    is( $t->{'a'}, 1, 'access as hash' );
    is( $t->{'b'}, 2, 'access as hash' );
    dies_ok { $t->{'c'} } 'no key throws as hash';
    dies_ok { delete $t->{'a'} } 'delete throws as hash';
    dies_ok { $t->{'a'} = 5 } 'assign throws as hash';
    dies_ok { $t->{'c'} = 5 } 'assign throws as hash';
    dies_ok { %$t = (); } 'clear throws as hash';
    dies_ok { @{$t}{qw(a b)} = (4, 5) } 'assign slice throws as hash';
    my @v = @{$t}{qw(a b)}
}

1;
__END__

