
package Womo::Class;

use warnings FATAL => 'all';
use strict;

#use Moose::Exporter;

#my ( $import, $unimport, $init_meta )
#    = Moose::Exporter->build_import_methods();


sub import {
    my $class  = shift;
    my $caller = caller();

    eval qq{
        package $caller;
        use Moose;
        use MooseX::StrictConstructor;
        use utf8;
    };
    die $@ if $@;

#    $class->$import();

    warnings->import( FATAL => 'all' );
    namespace::autoclean->import( -cleanee => $caller, );

    # TODO: make_immutable
}

#sub unimport { goto &$unimport }

#sub init_meta {
#    my $class = shift;
#    return $class->$init_meta();
#}

1;
__END__

