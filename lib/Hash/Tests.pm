
package Hash::Tests;

use warnings FATAL => 'all';
use strict;

use Test::Most;
use Test::Moose;

use EnumMap::Tests;

sub test_does {
    my $class = shift or die;

    EnumMap::Tests::test_does($class);

    use_ok($class);
    does_ok( $class, 'Hash::Role' );

    my $h = $class->new( a => 1, b => 2 );
    isa_ok( $h, $class );
    does_ok( $h, 'Hash::Role' );
    ok( !$h->is_identical( $class->new( a => 1, b => 2 ) ) );
    $h->put( 'a', 3 );
    is( $h->at('a'), 3, 'put' );

}

1;
__END__

