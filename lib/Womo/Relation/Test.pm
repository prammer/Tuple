
package Womo::Relation::Test;
use utf8;
use warnings FATAL => 'all';
use strict;
use DBIx::Connector;
use Test::Most 'die';
use Test::Moose;
use Womo::Relation;
use List::AllUtils qw(zip);
use Tuple;
use Const::Fast qw(const);
use Sub::Exporter -setup => { exports => [qw(new_test_db new_test_depot test_database)] };


#END { unlink $tmp }

const my @suppliers_array => (
    [qw(S1  Smith 20     London)],
    [qw(S2  Jones 10     Paris )],
    [qw(S3  Blake 30     Paris )],
    [qw(S4  Clark 20     London)],
    [qw(S5  Adams 30     Athens)],
);

const my @parts_array => (
    [qw(P1  Nut   Red   12.0   London)],
    [qw(P2  Bolt  Green 17.0   Paris )],
    [qw(P3  Screw Blue  17.0   Oslo  )],
    [qw(P4  Screw Red   14.0   London)],
    [qw(P5  Cam   Blue  12.0   Paris )],
    [qw(P6  Cog   Red   19.0   London)],
);

const my @shipments_array => (
    [qw(S1  P1  300)],
    [qw(S1  P2  200)],
    [qw(S1  P3  400)],
    [qw(S1  P4  200)],
    [qw(S1  P5  100)],
    [qw(S1  P6  100)],
    [qw(S2  P1  300)],
    [qw(S2  P2  400)],
    [qw(S3  P2  200)],
    [qw(S4  P2  200)],
    [qw(S4  P4  300)],
    [qw(S4  P5  400)],
);

my $to_hashrefs = sub {
    my $heading = shift or die;
    my @data    = @_    or die;
    return map { { zip( @$heading, @$_ ) } } @data;
};

const my @suppliers_hrefs => $to_hashrefs->( [qw(sno sname status city)],       @suppliers_array );
const my @parts_hrefs     => $to_hashrefs->( [qw(pno pname color weight city)], @parts_array );
const my @shipments_hrefs => $to_hashrefs->( [qw(sno pno qty)],                 @shipments_array );

my $to_tuples = sub { map { Tuple->new($_) } @_ };

const my @suppliers_tuples => $to_tuples->(@suppliers_hrefs);
const my @parts_tuples     => $to_tuples->(@parts_hrefs);
const my @shipments        => $to_tuples->(@shipments_hrefs);

sub new_test_db {
    my $tmp = shift or die 'must pass a file';
    unlink $tmp;

    my $dsn = 'dbi:SQLite:dbname=' . $tmp;

    my $db_conn = DBIx::Connector->new( $dsn, '', '' );

    # This is trying to use the running example data from
    # "Database in Depth" by C. J. Date.

    my $sql = q{

        create table suppliers (
            sno     text     primary key not null,
            sname   text     not null,
            status  integer  not null,
            city    text     not null
        );

        create table parts (
            pno     text     primary key not null,
            pname   text     not null,
            color   text     not null,
            weight  real     not null,
            city    text     not null
        );

        create table shipments (
            sno     text     not null,
            pno     text     not null,
            qty     integer  not null,
            foreign key(sno) references suppliers(sno)
        );

    };

    $db_conn->run(
        sub {
            my $dbh = $_;

            $dbh->do($_) for ( split( /;/, $sql ) );

            $dbh->do(
                'insert into suppliers (sno, sname, status, city) values (?,?,?,?)',
                undef,
                @$_
                )
                for ( @suppliers_array );

            $dbh->do(
                'insert into parts (pno, pname, color, weight, city) values (?,?,?,?,?)',
                undef,
                @$_
                )
                for ( @parts_array );

            $dbh->do(
                'insert into shipments (sno, pno, qty) values (?,?,?)',
                undef, @$_ )
                for ( @shipments_array );

        }
    );

    return $db_conn;
}

sub new_test_depot {
    my $db_conn = new_test_db(@_);

    use Womo::Depot::DBI;
    my $depot
        = Womo::Depot::DBI->new( db_conn => $db_conn, db_dsn => 'foo' );    # fix db_dsn required
    return $depot;
}

#sub in {
#    my $attr  = shift;
#    my @items = @_;
#    return sub {
#        my $value = $_->{$attr};
#        return List::AllUtils::any { $value eq $_ } @items;
#    };
#}

