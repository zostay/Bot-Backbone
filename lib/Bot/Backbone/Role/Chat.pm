package Bot::Backbone::Role::Chat;
use v5.10;
use Moose::Role;

has chat_consumers => (
    is          => 'ro',
    isa         => 'ArrayRef[Bot::Backbone::Role::ChatConsumer]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        register_chat_consumer => 'push',
        list_chat_consumers    => 'elements',
    },
);

requires qw( send_reply send_message );

sub resend_message {
    my ($self, $message) = @_;

    for my $consumer ($self->list_chat_consumers) {
        $consumer->receive_message($message);
    }
}

1;
