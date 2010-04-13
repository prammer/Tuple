
package Womo::SQL;
use Womo::Class;

has 'lines' => ( is => 'ro', isa => 'ArrayRef[Womo::SQL|Str]', required => 1, );

has 'bind' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    lazy     => 1,
    default  => sub { [] },
);

has 'next_label' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub combine_bind {
    my $self = shift;
    return [ @{ $self->bind }, map { @{ $_->bind } } @_ ];
}

sub text {
    my $self   = shift;
    my $indent = shift;
    $indent = 0 if !defined $indent;
    my $text = join( "\n", map { _make_chunk($_, $indent) } @{ $self->lines } );
    return $text;
}

sub _make_chunk {
    my ( $line, $indent ) = @_;
    if ( ref $line ) {
        return $line->text( $indent + 1 );
    }
    my $space = '';
    $space = '    ' x $indent if $indent;
    return $space . $line;
}

1;
__END__

