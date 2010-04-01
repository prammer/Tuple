
package Womo::Relation::Operator;
use Womo::Class;
require Womo::Relation;

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'relation' => (
    is       => 'ro',
    isa      => 'Womo::Relation',
    required => 1,
);

has 'args' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

1;
__END__

