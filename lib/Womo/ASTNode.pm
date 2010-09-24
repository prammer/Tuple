
package Womo::ASTNode;
use Womo::Class;
use Womo::Depot::Interface;
use Moose::Util::TypeConstraints;
use Moose::Util qw(does_role);
use Seq;

coerce 'Womo::ASTNode'
    => from 'HashRef'
    => via { Womo::ASTNode->new($_) };

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'args' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    default => sub { [] },
);

has 'heading' => (
    is       => 'ro',
    isa      => 'Seq',
    required => 1,
);

has 'depot' => (
    init_arg => undef,
    is       => 'ro',
    does     => 'Womo::Depot::Interface',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        ( $self->type eq 'table' ) or confess 'no depot for non-table types';
        return $self->args->[0];
    },
);

has 'table' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        ( $self->type eq 'table' ) or confess 'no table for non-table types';
        return $self->args->[1];
    },
);

has 'op' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        ( $self->type eq 'operator' ) or confess 'no op for non-operator types';
        return $self->args->[0];
    },
);

has 'op_args' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        ( $self->type eq 'operator' ) or confess 'no op for non-operator types';
        my @op_args = @{ $self->args };
        shift @op_args;
        return \@op_args;
    },
);

has 'child_relations' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'ArrayRef[Womo::Relation::Role]',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return [] if $self->type ne 'operator';
        return [
            grep { does_role( $_, 'Womo::Relation::Role' ) }
            @{ $self->op_args }
        ];
    },
);

has 'child_asts' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'ArrayRef[Womo::ASTNode]',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return [ map { $_->_ast } @{ $self->child_relations } ];
    },
);


1;
__END__

