
package BlessedArray;

# a raw blessed Perl 5 array reference

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

with (
    'New',
);

sub BUILDARGS {
    my $class = shift;
    return [@_];
}

1;
__END__

