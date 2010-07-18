
package Hash::Role;
use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;
use EnumSet;

with (
    'Moose::Autobox::Hash',
    'EnumSet::Role',
);

package Hash;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Hash::Role';

sub iterator {
    my $self = shift;
    require Tuple;
    require Iterator::Code;
    my $h = {%$self};
    return Iterator::Code->new(sub {
        my $k = ( keys(%$h) )[0];
        return if !defined $k;
        return Tuple->new( key => $k, value => delete $h->{$k}, );
    });
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

