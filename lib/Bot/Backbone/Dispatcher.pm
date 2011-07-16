package Bot::Backbone::Dispatcher;
use v5.10;
use Moose;

# ABSTRACT: Simple dispatching tool

has predicates => (
    is          => 'ro',
    isa         => 'ArrayRef[CodeRef]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        add_predicate => 'push',
    },
);

__PACKAGE__->meta->make_immutable;
