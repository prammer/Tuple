
use Test::Most;
use Test::Moose;

{
    use Iterator::Code;
    my @a = qw(a b c);
    my $i = Iterator::Code->new( sub { shift @a } );
    isa_ok( $i, 'Iterator::Code' );
    common($i);
}

{
    use Iterator::Array;
    my @a = ( undef, 0, '', qw(a b c) );
    my $i = Iterator::Array->new(@a);
    isa_ok( $i, 'Iterator::Array' );
    ok( $i->has_next );
    ok( !defined $i->peek );
    ok( !defined $i->next );
    ok( $i->has_next );
    is( $i->peek, 0 );
    ok( $i->has_next );
    is( $i->next, 0 );
    ok( $i->has_next );
    is( $i->peek, '' );
    ok( $i->has_next );
    is( $i->next, '' );
    ok( $i->has_next );
    is( $i->peek, 'a' );
    common($i);
}

sub common {
    my $i = shift;
    does_ok( $i, 'Iterator' );
    ok( $i->has_next );
    is( $i->peek, 'a' );
    ok( $i->has_next );
    is( $i->next, 'a' );
    ok( $i->has_next );
    is( $i->peek, 'b' );
    ok( $i->has_next );
    is( $i->next, 'b' );
    ok( $i->has_next );
    is( $i->peek, 'c' );
    ok( $i->has_next );
    is( $i->next, 'c' );
    ok( !$i->has_next );
    ok( !defined $i->next );
    ok( !defined $i->peek );
    ok( !$i->has_next );
}

done_testing();
