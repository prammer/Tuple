
package Womo::Relation;
use Womo::Class;
use Womo::Depot::Interface;
use Set::Relation;
use Womo::Relation::Iterator;

#with 'Set::Relation';

has '_depot' => (
    init_arg => 'depot',
    is       => 'ro',
    does     => 'Womo::Depot::Interface',
);

has '_table_name' => (
    init_arg => 'table_name',
    is       => 'ro',
    isa      => 'Str',
);

has '_expr' => (
    is  => 'ro',
    isa => 'ArrayRef',
);

has '_heading' => (
    init_arg => 'heading',
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

# TODO: make sure we have depot+table_name or expr ??

sub _new_iterator {
    my $self = shift;

    return Womo::Relation::Iterator->new( relation => $self );
}

sub members {
    my $self = shift;

    my $it = $self->_new_iterator or die;
    my @all;
    while ( my $row = $it->next ) {
        push @all, $row;
    }
    return \@all;
}

sub projection {
    my $self       = shift;
    my @attributes = @_;
    return (blessed $self)->new(
        _expr    => [ $self, 'projection', @attributes ],
        _heading => [@attributes],
    );
}

sub rename {
    my $self = shift;
    my %map  = @_;
    my %old_map;
    my @old_attr = @{ $self->_heading };
    @old_map{@old_attr} = @old_attr;
    my %new_map = ( %old_map, %map );
    return (blessed $self)->new(
        _expr    => [ $self, 'rename', %map ],
        _heading => [ sort values %new_map ],
    );
}

sub restriction {
    my $self = shift;
    my $expr = shift;
    return (blessed $self)->new(
        _expr    => [ $self, 'restriction', $expr ],
        _heading => [ @{ $self->_heading } ],
    );
}

1;
__END__

