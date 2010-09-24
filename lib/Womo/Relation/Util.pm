
package Womo::Relation::Util;

use warnings FATAL => 'all';
use strict;
use Set::Object qw(set);
use Carp qw(confess);
use Moose::Util qw(does_role);
use Womo::SQL;
use SQL::Abstract;
use List::AllUtils qw(any);
use namespace::autoclean;

#use Sub::Exporter -setup => { exports => [qw(foo)] };

sub _hash_arg {
    if ( @_ == 1 ) {
        ( ref( $_[0] ) && ref( $_[0] ) eq 'HASH' )
            or confess 'single arg must be a hashref';
        return $_[0];
    }
    ( @_ % 2 == 0 ) or confess 'expecting a hash or hash reference, got odd number of items';
    return {@_};
}

sub _array_arg {
    if ( @_ == 1 &&  ref( $_[0] ) && ref( $_[0] ) eq 'ARRAY' ) {
        return $_[0];
    }
    return [@_];
}

sub _array_arg_ensure_same_headings {
    my $r1 = shift;
    my $others = _array_arg(@_);
    _ensure_same_headings($r1, $_) for (@$others);
    return $others;
}

sub _ensure_same_headings {
    if ( !has_same_heading(@_) ) {
        confess "headings differ:\n["
            . CORE::join( ',', @{ $_[0]->heading } ) . "]\n["
            . CORE::join( ',', @{ $_[1]->heading } ) . ']';
    }
}

sub has_same_heading {
    return _headings_are_same( $_[0]->heading, $_[1]->heading );
}

sub _headings_are_same {
    return set( @{ $_[0] } )->equal( set( @{ $_[1] } ) );
}

sub projection {
    my $r = shift;

    my $attributes = _array_arg(@_);
    {
        my $a     = set(@$attributes);
        my $h     = set( @{ $r->heading } );
        my $broke = $a->difference($h);
        if ( $broke->size > 0 ) {
            my $members = CORE::join( ', ', $broke->members );
            confess "not attribute(s) of this relation: $members";
        }
    }

    return $r->new(
        'ast' => {
            'type'    => 'operator',
            'args'    => [ 'projection', $r, $attributes, ],
            'heading' => Seq->new(CORE::sort @$attributes) ,
        },
    );
}

# TODO: the keys and values seem reversed, but this is how Set::Relation works
sub rename {
    my $r   = shift;
    my $map = _hash_arg(@_);

    my $comp = { map { $_ => 1 } @{ $r->heading } };
    for my $attr ( values %$map ) {
        confess "'$attr' is not an attribute of this relation"
            if ( !$comp->{$attr} );
    }

    # check for values %$map in keys %$comp but not in keys %$map
    my $orig   = set( keys %$comp );
    my $new    = set( keys %$map );
    my $rename = set( values %$map );
    my $broke  = $orig->intersection($new)->difference($rename);
    if ( $broke->size > 0 ) {
        my $members = CORE::join( ', ', $broke->members );
        confess "renaming to existing unrenamed attribute(s): $members";
    }

    return $r->new(
        'ast' => {
            'type' => 'operator',
            'args' => [ 'rename', $r, {%$map}, ],
            'heading' =>
                Seq->new(CORE::sort $orig->difference($rename)->union($new)->members),
        },
    );
}

sub restriction {
    my $r    = shift;
    my $expr = @_ == 1 ? shift : {@_};  # either a CODE or a hash

    return $r->new(
        'ast' => {
            'type'    => 'operator',
            'args'    => [ 'restriction', $r, $expr, ],
            'heading' => $r->heading,
        },
    );
}

sub union {
    my $r = shift;

    # TODO: deal with is_empty

    return $r if ( @_ == 0 );
    my $others = _array_arg_ensure_same_headings($r, @_);
    return _reduce_op( $r, $others, 'union', $r->heading, );
}

sub intersection {
    my $r = shift;

    confess 'TODO: infinite relation?' if ( @_ == 0 );
    my $others = _array_arg_ensure_same_headings( $r, @_ );
    return _reduce_op( $r, $others, 'intersection', $r->heading, );
}

sub join {
    my $r = shift;

    my $others = _array_arg(@_);
    return $r if ( @$others == 0 );
    my $heading = set( map { @{ $_->heading } } ( $r, @$others ) );
    return _reduce_op( $r, $others, 'join', Seq->new(CORE::sort $heading->members), );
}

sub insertion {
die;
    my ( $self, @tuples ) = @_;

    # check headings
    # do lazy ast on ::InMemory relation
    # checking ->contains, etc happens lazily
    my $heading = $self->heading;
    for my $t (@tuples) {
        confess 'not a Romo::Tuple' if ( !$t->does('Romo::Tuple') );
        confess 'different headings'
            if ( !$heading->is_identical( $t->heading ) );
    }
    return $self->meta->name->new( $self->members, @tuples );
}

