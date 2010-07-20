
use warnings FATAL => 'all';
use strict;

use Test::Most tests => 4;

use Seq;

{
    my $s = Seq->new(qw(a 1));
    isa_ok( $s, 'Seq' );
    ok( $s->is_identical($s) );
    ok( $s->is_identical( Seq->new(qw(a 1)) ) );
    ok( !$s->is_identical( Seq->new( [qw(a 1)] ) ) );

}

done_testing;
