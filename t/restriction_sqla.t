
# restriction
use utf8;
use warnings FATAL => 'all';
use strict;
use Test::Most tests => 5, 'die';
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

# restriction
{
    diag('restriction');
    my $s1 = $s->restriction( sno => 'S1' );
    my $s2 = $s->restriction( { sno => 'S1' } );
    my $expect = relation( [ $supplier_tuples[0] ] );
    ok( $s1->is_identical($expect), 'restriction' );
    ok( $s2->is_identical($expect), 'restriction' );
    cmp_ok( $s1->cardinality, '==', 1, 'cardinality' );
    cmp_bag( $s1->members, $expect->members, 'same members' );
}


