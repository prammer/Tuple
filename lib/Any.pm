
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

1;
__END__

