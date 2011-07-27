package Bot::Backbone::Service::ConsoleChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
    Bot::Backbone::Role::Chat
    Bot::Backbone::Role::GroupJoiner
);

use Bot::Backbone::Message;
use POE qw( Wheel::ReadLine );

has term => (
    is          => 'ro',
    isa         => 'POE::Wheel::ReadLine',
    required    => 1,
    lazy_build  => 1,
    clearer     => 'clear_term',
);

sub _build_term { 
    my $self = shift;
    POE::Wheel::ReadLine->new(
        AppName    => $self->bot->meta->name,
        InputEvent => 'got_console_input',
    );
};

has bot_username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has bot_nickname => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has current_group => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => '(none)',
);

sub prompt {
    my $self = shift;
    return $self->current_group . ' > ';
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
    if ($input eq '/quit') {
        $term->addhistory($input);
        $self->bot->shutdown;
        return;
    }
    elsif ($input =~ m{^/join\s+(\w+)}) {
        $term->addhistory($input);
        $self->current_group($1);
        $input = '';
    }
    elsif ($input =~ m{^/leave$}) {
        $term->addhistory($input);
        $self->current_group('(none)');
        $input = '';
    }
    elsif ($input =~ s{^/dm\s+(.+)}{$1}) {
        $term->addhistory($input);

        my $message = Bot::Backbone::Message->new({
            chat  => $self,
            from  => Bot::Backbone::Identity->new(
                username => '(console)',
                nickname => '(console)',
            ),
            to    => Bot::Backbone::Identity->new(
                username => $self->bot_username,
                nickname => $self->bot_nickname,
            ),
            group => undef,
            text  => $input,
        });

        $self->resend_message($message);

        if ($self->has_dispatcher) {
            $self->dispatch_message($message);
        }
    }
    else {
        my $group = $self->current_group;
           $group = undef if $group eq '(none)';

        my $message = Bot::Backbone::Message->new({
            chat  => $self,
            from  => Bot::Backbone::Identity->new(
                username => '(console)',
                nickname => '(console)',
            ),
            to    => Bot::Backbone::Identity->new(
                username => $self->bot_username,
                nickname => $self->bot_nickname,
            ),
            group => $group,
            text  => $input,
        });

        $self->resend_message($message);

        if ($self->has_dispatcher) {
            $self->dispatch_message($message);
        }
    }

    if ($input ne '') {
        $term->addhistory($input);
        $term->put($input);
    }
    $term->get($self->prompt);
}

sub initialize {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self => [ qw( _start got_console_input ) ],
        ],
    );
}

sub join_group { }

sub send_reply {
    my ($self, $message, $text) = @_;
    $self->term->put($self->bot_username . ': ' . $text);
}

sub send_message {
    my ($self, %params) = @_;

    my $to    = $params{to};
    my $group = $params{group};
    my $text  = $params{text};

    if (defined $group) {
        return unless $group eq $self->current_group;
    }
    elsif (defined $to) {
        return unless $to->username eq '(console)';
    }
    else {
        return;
    }

    $self->term->put($self->bot_username . ': ' . $text);
}

sub shutdown {
    my $self = shift;
    $self->term->put('Good-bye.');
    $self->clear_term;
}

__PACKAGE__->meta->make_immutable;
