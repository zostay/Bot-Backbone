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

sub receive_message {
    my ($self, $message) = @_;

    return unless $message->is_direct;

    $self->resend_message($message);
    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}

__PACKAGE__->meta->make_immutable;
