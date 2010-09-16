
use utf8;
use warnings FATAL => 'all';
use strict;
use Test::Most tests => 1, 'die';
use Test::Moose;

use Womo::Test qw(new_test_depot);

#sub in {
#    my $attr  = shift;
#    my @items = @_;
#    return sub {
#        my $value = $_->{$attr};
#        return List::AllUtils::any { $value eq $_ } @items;
#    };
#}

#my $depot = Womo::Depot->new( database => ..., catalog => ...);
my $depot = new_test_depot('./t/db');
isa_ok( $depot, 'Womo::Depot::DBI' );

validate_sr_class( $depot->database );

# This is trying to use the running example data from
# "Database in Depth" by C. J. Date.

use Womo::Relation;
sub relation { return Womo::Relation::InMemory->new( @_ ); }

sub validate_sr_class {

####

my $db = shift;

# shorthands
my $s  = $db->{suppliers};
my $p  = $db->{parts};
my $sp = $db->{shipments};

# for testing, get the tuples in a known order
my @supplier_tuples =
    sort { $a->{sno} cmp $b->{sno} }
    $s->flat;

my @part_tuples =
    sort { $a->{pno} cmp $b->{pno} }
    $p->flat;

my @shipment_tuples =
    sort {
        $a->{sno} cmp $b->{sno} ||
        $a->{pno} cmp $b->{pno}
    }
    $sp->flat;

# test identity
{
    diag('is_identical');
#    does_ok( $s, 'Set::Relation' );
    ok( $s->is_identical($s), 'relation is === to itself' );
    ok( $s->is_identical( relation( [@supplier_tuples] ) ),
        'relation is === to relation with same members'
    );

#    does_ok( $p, 'Set::Relation' );
    ok( $p->is_identical($p), 'relation is === to itself' );
    ok( $p->is_identical( relation( [@part_tuples] ) ),
        'relation is === to relation with same members'
    );

#    does_ok( $sp, 'Set::Relation' );
    ok( $sp->is_identical($sp), 'relation is === to itself' );
    ok( $sp->is_identical( relation( [@shipment_tuples] ) ),
        'relation is === to relation with same members'
    );

    ok( !$p->is_identical($s),
        'relations of different class are not ===' );
    ok( !$s->is_identical($p),
        'relations of different class are not ===' );
    ok( !$sp->is_identical($s),
        'relations of different class are not ===' );
    ok( !$p->is_identical($sp),
        'relations of different class are not ===' );

    ok( !$s->is_identical(
            relation( [ $supplier_tuples[0] ] ) ),
        'relations of same class but different members are not ==='
    );
    ok( !$s->is_identical( relation( [] ) ),
        'relations of same class but different members are not ==='
    );
}

# test relational operators

# restriction
{
    diag('restriction');
    my $s1 = $s->restriction( sub { $_->{sno} eq 'S1' } );
    my $expect = relation( [ $supplier_tuples[0] ] );
    ok( $s1->is_identical($expect), 'restriction' );
    cmp_ok( $s1->cardinality, '==', 1, 'cardinality' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );
}

# projection
{
    diag('projection');
$DB::single =1;
    my $expect = relation(
        [ map { { city => $_ } } qw(London Paris Athens) ] );
    my $s1 = $s->projection('city');
    ok( $s1->is_identical($expect), 'projection' );
    cmp_ok( $s1->cardinality, '==', 3, 'cardinality' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );
}

# rename
{
    diag('rename');
    my $map = {
        a => 'sno',
        b => 'sname',
        c => 'status',
        d => 'city',
    };
    my $s1 = $s->rename($map);
    cmp_ok( $s->cardinality, '==', $s1->cardinality,
        'same cardinality on rename' );
    my $expect = relation( [
            [ qw(a   b     c      d     ) ], [
            [ qw(S1  Smith 20     London) ],
            [ qw(S2  Jones 10     Paris ) ],
            [ qw(S3  Blake 30     Paris ) ],
            [ qw(S4  Clark 20     London) ],
            [ qw(S5  Adams 30     Athens) ],
        ],
    ]);
    ok( $s1->is_identical($expect), 'expected renamed relation' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );
}

# union
{
    diag('union');
    ok( $s->is_identical( $s->union($s) ), 'self union yield self' );
    my $s1 = relation( [ @supplier_tuples[ 0, 1, 2 ] ] );
    my $s2 = relation( [ @supplier_tuples[ 1, 2, 3, 4 ] ] );
    my $s3 = $s1->union($s2);
    ok( $s->is_identical($s3), 'simple union' );
    cmp_bag( [$s->flat], [$s3->flat], 'same members' );
}

# insertion
{
    diag('insertion');
    my $inserted = {
        sno    => 'S6',
        sname  => 'Adams',
        status => 30,
        city   => 'Athens',
    };
    my $s1 = $s->insertion($inserted);
    my $expect = $s->union( relation( [$inserted] ) );
    ok( $s1->is_identical($expect), 'insertion/union' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );
}

# intersection
{
    diag('intersection');
    my $another = {
        sno    => 'S6',
        sname  => 'Sam',
        status => 30,
        city   => 'Paris',
    };
    my $s1 = $s->intersection(
        relation( [ @supplier_tuples[ 0, 4 ], $another ] ) );
    my $expect = relation( [ @supplier_tuples[ 0, 4 ] ] );
    ok( $s1->is_identical($expect), 'intersection' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );

    my $s2  = $s->projection('sno');
    my $sp1 = $sp->projection('sno');
    my $r   = $s2->intersection($sp1);
    $expect = relation( [ map { { 'sno' => $_ } } qw(S1 S2 S3 S4) ] );
    ok( $r->is_identical($expect), 'intersection' );
}

# join
{
    diag('join');
    my $j = $s->join($sp);
    cmp_ok(
        $j->cardinality,
        '==',
        scalar(@shipment_tuples),
        'cardinality of join'
    );
    my $expect = relation(
        [ [qw(sno sname status city pno qty)], [] ] );
    for my $sp (@shipment_tuples) {
        my $r = $s->restriction( sub { $_->{sno} eq $sp->{sno} } );
        ( $r->cardinality == 1 ) or die;
        my $sno = $r->eager->[0];
        $expect = $expect->insertion({
            sno    => $sp->{sno},
            sname  => $sno->{sname},
            status => $sno->{status},
            city   => $sno->{city},
            pno    => $sp->{pno},
            qty    => $sp->{qty},
        });
    }
    ok( $j->is_identical($expect), 'join' );
    cmp_bag( [$j->flat], [$expect->flat], 'same members' );
}

# group
{
    diag('group');
    my $sg = $s->group( 'the_rest', [qw(sno sname status)] );
    is( $sg->degree, 2, 'degree of group' );
    is_deeply( $sg->heading, [qw(city the_rest)], 'heading of group' );
    cmp_bag( $sg->attr('city'), [qw(London Paris Athens)],
        'values for nongrouped attribute' );

    my $london = $sg->restriction( sub { $_->{city} eq 'London' } )
        ->attr('the_rest')->[0];
    my $london_expect = relation( [
            [ qw(sno sname status) ], [
            [ qw(S1  Smith 20    ) ],
            [ qw(S4  Clark 20    ) ],
        ],
    ] );
    ok( $london->is_identical($london_expect), 'grouped attribute' );

    my $paris = $sg->restriction( sub { $_->{city} eq 'Paris' } )
        ->attr('the_rest')->[0];
    my $paris_expect = relation( [
            [ qw(sno sname status ) ], [
            [ qw(S2  Jones 10     ) ],
            [ qw(S3  Blake 30     ) ],
        ],
    ] );
    ok( $paris->is_identical($paris_expect), 'grouped attribute' );

    my $athens = $sg->restriction( sub { $_->{city} eq 'Athens' } )
        ->attr('the_rest')->[0];
    my $athens_expect = relation( [
            [ qw(sno sname status ) ], [
            [ qw(S5  Adams 30     ) ],
        ],
    ] );
    ok( $athens->is_identical($athens_expect), 'grouped attribute' );
}

####

}

