
package Iterator::BulkWrap;

use Moose;
use warnings FATAL => 'all';
use Data::Stream::Bulk;
use namespace::autoclean;

with 'Iterator::ArrayBuffer';

has 'bulk' => (
    is       => 'ro',
    does     => 'Data::Stream::Bulk',
    required => 1,
    handles  => [qw(
        is_done
    )],
);

override BUILDARGS => sub {
    return +{ bulk => $_[1] } if ( @_ == 2 );
    return super();
};

sub _get_more {
    my $self = shift;

    my $bulk = $self->bulk;
    while (1) {
        return if $bulk->is_done;
        my $array = $bulk->next or next;
        return $array if @$array;
    }
}

__PACKAGE__->meta->make_immutable;
1;
__END__

