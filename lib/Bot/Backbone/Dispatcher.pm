package Bot::Backbone::Dispatcher;
use v5.10;
use Moose;

use Bot::Backbone::Types qw( PredicateList );

# ABSTRACT: Simple dispatching tool

=head1 SYNOPSIS

  my $dispatcher = Bot::Backbone::Dispatcher->new(
      predicates      => \@predicates,
      also_predicates => \@also_predicates,
  );

  my $message = Bot::Backbone::Message->new(...);
  $dispatcher->dispatch_message($message);

=head1 DESCRIPTION

A dispatcher is an array of predicates that are each executed in turn. Each predicate is a subroutine that is run against the message that may or may not take an action against it and is expected to return a boolean value declaring whether any action was taken.

=head1 ATTRIBUTES

=head2 predicates

Predicates in this list are executed sequentially and in order. The first predicate to return a true value causes execution to cease so that any further predicates are ignored.

=cut

has predicates => (
    is          => 'ro',
    isa         => PredicateList,
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        add_predicate   => 'push',
        list_predicates => 'elements',
    },
);

=head2 also_predicates

This list of predicates are not guaranteed to execute sequentially or in any particular order. The return value of these predicates will be ignored and all will be executed on every message, even those that have already been handled by a predicate in the L</predicates> list.

=cut

has also_predicates => (
    is          => 'ro',
    isa         => PredicateList,
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        add_also_predicate   => 'push',
        list_also_predicates => 'elements',
    },

);

=head1 METHODS

=head2 dispatch_message

  $dispatcher->dispatch_message($message);

Given a L<Bot::Backbone::Message>, this will execute each predicate attached to the dispatcher, using the policies described under L</predicates> and L</also_predicates>.

=cut

sub dispatch_message {
    my ($self, $service, $message) = @_;

    for my $predicate ($self->list_predicates) {
        my $success = $message->set_bookmark_do(sub {
            $predicate->($service, $message);
        });
        last if $success;
    }

    for my $predicate ($self->list_also_predicates) {
        $message->set_bookmark_do(sub { $predicate->($service, $message) });
    }
}

=head2 add_predicate_or_return

  $dispatcher->add_predicate_or_return($predicate);

Chances are that you probably don't need this method. However, if you are creating a new kind of predicate, you will probably want this method.

This will do the right thing to either add a root level predicate to the dispatcher or return the predicate for chaining within another predicate. You probably want to read the code in L<Bot::Backbone::DispatchSugar> for examples.

=cut

sub add_predicate_or_return {
    my ($self, $code) = @_;

    if (defined wantarray) {
        return $code;
    }
    else {
        $self->add_predicate($code);
    }
}

__PACKAGE__->meta->make_immutable;
