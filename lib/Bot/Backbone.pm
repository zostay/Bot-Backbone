package Bot::Backbone;
use v5.10;
use Moose();
use Bot::Backbone::DispatchSugar();
use Moose::Exporter;

use Bot::Backbone::Meta::Class::Bot;
use Bot::Backbone::Dispatcher;

our $DEBUG = '';
sub debug { warn @_, "\n" if $DEBUG }

# ABSTRACT: Extensible framework for building bots

=head1 SYNOPSIS

  package MyBot;
  use v5.14; # because newer Perl is cooler than older Perl
  use Bot::Backbone;

  use DateTime;
  use AI::MegaHAL;
  use WWW::Wikipedia;

  service chat_bot => (
      service  => 'JabberChat',
      jid      => 'mybot@example.com',
      password => 'secret',
      host     => 'example.com',
  );

  service group_foo => (
      service    => 'GroupChat',
      chat       => 'chat_bot',
      dispatcher => 'group_chat', # defined below
  );

  # This would invoke a service named MyBot::Service::Pastebin
  service pastebin => (
      service  => '.Pastebin',
      chats    => [ 'group_foo' ],
      host     => 'localhost',
      port     => 5000,
  );

  has megahal => (
      is         => 'ro',
      isa        => 'AI::MegaHAL',
      default    => sub { AI::MegaHAL->new },
  );

  has wikipedia => (
      is         => 'ro',
      isa        => 'WWW::Wikipedia',
      default    => sub { WWW::Wikipedia->new },
  );

  dispatcher group_chat => as {
      # Report the bot's time
      command '!time' => respond { DateTime->now->format_cldr('ddd, MMM d, yyyy @ hh:mm:ss') };

      # Basic echo command, with arguments
      command '!echo' => given_parameters { 
          argument echo_this => ( matching => qr/.*/ ); 
      } respond {
          my ($self, $message) = @_; 
          $message->arguments->{echo_this};
      };

      # Include the pastebin commands (whatever they may be)
      dispatch_to 'pastebin';

      # Look for wikiwords in a comment and report the summaries for each
      not_to_me matching qr/\[\[\w+\]\]/ => respond {
          my ($self, $message) = @_;

          my (@wikiwords) = $message->text =~ /\[\[(\w+)\]\]/g;

           map { "$_->[0]: " . $_->[1] }
          grep { defined $_->[1] }
           map { [ $_, $self->wikipedia->search($_) }
              @wikiwords;
      };

      # Return an AI::MegaHAL resopnse for any message address to the bot
      to_me respond {
          my ($self, $message) = @_;
          $self->megahal->do_response($message->text);
      };

      # Finally:
      #  - also: match even if something else already responded
      #  - not_command: but not if a command matched
      #  - not_to_me: but not if addressed to me
      #  - run: run this code, but do not respond
      also not_command not_to_me run { 
          my ($self, $message) = @_;
          $self->megahal->learn($message->text);
      };
  };

  my $bot = MyBot->new;
  $bot->run;

=head1 DESCRIPTION

Bots should be easy to build. Also a bot framework does not need to be tied to a
particular protocol (e.g., IRC, Jabber, etc.). However, most bot tools fail at
either of these. Finally, it should be possible to create generic services that
a bot can consume or share with other bots. This framework aims at solving all
of these.

This framework provides the following tools to this end.

=head2 Services

A service is a generic sub-application that runs within your bot, possibly
independent of the rest. Here are some examples of possible services:

=over

=item Chat Service

Each chat server connects to a chat service. This might be a Jabber server or an
IRC server or even just a local REPL for running commands on the console. A
single bot may have multiple connections to these servers by running more than
one chat service.

=item Channel Service

These will ask a chat service to join a particular room or channel.

=item Direct Message Service

These services are similar to Channel services, but are used to connect to
another individual account or a list of other accounts.

=item Dispatched Service

A dispatched service may provide a group of common commands to the dispatcher.

=item Messaging Service

A messaging service might post messages into a chat to notify others on a
channel of events, or new posts to a blog, etc.

=item External Service

An external service could provide a web server for interaction or connect to a
MQ server to wait for commands or to post commands, etc.

=back

Basically, services are the place for any kind of tool the bot might need.

=head2 Dispatcher

A dispatcher is a collection of predicates paired with run modes. A dispatcher
may be applied to a chat, channel, or direct message service to handle incoming
messages. When a message comes in from the service, each predicate is checked
against that message. The run mode of the first matching predicate is executed
(as well as any C<also> predicates.

Dispatchers are extensible, allowing for new predicates and run mode operations
to be defined as needed.

=head1 SUBROUTINES

=cut

Moose::Exporter->setup_import_methods(
    with_meta => [ qw( dispatcher service ) ],
    also      => [ qw( Moose Bot::Backbone::DispatchSugar ) ],
);

=head2 init_meta

Setup the bot package with L<Bot::Backbone::Meta::Class> as the meta class and L<Bot::Backbone::Bot> as the base class.

=cut

sub init_meta {
    shift;
    return Moose->init_meta(@_, 
        base_class => 'Bot::Backbone::Bot',
        metaclass  => 'Bot::Backbone::Meta::Class::Bot',
    );
}

=head1 SETUP ROUTINES

=head2 service

  service $name => ( ... );

Add a new service configuration.

=cut

sub service($%) {
    my ($meta, $name, %config) = @_;

    $meta->add_service($name, \%config);
}

=head2 dispatcher

  dispatcher $name => ...;

This predicate is provided at the top level and is usually paired with the
L</as> run mode operation, though it could be paired with any of them. This
declares a named dispatcher that can be referred to as the C<dispatcher>
attribute on services that support dispatching.

=cut

sub dispatcher($$) { 
    my ($meta, $name, $code) = @_;

    my $dispatcher = Bot::Backbone::Dispatcher->new;
    {
        $meta->building_dispatcher($dispatcher);
        $code->();
        $meta->no_longer_building_dispatcher;
    }

    debug("add_dispatcher($name, ...)");
    $meta->add_dispatcher($name, $dispatcher);
}

=head1 DISPATCHER PREDICATES

=head2 redispatch_to

  redispatch_to 'service_name';

Given a service name for a service implementing L<Bot::Backbone::Role::Dispatch>, we will ask the dispatcher on that object (if any) to perform dispatch.

=cut

=head2 command

  command $name => ...;

A command predicate matches the very first word found in the incoming message
text. It only matches an exact string and only messages not preceded by
whitespace (unless the message is addressed to the bot, in which case whitespace
is allowed).

=cut

=head2 not_command

  not_command ...;

This is not useful unless paired with the L</also> predicate. This only matches
if no command has been matched so far for the current message.

=cut

# sub not_command($$) { 
#     my ($name, $code) = @_;
#     my $dispatcher = $_;
# 
#     my $new_code = sub {
#         my $message = shift;
#         return $code->($message) unless $message->is_command;
#         return ();
#     };
# 
#     if (defined wantarray) {
#         return $code;
#     }
#     else {
#         $dispatcher->add_predicate($code);
#     }
# }

=head2 given_parameters

  given_parameters { argument $name => %config; ... } ...

This is used in conjunction with C<argument> to define arguments expected to
come next. Each argument is separated by whitespace.

TODO More detail is needed on what can go into C<%config>.

=cut

=head2 matching

  matching $regex => ...

Matches any incoming message matching the given regular expression.

=cut

#sub matching($$) { ... }

=head2 to_me

  to_me ...

Matches messages that are considered directed toward the bot. This may be a
direct message or a channel message prefixed by the bot's name.

=cut

#sub to_me($) { ... }

=head2 not_to_me

  not_to_me ...

This is the opposite of L</to_me>. It matches any message not sent directly to
the bot.

=cut

#sub not_to_me($) { ... }

=head2 dispatch_to

  dispatch_to $service_name;

This is not really a predicate per se, but causes a nested dispatcher provided
by a service to be executed.

=cut

#sub dispatch_to($) { ... }

=head2 also

  also ...;

In general, only the run mode operation for the first matching predicate will be
executed. The C<also> predicate, however, tells the dispatcher to try and match
against it even if the dispatcher has already responded.

=cut

#sub also($) { ... }

=head1 RUN MODE OPERATIONS

=head2 as

  as { ... }

This nests another set of dispatchers inside a predicate. Each set of predicates
defined within will be executed in turn if this run mode oepration is reached.

=cut

=head2 respond

  respond { ... }

If a C<response> is executed, the code ref given will be executed with three
arguments. The first will be a reference to the bot's main object. The second
will be a message object describing the incoming message. The third is the
service that sent the message.

The return value of the executed code ref will be used to respond to the user.
It will be called in list context and all the values returned will be sent to
the user. If an empty list or C<undef> is returned, then no message will be sent
to the user and dispatching will continue as if the predicate had not matched.

=cut

=head2 respond_or_stop

  response_or_stop { ... }

This is identical to L</respond>, except that dispatching ends even if the
return value is an empty list or C<undef>.

=cut

#sub respond_or_stop(&) { ... }

=head2 run

  run { ... }

This will execute the given code ref, passing it the reference to the bot, the
message, and the service as arguments. The return value is ignored.

=cut

#sub run(&) { ... }

1;
