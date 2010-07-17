
use warnings FATAL => 'all';
use strict;

use Test::Most tests => 10;

use Pair;

{
    my $p = Pair->new( a => 1 );
    isa_ok( $p, 'Pair' );
    ok( $p->is_identical($p) );
    ok( !$p->is_identical( Pair->new( a => 1 ) ) );
    is($p->key, 'a');
    is($p->value, '1');

    throws_ok { Pair->new(1,2,3) }   qr/expecting 2 values but got 3/, 'new 3 fails';
    throws_ok { Pair->new(1,2,3,4) } qr/expecting 2 values but got 4/, 'new 4 fails';
    throws_ok { $p->key(5) } qr/too many arguments/,   'cannot set key';
    lives_ok { $p->value(5) } 'can set value';
    is($p->value, 5);
}

done_testing;
