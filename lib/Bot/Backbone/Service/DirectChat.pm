package Bot::Backbone::Service::DirectChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
    Bot::Backbone::Role::Chat
    Bot::Backbone::Role::ChatConsumer
);

sub initialize { }

sub send_reply {
    my ($self, $message, $text) = @_;
    $self->chat->send_reply($message, $text);
}

sub receive_message {
    my ($self, $message) = @_;

    return unless $message->is_direct;

    $self->resend_message($message);
    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}

__PACKAGE__->meta->make_immutable;
