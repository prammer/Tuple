
package MooseX::Identity;

use warnings FATAL => 'all';
use strict;

use Scalar::Util qw(looks_like_number blessed refaddr);
use Moose::Util qw(does_role);
use Carp qw(confess);
use namespace::clean;

use Sub::Exporter -setup => {
    exports => [qw(
        is_identical
    )],
#    groups => { default => [':all'] },
};

sub is_identical {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $v1, $v2 ) = @_;

    # this could be optimized and cleaned up
    if ( ref($v1) ) {
        return if ( !ref($v2) );    # one is a ref, one is not
        if ( my $b1 = blessed($v1) ) {
            if ( my $b2 = blessed($v2) ) {

                # just use ->can('is_identical') here?
                if (does_role(
                        $v1, 'MooseX::Identity::Role')) {
                    return $v1->is_identical($v2);
                }
                elsif (does_role(
                        $v2, 'MooseX::Identity::Role')) {

                    # just return here because they are different classes?
                    return $v2->is_identical($v1);
                }
                else {
                    return ( refaddr($v1) == refaddr($v2) );
                    #return if ($b1 ne $b2);
                }
            }
            else {
                return;    # one is blessed, one is not
            }
        }
        elsif ( my $b2 = blessed($v2) ) {
            return;    # one is blessed, one is not
        }
        else {
            # both refs, neither blessed
            return ( refaddr($v1) == refaddr($v2) );
        }
    }
    elsif ( ref($v2) ) {
        return;            # one is a ref, one is not
    }
    else {

        return   if ( defined($v1)  && !defined($v2) );
        return   if ( !defined($v1) && defined($v2) );
        return 1 if ( !defined($v1) && !defined($v2) );

        # both are not refs
        if ( looks_like_number($v1) && looks_like_number($v2) ) {
            return ( $v1 == $v2 );
        }
        return ( $v1 eq $v2 );
    }
}

1;
__END__



=head1 NAME

MooseX::Identity - Test identity of two objects/values


=head1 SYNOPSIS

  use MooseX::Identity 'is_identical';

  is_identical($v1, $v2);


=head1 DESCRIPTION

In Perl 6 you will be able to test whether any two objects
are the same value by using C<===>.

The C<is_identical> function is to have the same meaning as C<===>.

=head1 EXPORTS

=over 4

=item B<is_identical ($v1, $v2)>

Returns true if the two argument represent the same value.
This is not exported unless you specifically request it.

=back


