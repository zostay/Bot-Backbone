package Bot::Backbone::Service::GroupChat;

use v5.10;
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::Chat
);

with 'Bot::Backbone::Service::Role::ChatConsumer' => {
    -excludes => [ 'send_message' ],
};

with_bot_roles qw(
    Bot::Backbone::Bot::Role::GroupChat
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

=head2 nickname

This is the nickname to pass to the chat when joining the group. If not set, no
special nickname will be requested.

=cut

has nickname => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_nickname',
);

=head1 METHODS

=head2 initialize

Joins the L</group>.

=cut

sub initialize {
    my $self = shift;

    my %options = (
        group => $self->group,
    );

    $options{nickname} = $self->nickname if $self->has_nickname;

    $self->chat->join_group(\%options);
}

=head2 send_message

Sends a message to the L</group>.

=cut

sub send_message {
    my ($self, $params) = @_;
    my $text = $params->{text};
    $self->chat->send_message({
        group => $self->group,
        text  => $text,
    });
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
    $self->dispatch_message($message);
}

__PACKAGE__->meta->make_immutable;
