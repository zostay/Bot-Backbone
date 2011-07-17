package Bot::Backbone::Service::ConsoleChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
);

use Bot::Backbone::Message;
use POE qw( Wheel::ReadLine );

has term => (
    is          => 'ro',
    isa         => 'POE::Wheel::ReadLine',
    required    => 1,
    lazy_build  => 1,
);

sub _build_term { 
    my $self = shift;
    POE::Wheel::ReadLine->new(
        AppName    => $self->bot->meta->name,
        InputEvent => 'got_console_input',
    );
};

has current_room => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => '(none)',
);

sub prompt {
    my $self = shift;
    return $self->current_room . ' > ';
}

sub _start {
    my $self = $_[OBJECT];

    my $term = $self->term;
    $term->put('Starting console chat.');
    $term->get($self->prompt);
}

sub got_console_input {
    my ($self, $input, $exception) = @_[OBJECT, ARG0, ARG1];

    return unless defined $input;

    if ($input eq '/quit') {
        return;
    }
    elsif ($input =~ m{^/join\s+(.*)}) {
        $self->current_room($1);
        $input = '';
    }
    elsif ($self->has_dispatcher) {
        my $message = Bot::Backbone::Message->new($input);
        $self->dispatch_message($message);
    }

    my $term = $self->term;
    $term->put($input) if $input ne '';
    $term->get($self->prompt);
}

sub initialize {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self => [ qw( _start got_console_input ) ],
        ],
    );
    POE::Kernel->run;
}

__PACKAGE__->meta->make_immutable;
