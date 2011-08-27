package Bot::Backbone::Service::DirectChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::ChatConsumer
);

with 'Bot::Backbone::Service::Role::Chat' => {
    -excludes => [ qw( send_message ) ],
};

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

If the message is not to a group and is sent direct, it will be passed on to
any chat consumers and dispatched.

=cut

sub receive_message {
    my ($self, $message) = @_;

    return unless not $message->is_group
                  and $message->is_direct;

    $self->resend_message($message);
    $self->dispatch_message($message);
}

__PACKAGE__->meta->make_immutable;
