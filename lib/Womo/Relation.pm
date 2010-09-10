
package Womo::Relation;
use Womo::Class;

with 'Womo::Relation::Role';

sub _is_identical_value {
    my ( $self, $other ) = @_;

    # TODO: compare ast and depot

    # it seems like there are many ways to do this
    # this is just a simple one to implement
    $self->Seq->is_identical( $other->Seq );
}

1;
__END__

