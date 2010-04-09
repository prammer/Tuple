
package Womo::SQL;
use Womo::Class;

has 'text' => ( is => 'ro', isa => 'Str', required => 1 );

has 'bind' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    lazy     => 1,
    default  => sub { [] },
);

has 'next_label' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub combine_bind {
    my $self = shift;
    return [ @{ $self->bind }, map { @{ $_->bind } } @_ ];
}

1;
__END__

