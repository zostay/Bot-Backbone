package Bot::Backbone::Identity;
use v5.10;
use Moose;

# ABSTRACT: Describes an account sending or receiving a message

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
