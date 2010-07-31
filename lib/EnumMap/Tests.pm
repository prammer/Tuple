
package EnumMap::Tests;

use warnings FATAL => 'all';
use strict;

use Test::Most;
use Test::Moose;

use Tuple::Tests;

sub test_does {
    my $class = shift or die;

    Tuple::Tests::test_does($class);

    use_ok($class);
    does_ok( $class, 'EnumMap::Role' );

    my $e = $class->new( a => 1, b => 2 );
    isa_ok( $e, $class );
    does_ok( $e, 'EnumMap::Role' );
    ok( !defined $e->at('c'), 'no key returns undef' );
    my $s = $e->slice(qw(a c b));
    is_deeply(
        $s,
        [ 1, undef, 2 ],
        'can slice a key that does not exist'
    );
}

1;
__END__

