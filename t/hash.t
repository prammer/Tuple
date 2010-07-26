
use warnings FATAL => 'all';
use strict;

use Test::Most tests => 15;

use Hash;
use Tuple;
use Pair;


{
    my $h = Hash->new( a => 1, b => 2 );
    isa_ok( $h, 'Hash' );
    ok( $h->is_identical($h) );
    ok( !$h->is_identical( Hash->new( a => 1, b => 2 ) ) );
    my $it = $h->tuples;
    my @t;
    while ($it->has_next) {
        my $t = $it->next;
        isa_ok($t, 'Tuple');
        push @t, $t;
    }
    @t = sort { $a->attr('key') cmp $b->attr('key') } @t;
    ok( $t[0]->is_identical( Tuple->new( key => 'a', value => 1 ) ) );
    ok( $t[1]->is_identical( Tuple->new( key => 'b', value => 2 ) ) );

    my $p = $h->pairs->eager;
    isa_ok( $_, 'Pair' ) for (@$p);
    $p = [sort { $a->key cmp $b->key } @$p];
    is( $p->[0]->key, 'a' );
    is( $p->[0]->value, 1 );
    is( $p->[1]->key, 'b' );
    is( $p->[1]->value, 2 );
    ok( !$p->[0]->is_identical( Pair->new( 'a', 1 ) ) );
    ok( !$p->[1]->is_identical( Pair->new( 'b', 2 ) ) );
}

done_testing;
