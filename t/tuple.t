
use warnings FATAL => 'all';
use strict;

use Test::Most;
use Tuple::Tests;
Tuple::Tests::test_isa('Tuple');
Tuple::Tests::test_does('Tuple');
done_testing();

