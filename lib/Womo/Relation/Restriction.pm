
package Womo::Relation::Restriction;
use Womo::Class;
use Womo::Relation::Iterator::CodeRef;
use SQL::Abstract;

with 'Womo::Relation::Derived';

has '_expression' => (
    init_arg => 'expression',
    is => 'ro',
#TODO: DBIx::Class::SQLAHacks
    isa => 'HashRef|CodeRef',
    required => 1,
);

around '_new_iterator' => sub {
    my $next = shift;
    my $self = shift;
    my $want = $self->_expression;
    if ( ref $want && ref($want) eq 'CODE' ) {
        my $parent_it = $self->_parent->_new_iterator;
        return Womo::Relation::Iterator::CodeRef->new(
#            relation => $self,
            code     => sub {
                while (1) {
                    my $next = $parent_it->next or return;
                    local $_ = $next;
                    return $next if $want->($next);
                }
            }
        );
    }
    return $self->$next(@_);
};

sub _build_sql {
    my $self = shift;

    my $sql = SQL::Abstract->new;
    my ( $stmt, @bind ) = $sql->where( $self->_expression );
    my ( $pstmt, @pbind ) = $self->_parent->_build_sql;

    $stmt
        = "select distinct * from (\n" . $pstmt . "\n)\n$stmt";

    return ( $stmt, @pbind, @bind );
}

1;
__END__

