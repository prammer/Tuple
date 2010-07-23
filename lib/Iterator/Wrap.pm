
package Iterator::Wrap;

use Moose;
use warnings FATAL => 'all';
use namespace::autoclean;

has 'iterator' => (
    is       => 'ro',
    does     => 'Iterator',
    required => 1,
    handles  => [qw(has_next)],
);

has 'code' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

with 'Iterator';

sub next {
    my $self = shift;

    return if !$self->has_next;

    local $_ = $self->iterator->next;
    my @values = $self->code->($_);
    
    if ($self->_has_buf) {
        my $item = $self->_buf;
        $self->_clear_buf;
        return $item;
    }
    my $item = $self->_code->();
    return $item;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

