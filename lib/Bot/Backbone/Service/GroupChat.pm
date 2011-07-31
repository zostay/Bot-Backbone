package Bot::Backbone::Service::GroupChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
    Bot::Backbone::Role::Chat
    Bot::Backbone::Role::ChatConsumer
);

# ABSTRACT: A helper chat for performing group chats

=head1 SYNOPSIS

  service group_foo => (
      service => 'GroupChat',
      chat    => 'jabber_chat',
      group   => 'foo',
  );

=head1 DESCRIPTION

This is a chat consumer that provides chat services to a specific group on the
consumed chat service.

=head1 ATTRIBUTES

=head2 group

This is the name of the group this chat will communicate with. It will not
perform chats in any other group or directly.

=cut

has group => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head1 METHODS

=head2 initialize

Joins the L</group>.

=cut

sub initialize {
    my $self = shift;
    $self->chat->join_group($self->group);
}

=head2 send_reply

Replies to L</group> chats that were forwarded on.

=cut

sub send_reply {
    my ($self, $message, $text) = @_;
    $self->chat->send_reply($message, $text);
}

=head2 send_message

Sends a message to the L</group>.

=cut

sub send_message {
    my ($self, %params) = @_;
    my $text = $params{text};
    $self->chat->send_message(
        group => $self->group,
        text  => $text,
    );
}

=head2 receive_message

If the message belongs to the L</group> this chat service works with, the
consumers will be notified and the dispatcher run. Otherwise, the message will
be ignored.

=cut

sub receive_message {
    my ($self, $message) = @_;

    return unless $message->is_group
              and $message->group eq $self->group;

    $self->resend_message($message);
    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}

__PACKAGE__->meta->make_immutable;
