
package Womo::Relation::Derived;
use Womo::Role;

with 'Womo::Relation::Role';

has '_parent' => (
    init_arg => 'parent',
    is       => 'ro',
    does     => 'Womo::Relation::Role',
    required => 1,
);

sub _build_sql {
    die;
}

1;
__END__

