
package Womo::Depot::DBI;

use Moose;
use namespace::autoclean;
with qw(MooseX::Role::DBIx::Connector Womo::Depot::Interface);

sub catalog  {die}
sub database {die}

__PACKAGE__->meta->make_immutable;
1;
__END__

