
use warnings FATAL => 'all';
use strict;

use Test::Most;

use Enum;

{
    my $e = Enum->new( a => 1 );
    isa_ok( $e, 'Enum' );
    ok( $e->is_identical($e) );
    ok( $e->is_identical( Enum->new( a => 1 ) ) );
    is( $e->key,   'a' );
    is( $e->value, '1' );

    throws_ok { Enum->new( 1, 2, 3 ) } qr/expecting 2 values but got 3/,
        'new 3 fails';
    throws_ok { Enum->new( 1, 2, 3, 4 ) } qr/expecting 2 values but got 4/,
        'new 4 fails';
    throws_ok { $e->key(5) } qr/too many arguments/,   'cannot set key';
    throws_ok { $e->value(5) } qr/too many arguments/, 'cannot set value';

    my $p = $e->Pair;
    isa_ok( $p, 'Pair' );
    is( $p->key,   'a' );
    is( $p->value, '1' );
    my @p = $e->pairs->flat;
    is_deeply( \@p, [ Pair->new( 'a', 1 ) ] );

    my $t = $e->Tuple;
    isa_ok( $t, 'Tuple' );
    is( $t->at('key'),   'a' );
    is( $t->at('value'), '1' );
    my @t = $e->tuples->flat;
    is_deeply( \@t, [ Tuple->new( key => 'a', value => 1 ) ] );

}

done_testing;