sub _reduce_op {
    my ( $r, $others, $op, $heading ) = @_;

# TODO: deal better with $others not doing Womo::Relation::Role (ie not SQL backed)
    my ( @does, @not );
    for my $r (@$others) {
        if ( does_role( $r, 'Womo::Relation::Role' ) ) {
            push @does, $r;
        }
        else {
            push @not, $r;
        }
    }

    if ( @not != 0 ) {
        my $one = shift @not;
        return ( @not ? $one->$op(@not) : $one )
            ->$op( ( @does ? $r->$op(@does) : $r ) );
    }

    return $r->new(
        'ast' => {
            'type'    => 'operator',
            'args'    => [ $op, $r, @$others, ],
            'heading' => $heading,

        },
    );
}

sub new_iterator {
    my $ast = shift or confess 'must pass ast';

    if ( _ast_can_full_sql($ast) ) {
        require Womo::Relation::Iterator::STH;
        return Womo::Relation::Iterator::STH->new(
            sth => _new_sth($ast), );
    }

    if ( $ast->type eq 'operator' ) {
        return _new_iterator_op($ast);
    }

    die "not implemented";
}

sub _new_iterator_op {
    my $ast = $_[0];

    my $method = '_new_iterator_' . $ast->op;
    if ( !__PACKAGE__->can($method) ) {
#        $DB::single = 1;
        die "not implemented " . $ast->op;
    }
    return __PACKAGE__->can($method)->(@_);
}

sub _new_iterator_restriction {
    my $ast = shift;

    my $parent_it = new_iterator( $ast->child_asts->[0] );
    my $want      = $ast->op_args->[1];
    return Womo::Relation::Iterator::CodeRef->new(

        code => sub {
            while (1) {
                my $next = $parent_it->next or return;
                local $_ = $next;
                return $next if $want->($next);
            }
        }
    );
}

sub _new_iterator_projection {
    my $ast = shift;

    my $parent_it = new_iterator( $ast->child_asts->[0] );
    my @attr      = @{ $ast->op_args->[1] };
    return Womo::Relation::Iterator::CodeRef->new(

        code => sub {
            while (1) {
                my $next = $parent_it->next or return;
                return $next->projection(@attr);
                my %new;
                @new{@attr} = @$next{@attr};
                return \%new;
            }
        }
    );
}

sub _ast_can_full_sql {
    my $ast = shift or die;

    # TODO: check for different depots
    for my $sub ( @{ $ast->child_asts } ) {
        return 0 if !_ast_can_full_sql($sub);
    }
    return 0
        if ( $ast->type eq 'operator'
        && $ast->op eq 'restriction'
        && ref( $ast->op_args->[1] ) eq 'CODE' );
    return 1;
}

sub _new_sql {
    return Womo::SQL->new(@_);
}

sub _build_sql {
    my $ast = $_[0];

    if ( $ast->type eq 'table' ) {
        return _build_sql_table(@_);
    }
    elsif ( $ast->type eq 'operator' ) {
        my $method = '_build_sql_' . $ast->op;
        return __PACKAGE__->can($method)->(@_);
    }
    else {
        die 'wha!?';
    }
}

sub _build_sql_table {
    my ( $ast, $next_label ) = @_;

    # TODO: if heading includes any key, leave off distinct
    my $table = $ast->table;
    my $col   = $ast->heading;
    return _new_sql(
        'lines' =>
            [ 'select distinct ' . CORE::join( ', ', @$col ) . " from $table" ],
        'bind'       => [],
        'next_label' => $next_label,
    );
}

sub _build_sql_restriction {
    my ( $ast, $next_label ) = @_;

    my $sql = SQL::Abstract->new;
    my ( $stmt, @bind ) = $sql->where( $ast->op_args->[1] );
    my @table;
    if ( $ast->child_asts->[0]->type eq 'table' ) {
        @table = ( $ast->child_asts->[0]->table );
    }
    else {
        my $p_sql = _build_sql( $ast->child_asts->[0], $next_label );
        $next_label = $p_sql->next_label,
        @table = ( '(', $p_sql, ')' );
        unshift @bind, @{ $p_sql->bind };
    }

    return _new_sql(
        'lines'      => [ 'select distinct * from', @table, $stmt, ],
        'bind'       => \@bind,
        'next_label' => $next_label,
    );
}

sub _build_sql_projection {
    my ( $ast, $next_label ) = @_;

    if ( $ast->child_asts->[0]->type eq 'table' ) {
        my $table = $ast->child_asts->[0]->table;
        return _new_sql(
            'lines' => [
                "select distinct " . CORE::join( ", ", @{ $ast->heading } ),
                "from $table",
            ],
            'bind'       => [],
            'next_label' => $next_label,
        );
    }

    my $p_sql = _build_sql( $ast->child_asts->[0], $next_label );
    return _new_sql(
        'lines' => [
            "select distinct " . CORE::join( ", ", @{ $ast->heading } ),
            'from (', $p_sql, ')',
        ],
        'bind'       => $p_sql->bind,
        'next_label' => $p_sql->next_label,
    );
}

