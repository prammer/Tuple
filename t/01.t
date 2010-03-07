
use Test::Most tests => 1, 'die';
use Test::TempDir;

my $tmp = temp_root();
my $dsn = 'dbi:SQLite:dbname=' . $tmp->file('db');


#my $depot = Womo::Depot->new( database => ..., catalog => ...);
use Womo::Depot::DBI;
my $depot = Womo::Depot::DBI->new(
    db_dsn      => $dsn,
    db_user     => '',
    db_password => '',
);

$depot->db_conn->run(sub { $_->do(q{
    create table foo (
        a text,
        b text,
        c text
    );
})});

ok( -f $tmp->file('db'));


