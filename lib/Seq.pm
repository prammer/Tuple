
# a fully reified Perl 5 array -- no iterators or lazyness -- immutable

package Seq::Role;

use Moose::Role;
use warnings FATAL => 'all';
use namespace::autoclean;

# delegate to Iterator
for my $method (qw(map grep each enums pairs tuples)) {
    __PACKAGE__->meta->add_method(
        $method => sub {
            my $self = shift;
            return $self->iterator->$method(@_);
        }
    );
}

with (
    'Any',
    'BlessedArray',
);

sub iterator {
    my $self = shift;
    require Iterator::Array;
    return Iterator::Array->new(@$self);
}

sub Array {
    my $self = shift;
    require Array;
    return Array->new(@$self);
}

sub eager { $_[0] }
sub elems { scalar( @{ $_[0] } ) }
sub flat  { @{ $_[0] } }
sub kv {
    $_[0]->map( sub { $_->key, $_->value } );
}
sub slice { $_[0]->new( @{ $_[0] }[ @{ $_[1] } ] ) }
sub head  { $_[0]->[0] }
sub tail  { $_[0]->new( @{ $_[0] }[ 1 .. $#{ $_[0] } ] ) }
sub first { $_[0]->[0]; }
sub last  { $_[0]->[ $#{ $_[0] } ]; }

sub join {
    my ( $self, $sep ) = @_;
    $sep ||= '';
    CORE::join $sep, @$self;
}

sub reverse {
    my ($self) = @_;
    $self->new( CORE::reverse @$self );
}

sub sort {
    my ( $self, $sub ) = @_;
    $sub ||= sub { $a cmp $b };
    $self->new( CORE::sort { $sub->( $a, $b ) } @$self );
}

sub at {
    my ( $self, $index ) = @_;
    $self->[$index];
}

sub exists {
    my ( $self, $index ) = @_;
    CORE::exists $self->[$index];
}

sub keys {
    my ($self) = @_;
    $self->new( 0 .. $#{$self} );
}

sub values {
    my ($self) = @_;
    $self->new(@$self);
}


package Seq;
use Moose;
use warnings FATAL => 'all';
use MooseX::Identity qw(is_identical);
use namespace::autoclean;

with 'Seq::Role';

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

