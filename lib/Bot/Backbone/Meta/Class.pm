package Bot::Backbone::Meta::Class;
use Moose;

extends 'Moose::Meta::Class';

has services => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        add_service   => 'set',
        list_services => 'keys',
    },
);

has dispatchers => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        add_dispatcher => 'set',
    },
);

__PACKAGE__->meta->make_immutable;
