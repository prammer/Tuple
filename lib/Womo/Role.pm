
package Womo::Role;

use warnings FATAL => 'all';
use strict;
use utf8;
use namespace::autoclean;

sub import {
    my $class  = shift;
    my $caller = caller();


    eval qq{
        package $caller;
        use Moose::Role;
        use utf8;
    };
    die $@ if $@;

    warnings->import( FATAL => 'all' );
    strict->import;

    namespace::autoclean->import( -cleanee => $caller, );
}

1;
__END__

