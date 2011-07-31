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

# ABSTRACT: Chat with an interactive command line

=head1 SYNOPSIS

  service console => (
      service      => 'ConsoleChat',
      bot_username => 'coolbot',
      bot_nickname => 'Cool Bot',
  );

=head1 DESCRIPTION

This is a handy service for interacting with a bot from the command line. This
can be useful for interfering with the state of the bot or working with the bot
without going through some other chat server.

=head1 ATTRIBUTES

=head2 term

This is the internal readline terminal object.

No user serviceable parts.

=cut

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

=head2 bot_username

The username to give the bot.

=cut

has bot_username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 bot_nickname

The nickname to give the bot.

=cut

has bot_nickname => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 current_group

The console chat provides groups for chat. This is mostly to allow it to work
seamlessly with the multicast chat.

When chat is in a group, any message the bot sends to that group will be
displayed. Also, interactive commands sent will be presented as if they happened
in that group.

The special group "(none)" means that console is in no group. This mutes all 
group chats that the bot may send and all entries on the command line will
behave as if they are direct messages to the bot.

=cut

has current_group => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => '(none)',
);

=head1 EVENT HANDLERS

=head2 _start

Starts the chat and shows the first prompt.

=cut

sub _start {
    my $self = $_[OBJECT];

    my $term = $self->term;
    $term->put('Starting console chat.');
    $term->get($self->prompt);
}

=head2 got_console_input

Whenever the user hits enter, this dispatches, notifies the chat consumers, and
puts up the next prompt.

Anything not matching a built-in command will be passed to the bot as if it were
a direct message or posted to the L</current_group>.

The built-in commands include:

=head3 /quit

This causes the bot to shutdown and exit.

=head3 /join

  /join group

Given the name of a group, the console changes the L</current_group> that that
group name.

=head3 /leave

Causes the console chat to enter the "(none)" group. 

See L</current_group>.

=head3 /dm

  /dm ...

This is implied when the L</current_group> is "(none)". This causes a message
typed at the prompt to be treated as a direct message, even if L</current_group>
is set to a specific group.

=cut

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

=head1 METHODS

=head2 prompt

This is used to draw the prompt.

=cut

sub prompt {
    my $self = shift;
    return $self->current_group . ' > ';
}

=head2 initialize

This sets up the L<POE::Session> that is used to manage the terminal wheel.

=cut

sub initialize {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self => [ qw( _start got_console_input ) ],
        ],
    );
}

=head2 join_group

Does nothing. The bot can communicate with a group whether joined or not, we
don't especially care.

=cut

sub join_group { }

=head2 send_reply

Whenever the bot replies to a message, the reply will be posted to console.

=cut

sub send_reply {
    my ($self, $message, $text) = @_;
    $self->term->put($self->bot_username . ': ' . $text);
}

=head2 send_message

Whenever the bot sends a message, it will be displayed if it is a direct message
back to the console or if the group name matches the L</current_group>. All
other messages will be muted.

=cut

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

=head2 shutdown

Says good-bye and destroys the terminal object, which will shutdown the session
and allow the bot to exit.

=cut

sub shutdown {
    my $self = shift;
    $self->term->put('Good-bye.');
    $self->clear_term;
}

__PACKAGE__->meta->make_immutable;
