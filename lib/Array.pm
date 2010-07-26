
# a fully reified Perl 5 array -- no iterators or lazyness

package Array::Role;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

with (
    'BlessedArray',
    'Any',
    'Moose::Autobox::Array',
);

package Array;
use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Array::Role';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

