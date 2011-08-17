package Bot::Backbone::Service::Role::ChatConsumer;
use v5.10;
use Moose::Role;

# ABSTRACT: Role for services that listen for chat messages

=head1 DESCRIPTION

Any service that needs to listen for chats and react to them will implement this
role.

=head1 ATTRIBUTES

=head2 chat_name

  service my_responder => (
      service => '=My::Responder',
      chat    => 'jabber',
  );

This attribute is named C<chat> during construction. It is used to look up the
chat service set in L</chat>.

=cut

has chat_name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    init_arg    => 'chat',
    predicate   => 'has_chat',
);

=head2 chat

This is the L<Bot::Backbone::Service::Role::Chat> that this responder will receive
messages from.

This must not be set directly and will be loaded lazily for you from the setting
in L</chat_name>.

=cut

has chat => (
    is          => 'ro',
    does        => 'Bot::Backbone::Service::Role::Chat',
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

    return $chat;
}

=head1 REQUIRED METHODS

=head2 receive_message

  $consumer->receive_message($message);

Whenever the chat service receives a message, it will pass it on to each
registered consumer by passing it to this method.

The method can do whatever it wants here and the return value of this method is
ignored.

=cut

requires 'receive_message';

=head1 METHODS

=head2 initialize

This adds a bit of code to run before the service's C</initialize>. It loads
the chat object from the bot and registers this consumer with that chat service.

=cut

before initialize => sub {
    my $self = shift;
    my $chat = $self->chat if $self->has_chat;
    $chat->register_chat_consumer($self);
};

1;
