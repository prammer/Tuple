
# restriction
use utf8;
use warnings FATAL => 'all';
use strict;
use Test::Most tests => 7, 'die';
use Test::Moose;

use Womo::Test qw(new_test_depot);

my $depot = new_test_depot('./t/db');
isa_ok( $depot, 'Womo::Depot::DBI' );

use Set::Relation::V2;
sub relation { return Set::Relation::V2->new( @_ ); }

my $db = $depot->database;

# shorthands
my $s  = $db->{suppliers};
my $p  = $db->{parts};
my $sp = $db->{shipments};

# for testing, get the tuples in a known order
my @supplier_tuples =
    sort { $a->{sno} cmp $b->{sno} }
    @{ $s->members };

my $s1 = $s->restriction( sno => 'S1' );
my $s2 = $s->restriction( { sno => 'S1' } );
my $expect = relation( [ $supplier_tuples[0] ] );
ok( $s1->is_identical($expect), 'restriction' );
ok( $s2->is_identical($expect), 'restriction' );
cmp_ok( $s1->cardinality, '==', 1, 'cardinality' );
cmp_bag( $s1->members, $expect->members, 'same members' );

my $out1 = $s->join($sp)->restriction(sno => 'S4');
my $out2 = $s->restriction(sno => 'S4')->join($sp);

$expect = relation( [
        [ qw(sno sname status city   pno qty) ], [
        [ qw(S4  Clark 20     London P2  200) ],
        [ qw(S4  Clark 20     London P4  300) ],
        [ qw(S4  Clark 20     London P5  400) ],
    ],
] );

ok( $out1->is_identical($expect), 'join + restriction' );

# TODO: optimize this (somehow?) to not even query since they are the same logically?
ok( $out1->is_identical($out2),   'restriction + join' );

#my $out1 = $s->join($p, $sp)->



__END__


$db->{suppliers} = relation( [
        [ qw(sno sname status city  ) ], [
        [ qw(S1  Smith 20     London) ],
        [ qw(S2  Jones 10     Paris ) ],
        [ qw(S3  Blake 30     Paris ) ],
        [ qw(S4  Clark 20     London) ],
        [ qw(S5  Adams 30     Athens) ],
    ],
] );


$db->{parts} = relation( [
        [ qw(pno pname color weight city  ) ], [
        [ qw(P1  Nut   Red   12.0   London) ],
        [ qw(P2  Bolt  Green 17.0   Paris ) ],
        [ qw(P3  Screw Blue  17.0   Oslo  ) ],
        [ qw(P4  Screw Red   14.0   London) ],
        [ qw(P5  Cam   Blue  12.0   Paris ) ],
        [ qw(P6  Cog   Red   19.0   London) ],
    ],
] );

$db->{shipments} = relation( [
        [ qw(sno pno qty) ], [
        [ qw(S1  P1  300) ],
        [ qw(S1  P2  200) ],
        [ qw(S1  P3  400) ],
        [ qw(S1  P4  200) ],
        [ qw(S1  P5  100) ],
        [ qw(S1  P6  100) ],
        [ qw(S2  P1  300) ],
        [ qw(S2  P2  400) ],
        [ qw(S3  P2  200) ],
        [ qw(S4  P2  200) ],
        [ qw(S4  P4  300) ],
        [ qw(S4  P5  400) ],
    ],
] );


