package Bot::Backbone::Person;
use v5.10;
use Moose;

# ABSTRACT: Describes a person sending or receiving a message

has username => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has nickname => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

__PACKAGE__->meta->make_immutable;
