
package MooseX::WHICH;

use Moose::Role;
use MooseX::Identity 'is_identical';
use namespace::autoclean;

with 'MooseX::Identity::Role';

requires 'WHICH';

sub _is_identical_value {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $other ) = @_;
    confess '_is_identical_value is not a class method' if !ref($self);

    # NOTE:
    # Cannot call is_identical directly on the return
    # value from WHICH (even with autobox) because it might be
    # a string that happens to be a class name that happens to have
    # an is_identical method.  We cannot call is_identical
    # as a class method (see confess above :).
    #return $self->WHICH->is_identical( $other->WHICH );

    my $w1 = $self->WHICH;
    my $w2 = $other->WHICH;
    return is_identical( $w1, $w2 );
};

1;
__END__


=head1 NAME

MooseX::WHICH - Value Types


=head1 SYNOPSIS

  package MyClass;
  use Moose;
  with 'MooseX::WHICH';
  sub WHICH { ... }


=head1 DESCRIPTION

This is a L<Moose::Role> that requires your class to implement
a C<WHICH> method.  Your C<WHICH> method should return a value
that can be used to disginguish the invokent from other objects/values
in the exact same class.

This role composes the L<MooseX::Identity::Role> role.  Thus, your class will
get an C<is_identical> method that will use the value you return
from C<WHICH> to decide whether two values are identical.

This is meant to resemble descriptions in the Perl 6 Specification
of C<WHICH> and C<===>.

C<WHICH> will be called in scalar context.


