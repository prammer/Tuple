
{
    package Foo::A;
    use Moose;
    use namespace::autoclean;
    with 'MooseX::WHICH';
    has 'x' => ( is => 'ro', isa => 'Int', );
    sub WHICH {
        my $self = shift;
        return $self->x;
    }
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::B;
    use Moose;
    use namespace::autoclean;
    extends 'Foo::A';
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::C;
    use Moose;
    use namespace::autoclean;
    with 'MooseX::WHICH';
    has 'x' => ( is => 'ro', isa => 'Int', );
    sub WHICH {
        my $self = shift;
        return $self->x;
    }
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::D;
    use Moose;
    use namespace::autoclean;
    # note: no MooseX::WHICH
    has 'x' => ( is => 'ro', isa => 'Int', );
    sub WHICH {
        my $self = shift;
        return $self->x;
    }
    __PACKAGE__->meta->make_immutable;
}

package main;

use warnings FATAL => 'all';
use strict;

use Test::More tests => 45;
use Test::Exception;
use MooseX::Identity 'is_identical';

# not sure about these
#ok( Foo::A->meta->is_identical( Foo::A->meta ),  'metas are ===' );
#ok( !Foo::A->meta->is_identical( Foo::B->meta ), 'metas are not ===' );
#ok( !Foo::A->meta->is_identical( Foo::C->meta ), 'metas are not ===' );

my $a = Foo::A->new( x => 4 );
my $b = Foo::B->new( x => 4 );
my $c = Foo::C->new( x => 4 );
my $d = Foo::D->new( x => 4 );

ok( $a->is_identical($a), 'same refaddr are ===' );
ok( $a->is_identical( Foo::A->new( x => 4 ) ),
    'different refaddr are ===' );
ok( !$a->is_identical( Foo::A->new( x => 5 ) ),
    'different WHICH same class are not ===' );
ok( $c->is_identical($c), 'same refaddr are ===' );
ok( $c->is_identical( Foo::C->new( x => 4 ) ),
    'different refaddr are ===' );
ok( !$c->is_identical( Foo::C->new( x => 5 ) ),
    'differet WHICH same class are not ===' );

ok( !$a->is_identical($b), 'same WHICH different class are not ===' );
ok( !$a->is_identical($c), 'same WHICH different class are not ===' );
ok( !$b->is_identical($a), 'same WHICH different class are not ===' );
ok( !$b->is_identical($c), 'same WHICH different class are not ===' );
ok( !$c->is_identical($a), 'same WHICH different class are not ===' );
ok( !$c->is_identical($b), 'same WHICH different class are not ===' );

ok( !$a->is_identical(4), 'not ===' );
ok( !$a->is_identical( [] ),  'not ===' );
ok( !$a->is_identical( [4] ), 'not ===' );
ok( !$a->is_identical( {} ), 'not ===' );
ok( !$a->is_identical( { x => 4 } ), 'not ===' );
ok( !$a->is_identical( \$a ), 'not ===' );

sub _pretty {
    return 'undef' if ( !defined $_[0] );
    return "''" if ( $_[0] eq '' );
    return "$_[0]";
}

sub _mesg {
    return join( ' ', _pretty( $_[0] ), $_[2], _pretty( $_[1] ) );
}

sub identical_ok {
    my ( $v1, $v2, $mesg ) = @_;
    ok( is_identical( $v1, $v2 ),
        $mesg || _mesg( $v1, $v2, '===' ) );
}

sub not_identical_ok {
    my ( $v1, $v2, $mesg ) = @_;
    ok( !is_identical( $v1, $v2 ),
        $mesg || _mesg( $v1, $v2, '!===' ) );
}

throws_ok { is_identical() } qr/wrong number of arguments/;
throws_ok { is_identical(1) } qr/wrong number of arguments/;
throws_ok { is_identical( 1, 1, 1 ) } qr/wrong number of arguments/;

identical_ok( undef, undef );
identical_ok( 0, 0 );
identical_ok( '', '' );
identical_ok( 0, '0.0' );
identical_ok( 0, 0.0 );
identical_ok( '0', '0.0' );
not_identical_ok( undef, '' );
not_identical_ok( '', undef );
not_identical_ok( '', 0 );
not_identical_ok( 0, '' );
not_identical_ok( undef, 0 );
not_identical_ok( 0, undef );
identical_ok( 42, 42 );
not_identical_ok( 42, 43 );
not_identical_ok( !!1, !1);
not_identical_ok( !!0, !0);
identical_ok( 'foo', 'foo' );
not_identical_ok( 'foo', 'bar' );
identical_ok( $a, $a );
not_identical_ok( $a, $b );
identical_ok( $b, $b );
identical_ok( $b, Foo::B->new( x => 4 ) );
identical_ok( $d, $d );
not_identical_ok( $d, Foo::D->new( x => 4 ) );