sub test_database {
    my $db = shift;
    my $in_memory_class = shift || 'Womo::Relation::InMemory';

    my $relation = sub { $in_memory_class->new(@_); };

    # shorthands
    my $s  = $db->{suppliers} or die;
    my $p  = $db->{parts} or die;
    my $sp = $db->{shipments} or die;

    test_identity( $s, $p, $sp, $relation );
    test_restriction( $s, $p, $sp, $relation );
    test_projection( $s, $p, $sp, $relation );
    test_rename( $s, $p, $sp, $relation );
    test_union( $s, $p, $sp, $relation );
    test_sqla_syntax( $s, $p, $sp, $relation );
    test_group( $s, $p, $sp, $relation );
    test_intersection( $s, $p, $sp, $relation );
    test_insertion( $s, $p, $sp, $relation );
    test_join( $s, $p, $sp, $relation );
}

sub test_identity {
    my ($s, $p, $sp, $relation) = @_;
    diag('is_identical');
#    does_ok( $s, 'Set::Relation' );
    ok( $s->is_identical($s), 'relation is === to itself' );
    ok( $s->is_identical( $relation->( [@suppliers_hrefs] ) ),
        'relation is === to relation with same members'
    );

#    does_ok( $p, 'Set::Relation' );
    ok( $p->is_identical($p), 'relation is === to itself' );
    ok( $p->is_identical( $relation->( [@parts_hrefs] ) ),
        'relation is === to relation with same members'
    );

#    does_ok( $sp, 'Set::Relation' );
    ok( $sp->is_identical($sp), 'relation is === to itself' );
    ok( $sp->is_identical( $relation->( [@shipments_hrefs] ) ),
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
            $relation->( [ $suppliers_hrefs[0] ] ) ),
        'relations of same class but different members are not ==='
    );
    ok( !$s->is_identical( $relation->( [] ) ),
        'relations of same class but different members are not ==='
    );
}


sub test_restriction {
    my ($s, $p, $sp, $relation) = @_;
    diag('restriction');
    my $s1 = $s->restriction( sub { $_->{sno} eq 'S1' } );
    my $expect = $relation->( [ $suppliers_hrefs[0] ] );
    ok( $s1->is_identical($expect), 'restriction' );
    cmp_ok( $s1->cardinality, '==', 1, 'cardinality' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );
}

sub test_projection {
    my ($s, $p, $sp, $relation) = @_;
    diag('projection');
    my $expect = $relation->(
        [ map { { city => $_ } } qw(London Paris Athens) ] );
    my $s1 = $s->projection('city');
    ok( $s1->is_identical($expect), 'projection' );
    cmp_ok( $s1->cardinality, '==', 3, 'cardinality' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );
}

