
use utf8;
use warnings FATAL => 'all';
use strict;
use Test::Most 'die';
use Womo::Relation::Test qw(new_test_depot test_database test_relation_class);
use Womo::Relation;

my $depot = new_test_depot('./t/db');
isa_ok( $depot, 'Womo::Depot::DBI' );
test_database( $depot->database );

test_relation_class('Womo::Relation::InMemory');

done_testing();


