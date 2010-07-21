
package Seq::Role;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

with (
#    'Moose::Autobox::Array',
    'Any',
    'New',
);

sub BUILDARGS {
    my $class = shift;
    return [@_];
}

sub iterator {
    my $self = shift;
    require Tuple;
    require Iterator::Code;
    my $a = [@$self];
    my $i = -1;
    return Iterator::Code->new(sub {
        return if (@$a == 0);
        $i++;
        return Tuple->new( key => $i, value => shift @$a, );
    });
}

sub pairs {
    my $self = shift;
    require Pair;
    my $i = 0;
    return [ map { Pair->new( $i => $self->[ $i++ ] ) } @$self ];
}

sub elems { $_[0]->length }

# stolen from Moose::Autobox::Array, is it what we want?
sub map {
    my ( $self, $sub ) = @_;
    [ CORE::map { $sub->($_) } @$self ];
}

#TODO
sub each {
    my ($self, $sub) = @_;
}

package Seq;
use Moose;
use warnings FATAL => 'all';
use MooseX::Identity qw(is_identical);
use namespace::autoclean;

with 'Seq::Role';

sub push    { confess 'cannot modify' }
sub pop     { confess 'cannot modify' }
sub shift   { confess 'cannot modify' }
sub unshift { confess 'cannot modify' }
sub delete  { confess 'cannot modify' }
sub put     { confess 'cannot modify' }

sub _is_identical_value {
    confess 'wrong number of arguments' if ( @_ != 2 );
    my ( $s1, $s2 ) = @_;

    return 0 if ( $#$s1 != $#$s2 );
    for ( my $i = 0; $i <= $#$s1; $i++ ) {
        return 0 if !is_identical( $s1->[$i], $s2->[$i] );
    }
    return 1;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__
