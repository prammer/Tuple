
use warnings FATAL => 'all';
use strict;

use Test::Most;
use Test::Moose;

my %make_new = (
    'Iterator::Code' => sub {
        my $a = shift;
        return Iterator::Code->new( sub { shift @$a } );
    },
    'Iterator::Array' => sub {
        my $a = shift;
        return Iterator::Array->new(@$a);
    },
);

{
    use Iterator::Code;
    common('Iterator::Code');

    my @a = qw(a b c);
    my $i = Iterator::Code->new( sub { shift @a } );
    isa_ok( $i, 'Iterator::Code' );
    my $i2 = Iterator::Code->new( sub { shift @a } );
    ok( !$i->is_identical($i2) );
}

{
    use Iterator::Array;
    common('Iterator::Array');

    my @a = ( undef, 0, '', 'a');
    my $i = Iterator::Array->new(@a);
    isa_ok( $i, 'Iterator::Array' );
    my $i2 = Iterator::Array->new(@a);
    ok( !$i->is_identical($i2) );
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
}

sub common {
    my $class = shift or die;
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        ok( $i->is_identical($i) );
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

    # map
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my $mapped = $i->map( sub { $_ . $_ } )->eager;
        is_deeply( $mapped, [qw(aa bb cc)] );
    }

    # grep
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my $filtered = $i->grep( sub { $_ eq 'c' } )->eager;
        is_deeply( $filtered, ['c'] );
    }

    # flatten
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my @a = $i->flatten;
        is_deeply( \@a, [qw(a b c)] );
    }
}

done_testing();
