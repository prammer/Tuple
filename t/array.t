
use warnings FATAL => 'all';
use strict;

use Test::Most;
use Test::Moose;

use Array;

{
    my $a = Array->new(qw(a 1));
    isa_ok( $a, 'Array' );
    ok( $a->is_identical($a) );
    ok( !$a->is_identical( Array->new(qw(a 1)) ) );
    ok( !$a->is_identical( Array->new( [qw(a 1)] ) ) );
    is( $a->elems, 2 );
    my $i = $a->map( sub { $_ . $_ } );
    does_ok( $i, 'Iterator' );
    my $a2 = $i->eager;
    isa_ok( $a2, 'Array' );
    is( $a2->elems, 2 );
    is( $a2->[0],   'aa' );
    is( $a2->[1],   '11' );
}

done_testing;
