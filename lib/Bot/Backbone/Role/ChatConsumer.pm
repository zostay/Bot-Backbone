package Bot::Backbone::Role::ChatConsumer;
use v5.10;
use Moose::Role;

has chat_name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    init_arg    => 'chat',
    predicate   => 'has_chat',
);

has chat => (
    is          => 'ro',
    does        => 'Bot::Backbone::Role::Chat',
    init_arg    => undef,
    lazy_build  => 1,
    weak_ref    => 1,

    # lazy_build implies (predicate => has_chat)
    predicate   => 'has_setup_the_chat',
);

sub _build_chat {
    my $self = shift;
    my $chat = $self->bot->services->{ $self->chat_name };

    die "no such chat as ", $self->chat_name, "\n"
        unless defined $chat;

    $chat->register_chat_consumer($self);
    return $chat;
}

requires 'receive_message';

1;
