
package New;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

sub new {
    my $class = shift;

    my $real_class = blessed($class) || $class;
    my $params = $real_class->BUILDARGS(@_);
    return bless $params, $real_class;
}

1;
__END__

