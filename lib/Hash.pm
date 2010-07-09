
package Hash;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with (
    'Moose::Autobox::Hash',
    'MooseX::Identity::Role',
);

sub new {
    my $class = shift;

    my $real_class = blessed($class) || $class;
    my $params = $real_class->BUILDARGS(@_);
    return bless $params, $real_class;
}

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

sub pairs {
    my $self = shift;
    require Pair;
    return ( map { Pair->new( $_ => $self->{$_} ) } keys %$self );
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

