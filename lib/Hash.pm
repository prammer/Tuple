
package Hash::Role;
use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;
use EnumMap;

with (
    'EnumMap::Role',
);


package Hash;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Hash::Role';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

