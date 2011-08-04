package Bot::Backbone::Service::DirectChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
    Bot::Backbone::Role::Chat
    Bot::Backbone::Role::ChatConsumer
);

# ABSTRACT: A helper for doing direct chats

=head1 SYNOPSIS

  service private_chat => (
      service => 'DirectChat',
      chat    => 'jabber_chat',
  );

=head1 DESCRIPTION

This is a chat service layered on top of an existing chat service. It only
passes on direct chats received and only sends direct chages back.

=head1 METHODS

=head2 initialize

Does nothing.

=cut

sub initialize { }

=head2 send_reply

Forwards the direct message reply on to the nested chat service.

=cut

sub send_reply {
    my ($self, $message, $text) = @_;
    $self->chat->send_reply($message, $text);
}

=head2 send_message

Sends a direct message chat to the nested chat service.

=cut

sub send_message {
    my ($self, %params) = @_;

    my $to = $params{to} // Bot::Backbone::Identity->new(
        username => $params{to_username},
        (defined $params{to_nickname} ? (nickname => $params{to_nickname}) : ()),
    );

    my $text = $params{text};

    $self->chat->send_message(
        to   => $to,
        text => $text,
    );
}

=head2 receive_message

If the message is direct, it will be passed on to any chat consumers and
dispatched.

=cut

sub receive_message {
    my ($self, $message) = @_;

    return unless $message->is_direct;

    $self->resend_message($message);
    $self->dispatch_message($message);
}

__PACKAGE__->meta->make_immutable;
