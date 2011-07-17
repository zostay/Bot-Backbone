package Bot::Backbone::Role::Dispatch;
use v5.10;
use Moose::Role;

use namespace::autoclean;

has dispatcher_name => (
    is          => 'ro',
    isa         => 'Str',
    init_arg    => 'dispatcher',
    predicate   => 'has_dispatcher',
);

has dispatcher => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Dispatcher',
    init_arg    => undef,
    lazy_build  => 1,
    handles     => [ 'dispatch_message' ],

    # lazy_build implies (predicate => has_dispatcher)
    predicate   => 'has_setup_the_dispatcher', 
);

sub _build_dispatcher {
    my $self = shift;
    $self->bot->meta->dispatchers->{ $self->dispatcher_name };
}

1;
