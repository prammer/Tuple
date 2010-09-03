
# a fully reified Perl 5 array -- no iterators or lazyness -- mutable

package Array::Role;

use Moose::Role;
use warnings FATAL => 'all';
use Seq;
use namespace::autoclean;

sub Seq {
    my $self = shift;
    require Seq;
    return Seq->new(@$self);
}

with (
    'Seq::Role',
    'Moose::Autobox::Array' => { -excludes =>[qw(each grep map at exists first head join keys kv last reverse slice sort tail values)], },
);


package Array;
use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Array::Role';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__

