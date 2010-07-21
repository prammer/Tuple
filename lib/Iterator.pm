
package Iterator;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

with(
    'MooseX::Iterator::Role',
    'Any',
);

1;
__END__

