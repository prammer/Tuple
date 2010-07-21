
use warnings FATAL => 'all';
use strict;

use Test::Most;

use Seq;

{
    my $s = Seq->new(qw(a 1));
    isa_ok( $s, 'Seq' );
    ok( $s->is_identical($s) );
    ok( $s->is_identical( Seq->new(qw(a 1)) ) );
    ok( !$s->is_identical( Seq->new( [qw(a 1)] ) ) );
    is( $s->elems, 2 );
    my $s2 = $s->map(sub { $_ . $_ });
    is( $s2->[0], 'aa');
    is( $s2->[1], '11');
}

done_testing;
