
package Womo::ASTNode;
use Womo::Class;
use Moose::Util::TypeConstraints;

coerce 'Womo::ASTNode'
    => from 'HashRef'
    => via { Womo::ASTNode->new($_) };

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
);

has 'op' => (
    is       => 'ro',
    isa      => 'Str',
#    required => 1,     # tables do not have this
);

has 'args' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    default => sub { [] },
);

has 'heading' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

1;
__END__

