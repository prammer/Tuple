
package EnumMap::Role;
use Moose::Role;
use warnings FATAL => 'all';
use Tuple;
use namespace::autoclean;

with(
# TODO: is this a bug in Moose?
    'Tuple::Role' => { excludes => [qw(tuples at)] },
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

sub at {
    confess 'wrong number of arguments' if ( @_ != 2 );
    return $_[0]->{ $_[1] };
}

sub Tuple {
    my $self = shift;
    return Tuple->new(%$self);
}


package EnumMap;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'EnumMap::Role';

sub WHICH { $_[0]->Tuple }

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

