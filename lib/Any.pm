
package Any;

use Moose::Role;
use warnings FATAL => 'all';
use Scalar::Util qw(refaddr);
use namespace::autoclean;

with (
#    'MooseX::Identity::Role',
    'MooseX::WHICH',
);

sub WHICH { return refaddr( $_[0] ) }

requires (
    'elems',
    'map',
    'grep',
    'each',
    'enums',
    'pairs',
    'tuples',
);

1;
__END__

