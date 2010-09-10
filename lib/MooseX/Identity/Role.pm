
package MooseX::Identity::Role;

use Scalar::Util 'refaddr';
use Moose::Role;
use namespace::autoclean;

requires '_is_identical_value';

sub is_identical {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $other ) = @_;
    confess 'is_identical is not a class method' if !ref($self);

    # should this be here as a shortcut? can it be wrong?
    return 1 if ( ref($other) && ( refaddr($self) == refaddr($other) ) );

    return if !$self->_is_identical_class($other);
    return $self->_is_identical_value($other);
}

# this would be good as a default for things that
# do not implement WHICH
#sub _is_identical_value {
#    confess 'wrong number of arguments' if ( @_ != 2 );
#    my ( $self, $other ) = @_;
#    confess 'is_identical is not a class method' if !ref($self);
#    return 1 if ( ref($other) && ( refaddr($self) == refaddr($other) ) );
#    return 0;
#}

sub _is_identical_class {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $self, $other ) = @_;
    confess '_is_identical_class is not a class method' if !ref($self);

#    return if !ref($other);
#    return if !blessed($other);
#    return if !find_meta($other);
    return ( blessed($self) eq ( blessed($other) || '' ) );

#    my $other_meta = Moose::Util::find_meta($other) or return;
#    my $self_meta = $self->meta;
    #return ( $self_meta->name eq $other_meta->name );

    # below here may all just be overkill
    # but it's attractive from a "dog fooding" perspective

    # in some sense, ideally we'd just ask the classes if they are ===
    # like this:
    #return $self->meta->is_identical( $other->meta );
    # but we try to handle heterogeneous cases:
    #       $self->meta does not do MooseX::Identity::Interface
    #       $other cannot ->meta
    #       $other->meta does not do MooseX::Identity::Interface

#    return $self_meta->is_identical($other_meta)
#        if $self_meta->meta->can('does_role')
#            && $self_meta->meta->does_role('MooseX::Identity::Interface');
#        if $self_meta->$does_id;
#        if Moose::Util::does_role( $self_meta->name,
#            'MooseX::Identity::Interface' );

    # just return here because they are different classes?
#    return $other_meta->is_identical($self_meta)
#        if $other_meta->meta->can('does_role')
#            && $other_meta->meta->does_role('MooseX::Identity::Interface');
#        if $other_meta->$does_id;
#        if Moose::Util::does_role( $other_meta->name,
#            'MooseX::Identity::Interface' );

    # neither metaclasses do ===
#    return ( $self_meta->name eq $other_meta->name );
}

1;
__END__


=head1 NAME

MooseX::Identity::Role - Test identity of two objects/values


=head1 SYNOPSIS

  package MyClass;
  use Moose;
  with 'MooseX::Identity::Role';
  sub _is_identical_value { ... }


=head1 DESCRIPTION

In Perl 6 you will be able to test whether any two objects
are the same value by using C<===>.

The C<is_identical> method is to have the same meaning as C<===>.
This role provides an C<is_identical> method that is intended to
be usable for the majority of cases.

Your class will be required to implement a C<_is_identical_value>
method.

See also L<MooseX::WHICH> for a role that provides this.

Also see docs for L<MooseX::Identity>.

=head1 METHODS

=over 4

=item B<is_identical ($other)>

Returns true if this object is the same value as C<$other>.

=back


