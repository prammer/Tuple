
package Iterator::Map;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

with 'Iterator::ArrayBuffer';

has 'iterator' => (
    is       => 'ro',
    does     => 'Iterator',
    required => 1,
);

has 'code' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub _get_more {
    my $self = shift;

    my $it   = $self->iterator;
    my $code = $self->code;
    while (1) {
        return if !$it->has_next;
        local $_ = $it->next;
        my @array = $code->($_);
        return \@array if @array;
    }
}

__PACKAGE__->meta->make_immutable;
1;
__END__

