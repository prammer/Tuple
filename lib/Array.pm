
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

sub iterator {
    my $self = shift;
    require Iterator::Array;
    return Iterator::Array->new(@$self);
}

sub eager { $_[0] }

sub elems { scalar( @{ $_[0] } ) }

# delegate to Iterator
for my $method (qw(map grep each enums pairs tuples)) {
    __PACKAGE__->meta->add_method(
        $method => sub {
            my $self = shift;
            return $self->iterator->$method(@_);
        }
    );
}

package Array;
use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Array::Role';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

