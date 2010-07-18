
package EnumSet::Role;
use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

with (
#    'Moose::Autobox::Hash',
    'Any',
    'New',
);

sub pairs {
    my $self = shift;
    require Pair;
    return [ map { Pair->new( $_ => $self->{$_} ) } keys %$self ];
}

package EnumSet;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'EnumSet::Role';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

