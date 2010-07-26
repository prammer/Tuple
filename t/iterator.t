
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
    # map - can return empty array or multiple items
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my $mapped
            = $i->map( sub { ( $_ eq 'b' ) ? ( $_, 1, 2, 3, 4 ) : () } )
            ->eager;
        is_deeply( $mapped, [qw(b 1 2 3 4)],
            'map can return empty array and/or multiple items' );
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

    # each
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my $x = 0;
        $i->each( sub { $x++ } );
        is( $x, 3 );
    }

    # enums
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my $e = $i->enums->eager;
        is_deeply(
            $e,
            [
                Enum->new( 0, 'a' ),
                Enum->new( 1, 'b' ),
                Enum->new( 2, 'c' ),
            ],
        );
    }

    # pairs
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my $p = $i->pairs->eager;
        is_deeply(
            $p,
            [
                Pair->new( 0, 'a' ),
                Pair->new( 1, 'b' ),
                Pair->new( 2, 'c' ),
            ],
        );
    }

    # tuples
    {
        my $i = $make_new{$class}->( [qw(a b c)] ) or die;
        my $t = $i->tuples->eager;
        is_deeply(
            $t,
            [
                Tuple->new( key => 0, value => 'a' ),
                Tuple->new( key => 1, value => 'b' ),
                Tuple->new( key => 2, value => 'c' ),
            ],
        );
    }

}

done_testing();
