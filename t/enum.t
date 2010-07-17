
use warnings FATAL => 'all';
use strict;

use Test::Most tests => 9;

use Enum;

{
    my $e = Enum->new( a => 1 );
    isa_ok( $e, 'Enum' );
    ok( $e->is_identical($e) );
    ok( $e->is_identical( Enum->new( a => 1 ) ) );
    is($e->key, 'a');
    is($e->value, '1');

    throws_ok { Enum->new(1,2,3) }   qr/expecting 2 values but got 3/, 'new 3 fails';
    throws_ok { Enum->new(1,2,3,4) } qr/expecting 2 values but got 4/, 'new 4 fails';
    throws_ok { $e->key(5) } qr/too many arguments/,   'cannot set key';
    throws_ok { $e->value(5) } qr/too many arguments/, 'cannot set value';
}

done_testing;
