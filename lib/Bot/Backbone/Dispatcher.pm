package Bot::Backbone::Dispatcher;
use v5.10;
use Moose;

use Bot::Backbone::Types qw( PredicateList );

# ABSTRACT: Simple dispatching tool

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

sub dispatch_message {
    my ($self, $message) = @_;

    for my $predicate ($self->list_predicates) {
        my $success = $message->set_bookmark_do(sub {
            $predicate->($message);
        });
        last if $success;
    }

    for my $predicate ($self->list_also_predicates) {
        $message->set_bookmark_do(sub { $predicate->($message) });
    }
}

__PACKAGE__->meta->make_immutable;
