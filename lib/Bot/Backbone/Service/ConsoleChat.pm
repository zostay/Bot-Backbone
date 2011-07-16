package Bot::Backbone::Service::ConsoleChat;
use v5.10;
use Moose;

with 'Bot::Backbone::Service';

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
    is          => 'ro',
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

    my $term = $self->term;
    $term->put($input);
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
