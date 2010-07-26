
package Pair::Role;
use Moose::Role;
use warnings FATAL => 'all';
use Enum;
use namespace::autoclean;

with 'Enum::Role';

around 'value' => sub {
    my $code = shift;
    if ( @_ == 2 ) {
        return $_[0]->{ $_[0]->key } = $_[1];
    }
    return $code->(@_);
};

sub pairs {
    my $self = shift;
    return $self->Array->iterator;
}

package Pair;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Pair::Role';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

