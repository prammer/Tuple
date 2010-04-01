
package Womo::Relation::Restriction;
use Womo::Class;
use Womo::Relation::Iterator::CodeRef;

with 'Womo::Relation::Derived';

has '_parent' => (
    init_arg => 'parent',
    is       => 'ro',
    does     => 'Womo::Relation::Role',
    required => 1,
);

has '_expression' => (
    init_arg => 'expression',
    is => 'ro',
#TODO: DBIx::Class::SQLAHacks
#    isa => 'Str|CodeRef',
    required => 1,
);

around '_new_iterator' => sub {
    my $next = shift;
    my $self = shift;
    my $want    = $self->_expression;
    if ( ref $want && ref($want) eq 'CODE' ) {
        my $parent_it = $self->_parent->_new_iterator;
        return Womo::Relation::Iterator::CodeRef->new(
            relation => $self,
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
    die;
}

1;
__END__

