
package Womo::Relation;
use Womo::Class;

with 'Womo::Relation::Role';

sub _is_identical_value {
    my ( $self, $other ) = @_;

    # TODO: compare ast and depot

    return if !$self->_has_same_heading($other);

    # it seems like there are many ways to do this
    # this is just a simple one to implement
    $self->Seq->is_identical( $other->Seq );
}

sub each   { die }
sub elems  { die }
sub enums  { die }
sub grep   { die }
sub map    { die }
sub pairs  { die }
sub tuples { die }

1;
__END__

