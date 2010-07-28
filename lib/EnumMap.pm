
package EnumMap::Role;
use Moose::Role;
use warnings FATAL => 'all';
use Tuple;
use namespace::autoclean;

with(
# TODO: is this a bug in Moose?
    'Tuple::Role' => { excludes => [qw(tuples)] },
#    'Tuple::Role',
);

sub tuples {
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


package EnumMap;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

extends 'Tuple';
with 'EnumMap::Role';

#sub put    { confess 'cannot modify' }
#sub delete { confess 'cannot modify' }

#sub WHICH { return $_[0] }

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

