
package Womo::Relation::Test;
use utf8;
use warnings FATAL => 'all';
use strict;
use DBIx::Connector;
use Sub::Exporter -setup => { exports => [qw(new_test_db new_test_depot)] };

#END { unlink $tmp }

sub _data_suppliers {(
    [qw(S1  Smith 20     London)],
    [qw(S2  Jones 10     Paris )],
    [qw(S3  Blake 30     Paris )],
    [qw(S4  Clark 20     London)],
    [qw(S5  Adams 30     Athens)],
)}

sub _data_parts {(
    [qw(P1  Nut   Red   12.0   London)],
    [qw(P2  Bolt  Green 17.0   Paris )],
    [qw(P3  Screw Blue  17.0   Oslo  )],
    [qw(P4  Screw Red   14.0   London)],
    [qw(P5  Cam   Blue  12.0   Paris )],
    [qw(P6  Cog   Red   19.0   London)],
)}

sub _data_shipments {(
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
)}

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
                for ( _data_suppliers() );

            $dbh->do(
                'insert into parts (pno, pname, color, weight, city) values (?,?,?,?,?)',
                undef,
                @$_
                )
                for ( _data_parts() );

            $dbh->do(
                'insert into shipments (sno, pno, qty) values (?,?,?)',
                undef, @$_ )
                for ( _data_shipments() );

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

1;
__END__