sub _build_sql_rename {
    my ( $ast, $next_label ) = @_;

    my $map  = $ast->op_args->[1];
    my $comp = set( @{ $ast->child_relations->[0]->heading } )
        ->difference( values %$map );
    my $clause = CORE::join( ', ',
        ( sort $comp->members ),
        ( map { "$map->{$_} $_" } sort keys %$map ) );
    if ( $ast->child_asts->[0]->type eq 'table' ) {
        return _new_sql(
            'lines' => [
                "select distinct $clause from "
                    . $ast->child_asts->[0]->table,
            ],
            'bind'       => [],
            'next_label' => $next_label,
        );
    }
    my $p_sql = _build_sql( $ast->child_relations->[0], $next_label );
    return _new_sql(
        'lines'      => [ "select $clause from (", $p_sql, ')', ],
        'bind'       => $p_sql->bind,
        'next_label' => $p_sql->next_label,
    );
}

sub _all_sql_reduce_bind {
    my ( $to_reduce, $next_label ) = @_;
    my @sql;
    for my $ast ( @{$to_reduce} ) {
        push @sql, _build_sql( $ast, $next_label );
        $next_label = $sql[-1]->next_label;
    }
    my $bind = [ map { @{ $_->bind } } @sql ];
    return ( \@sql, $bind );
}

sub _build_sql_union {
    my ( $ast, $next_label ) = @_;

    my ( $sql, $bind ) = _all_sql_reduce_bind( $ast->child_asts, $next_label );
    $sql = [ map { ( $_, 'union' ) } @$sql ];
    pop @$sql;
    return _new_sql(
        'lines'      => $sql,
        'bind'       => $bind,
        'next_label' => $next_label,
    );
}

sub _build_sql_intersection {
    my ( $ast, $next_label ) = @_;

    my ( $sql, $bind ) = _all_sql_reduce_bind( $ast->child_asts, $next_label );
    $sql = [ map { ( $_, 'intersect' ) } @$sql ];
    pop @$sql;
    return _new_sql(
        'lines'      => $sql,
        'bind'       => $bind,
        'next_label' => $next_label,
    );
}

sub _build_sql_join {
    my ( $ast, $next_label ) = @_;

    my @chunks = map {
        my $h = set( @{ $_->{heading} } );
        my $to_join_sql = _build_sql( $_, $next_label );
        $next_label = $to_join_sql->next_label;
        { 'sql' => $to_join_sql, 'heading' => $h, 'ast' => $_, };
    } @{ $ast->child_asts };

    $_->{label} = $next_label++ for (@chunks);

    my @select;
    my $selected = set();
    my $previous;
    my @table_joins;
    my %labeled_attribute;
    for my $chunk (@chunks) {
        my $to_select = $chunk->{heading}->difference($selected);
        my $common    = $chunk->{heading}->intersection($selected);
        my $l         = $chunk->{label};
        push @select, map { "$l.$_ $_" } sort $to_select->members;
        $labeled_attribute{$_} = "$l.$_" for ( $to_select->members );
        $selected = $selected->union($to_select);
        my @this;
        if ( $chunk->{ast}->type eq 'table' ) {
            @this = ( $chunk->{ast}->table . " $l" );
        }
        else {
            @this = ( '(', $chunk->{sql}, ") $l" );
        }
        if ($previous) {
            unshift @this, 'join';

            if ( $common->size > 0 ) {
                my @on = (
                    'on ('
                        . CORE::join( ' and ',
                        map { "$l.$_ = $labeled_attribute{$_}" }
                        sort $common->members )
                        . ')'
                );
                push @this, @on;
            }
        }
        push @table_joins, @this;
        $previous = $chunk;
    }

    my $bind = [ map { @{ $_->{sql}->bind } } @chunks ];

    return _new_sql(
        'lines' => [
            'select distinct', CORE::join( ', ', @select ),
            'from', @table_joins,
        ],
        'bind'       => $bind,
        'next_label' => $next_label,
    );
}

sub _uniq_via_is_identical {
    my @uniq;
    while ( my $item = shift ) {
        next if any { $item->is_identical($_) } @uniq;
        push @uniq, $item;
    }
    return @uniq;
}

sub _find_depots {
    my $ast = shift;
    if ( $ast->type eq 'table' ) { return $ast->depot }
    return _uniq_via_is_identical( map { _find_depots($_) } @{ $ast->child_asts } );
}

sub _find_depot {
    my @d = _find_depots(@_);
    ( @d == 1 ) or confess 'could not find exactly 1 depot';
    return $d[0];
}

sub _new_sth {
    my $ast = shift or confess 'must pass ast';

    my $sql = _build_sql( $ast, 'a' );
    print "-------------\n" . $sql->text . "\n";
    my $db_conn = _find_depot($ast)->db_conn;
    print CORE::join( ', ', map { "'$_'" } @{ $sql->bind } ) . "\n";
    print "---------------\n";
    my $sth = $db_conn->run( sub {
        my $sth = $_->prepare( $sql->text ) or die $_->errstr;
        $sth->execute( @{ $sql->bind } ) or die $sth->errstr;
        return $sth;
    });
    return $sth;
}

1;
__END__

