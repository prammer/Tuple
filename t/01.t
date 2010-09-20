
use utf8;
use warnings FATAL => 'all';
use strict;
use Test::Most 'die';
use Womo::Relation::Test qw(new_test_depot test_database);
use Womo::Relation;

my $depot = new_test_depot('./t/db');
isa_ok( $depot, 'Womo::Depot::DBI' );

test_database( $depot->database );

done_testing();


