
package Womo::Relation::Iterator;

use Womo::Role;
use Womo::Relation::Role;

with 'MooseX::Iterator::Role';

has 'relation' => (
    is       => 'ro',
    does     => 'Womo::Relation::Role',
    required => 1,
);

1;
__END__

