package Bot::Backbone::Service::TestChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
    Bot::Backbone::Role::Chat
);

use Bot::Backbone::Message;

has mq => (
    is          => 'rw',
    isa         => 'ArrayRef[HashRef]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        'put' => 'push',
    },
);

sub initialize { }

sub dispatch {
    my ($self, $text) = @_;

    my $message = Bot::Backbone::Message->new({
        chat  => $self,
        from  => Bot::Bakcbone::Identity->new(
            username => 'test',
            nickname => 'Test',
        ),
        to    => Bot::Backbone::Identity->new(
            username => 'testbot',
            nickname => 'Test Bot',
        ),
        group => undef,
        text  => $text,
    });

    $self->resend_message($message);

    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}

sub send_reply {
    my ($self, $message, $text) = @_;

    $self->put({
        action  => 'send_reply',
        message => $message,
        text    => $text,
    });
}

sub send_message {
    my ($self, %params) = @_;

    $self->put({
        %params,
        action => 'send_message',
    });
}

__PACKAGE__->meta->make_immutable;
