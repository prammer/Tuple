
use warnings FATAL => 'all';
use strict;

use Test::Most;
use Tuple::Tests;
Tuple::Tests::test_does('Tuple');
Tuple::Tests::test_no_key_fail('Tuple');
done_testing();

