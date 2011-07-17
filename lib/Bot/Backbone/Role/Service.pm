package Bot::Backbone::Role::Service;
use Moose::Role;

requires 'initialize';

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has bot => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Bot',
    required    => 1,
    weak_ref    => 1,
);

1;
