package Bot::Backbone::Service::GroupChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
    Bot::Backbone::Role::Chat
    Bot::Backbone::Role::ChatConsumer
);

has group => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

sub initialize {
    my $self = shift;
    $self->chat->join_group($self->group);
}

sub send_reply {
    my ($self, $message, $text) = @_;
    $self->chat->send_reply($message, $text);
}

sub send_message {
    my ($self, %params) = @_;
    my $text = $params{text};
    $self->chat->send_message(
        group => $self->group,
        text  => $text,
    );
}

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