sub test_rename {
    my ($s, $p, $sp, $relation) = @_;
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
    my $expect = $relation->( [
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

sub test_union {
    my ($s, $p, $sp, $relation) = @_;
    diag('union');
    ok( $s->is_identical( $s->union($s) ), 'self union yield self' );
#    my $s1 = relation( [ @suppliers_hrefs[ 0, 1, 2 ] ] );
    my $s1 = $s->restriction(sno => [qw(S1 S2 S3)]);
#    my $s2 = relation( [ @suppliers_hrefs[ 1, 2, 3, 4 ] ] );
    my $s2 = $s->restriction(sno => [qw(S2 S3 S4 S5)]);
    my $s3 = $s1->union($s2);
    ok( $s->is_identical($s3), 'simple union' );
    cmp_bag( [$s->flat], [$s3->flat], 'same members' );
}

sub test_insertion {
    my ($s, $p, $sp, $relation) = @_;
    diag('insertion');
    my $inserted = {
        sno    => 'S6',
        sname  => 'Adams',
        status => 30,
        city   => 'Athens',
    };
    my $s1 = $s->insertion($inserted);
    my $expect = $s->union( $relation->( [$inserted] ) );
    ok( $s1->is_identical($expect), 'insertion/union' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );
}

sub test_intersection {
    my ($s, $p, $sp, $relation) = @_;
    diag('intersection');
    my $another = {
        sno    => 'S6',
        sname  => 'Sam',
        status => 30,
        city   => 'Paris',
    };
    my $s1 = $s->intersection(
        $relation->( [ @suppliers_hrefs[ 0, 4 ], $another ] ) );
    my $expect = $relation->( [ @suppliers_hrefs[ 0, 4 ] ] );
    ok( $s1->is_identical($expect), 'intersection' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );

    my $s2  = $s->projection('sno');
    my $sp1 = $sp->projection('sno');
    my $r   = $s2->intersection($sp1);
    $expect = $relation->( [ map { { 'sno' => $_ } } qw(S1 S2 S3 S4) ] );
    ok( $r->is_identical($expect), 'intersection' );
}

sub test_join {
    my ($s, $p, $sp, $relation) = @_;
    diag('join');
    my $j = $s->join($sp);
    cmp_ok(
        $j->cardinality,
        '==',
        scalar(@shipments_hrefs),
        'cardinality of join'
    );
    my $expect = $relation->(
        [ [qw(sno sname status city pno qty)], [] ] );
    for my $sp (@shipments_hrefs) {
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

sub test_group {
    my ($s, $p, $sp, $relation) = @_;
    diag('group');
    my $sg = $s->group( 'the_rest', [qw(sno sname status)] );
    is( $sg->degree, 2, 'degree of group' );
    is_deeply( $sg->heading, [qw(city the_rest)], 'heading of group' );
    cmp_bag( $sg->attr('city'), [qw(London Paris Athens)],
        'values for nongrouped attribute' );

    my $london = $sg->restriction( sub { $_->{city} eq 'London' } )
        ->attr('the_rest')->[0];
    my $london_expect = $relation->( [
            [ qw(sno sname status) ], [
            [ qw(S1  Smith 20    ) ],
            [ qw(S4  Clark 20    ) ],
        ],
    ] );
    ok( $london->is_identical($london_expect), 'grouped attribute' );

    my $paris = $sg->restriction( sub { $_->{city} eq 'Paris' } )
        ->attr('the_rest')->[0];
    my $paris_expect = $relation->( [
            [ qw(sno sname status ) ], [
            [ qw(S2  Jones 10     ) ],
            [ qw(S3  Blake 30     ) ],
        ],
    ] );
    ok( $paris->is_identical($paris_expect), 'grouped attribute' );

    my $athens = $sg->restriction( sub { $_->{city} eq 'Athens' } )
        ->attr('the_rest')->[0];
    my $athens_expect = $relation->( [
            [ qw(sno sname status ) ], [
            [ qw(S5  Adams 30     ) ],
        ],
    ] );
    ok( $athens->is_identical($athens_expect), 'grouped attribute' );
}

sub test_sqla_syntax {
    my ($s, $p, $sp, $relation) = @_;
    diag('sqla syntax');
    my $s1 = $s->restriction( sno => 'S1' );
    my $s2 = $s->restriction( { sno => 'S1' } );
    my $s3 = $s->restriction( sub { $_->{sno} eq 'S1' } );
    my $expect = $relation->( [ $suppliers_hrefs[0] ] );
    ok( $s1->is_identical($expect), 'restriction' );
    ok( $s2->is_identical($expect), 'restriction' );
    ok( $s3->is_identical($expect), 'restriction' );
    cmp_ok( $s1->cardinality, '==', 1, 'cardinality' );
    cmp_bag( [$s1->flat], [$expect->flat], 'same members' );

    my $out1 = $s->join($sp)->restriction( sno => 'S4' );
    my $out2 = $s->restriction( sno => 'S4' )->join($sp);

    $expect = $relation->( [
            [ qw(sno sname status city   pno qty) ], [
            [ qw(S4  Clark 20     London P2  200) ],
            [ qw(S4  Clark 20     London P4  300) ],
            [ qw(S4  Clark 20     London P5  400) ],
        ],
    ] );

    ok( $out1->is_identical($expect), 'join + restriction' );

    # TODO: optimize this (somehow?) to not even query since they are the same logically?
    ok( $out1->is_identical($out2), 'restriction + join' );

    $out2 = $s->restriction( sno => 'S4', sname => 'Clark', )->join($sp);
    ok( $out1->is_identical($out2), 'restriction + join' );
    #$s->join($p, $sp)->members;

    my $out3
        = $s->rename( s_city => 'city', )
        ->join( $p->rename( p_city => 'city' ), $sp, )
        ->restriction( s_city => 'Paris', p_city => 'London', )
        ->projection(qw(sname color qty));
    cmp_ok( $out3->cardinality, '==', 1, 'cardinality' );
    my $t = $out3->eager->[0] or die;
    cmp_ok( $t->{sname}, 'eq', 'Jones', 'sname is Jones' );
    cmp_ok( $t->{color}, 'eq', 'Red',   'color is Red' );
    cmp_ok( $t->{qty},   '==', 300,     'qty is 300' );

    # projection on an iterator (not sth) based restriction
    my $s4 = $s3->projection(qw(sname status));
    $expect = $relation->(
        [ { map { $_ => $suppliers_hrefs[0]->{$_} } qw(sname status) } ] );
    ok( $s4->is_identical($expect), 'restriction' );
}

1;
__END__

