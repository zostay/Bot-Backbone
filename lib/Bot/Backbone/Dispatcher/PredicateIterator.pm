package Bot::Backbone::Dispatcher::PredicateIterator;
use v5.10;
use Moose;

use Bot::Backbone::Types qw( PredicateList );

# ABSTRACT: Iterator over the predicates in a dispatcher

=head1 SYNOPSIS

  my $iterator = $dispatcher->predicate_iterator;
  while (my $predicate = $iterator->next_predicate) {
      # do something...
  }

=head1 DESCRIPTION

This is a helper for iterating over predicates in a L<Bot::Backbone::Dispatcher>.

=head1 ATTRIBUTES

=head2 dispatcher

This is the dispatcher this iterator iterates over.

=cut

has dispatcher => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Dispatcher',
    required    => 1,
);

has predicate_list => (
    is          => 'rw',
    isa         => PredicateList,
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        have_more_predicates     => 'count',
        next_from_predicate_list => 'shift',
        add_predicates           => 'push',
    },
);

=head1 METHODS

=head2 BUILD

Resets the iterator to the start at construction.

=cut

sub BUILD {
    my $self = shift;
    $self->reset;
}

=head2 next_predicate

Returns the next L<Bot::Backbone::Dispatcher::Predicate> or C<undef> if all predicates have been iterated through.

=cut

sub next_predicate {
    my $self = shift;

    return unless $self->have_more_predicates;

    my $predicate = $self->next_from_predicate_list;
    $self->add_predicates($predicate->more_predicates);

    return $predicate;
}

=head2 reset

Starts over by retriving the list of predicates that belong to the associated L<Bot::Backbone::Dispatcher>.

=cut

sub reset {
    my $self = shift;

    $self->predicate_list([
        $self->dispatcher->list_predicates,
        $self->dispatcher->list_also_predicates,
    ]);
}

__PACKAGE__->meta->make_immutable;
