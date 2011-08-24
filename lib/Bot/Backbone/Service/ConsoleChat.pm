package Bot::Backbone::Service::ConsoleChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::BareMetalChat
);

use Bot::Backbone::Message;
use List::MoreUtils qw( all );
use POE qw( Wheel::ReadLine );

# ABSTRACT: Chat with an interactive command line

=head1 SYNOPSIS

  service console => (
      service  => 'ConsoleChat',
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

=head2 prompt

This is the prompt displayed to the user. It is "> " by default. You may set
this during initialization or the bot may modify it as desired.

=cut

has prompt => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => '> ',
);

=head2 username

This is the name of the user at the console. This is set to C<$ENV{USER}> by
default.

=cut

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => sub { $ENV{USER} },
);

=head2 nickname

This is the nickname to give the user at the console. As of now, this is also se to
C<$ENV{USER}> be default.

It may be set to gecos or something by default in the future.`

=cut

has nickname => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => sub { $ENV{USER} },
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

Anything not matching a built-in command will be passed to the bot as a direct
message.  
The built-in commands include:

=head3 /quit

This causes the bot to shutdown and exit.

=cut

sub got_console_input {
    my ($self, $p, $input, $exception) = @_[OBJECT, KERNEL, ARG0, ARG1];

    return unless defined $input;

    my $term = $self->term;
    if ($input eq '/quit') {
        $self->bot->shutdown;
        return;
    }
    else {
        $p->yield('cli_message', $input);
    }

    $term->addhistory($input) if $input =~ /\S/;
    $term->get($self->prompt);
}

=head2 cli_message

Handles most messages typed on the command line.

=cut

sub cli_message {
    my ($self, $text) = @_[OBJECT,ARG0];

    my $message = Bot::Backbone::Message->new({
        chat  => $self,
        from  => Bot::Backbone::Identity->new(
            username => $self->username,
            nickname => $self->nickname,
            me       => '', # never from me
        ),
        to    => Bot::Backbone::Identity->new(
            username => '(console)',
            nickname => '(console)',
            me       => 1, # always to me
        ),
        group => undef,
        text  => $text,
    });

    $self->resend_message($message);
    $self->dispatch_message($message);
}

=head1 METHODS

=head2 initialize

This sets up the L<POE::Session> that is used to manage the terminal wheel.

=cut

sub initialize {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self => [ qw( 
                _start 
                got_console_input 
                cli_message
            ) ],
        ],
    );
}

=head2 send_reply

Whenever the bot replies to a message, the reply will be posted to console.

=cut

sub send_reply {
    my ($self, $message, $text) = @_;
    $self->term->put($text);
}

=head2 send_message

Whenever the bot sends a message, it will be displayed if it is a direct message
back to the console or if the group name matches the L</current_group>. All
other messages will be muted.

=cut

sub send_message {
    my ($self, %params) = @_;

    my $text = $params{text};
    $self->term->put($text);
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
