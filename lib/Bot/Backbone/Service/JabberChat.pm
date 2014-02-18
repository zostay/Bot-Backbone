package Bot::Backbone::Service::JabberChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::BareMetalChat
    Bot::Backbone::Service::Role::GroupJoiner
);

use Bot::Backbone::Message;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::MUC;

# ABSTRACT: Connect and chat with a Jabber server

=head1 SYNOPSIS

  service jabber_chat => (
      service  => 'JabberChat',
      username => 'bot',
      domain   => 'example.com',
      resource => 'coolbot',
      password => 'secret',
  );

=head1 DESCRIPTION

Connects to and chats directly with other users and chat groups using a Jabber
(XMPP) server.

=head1 ATTRIBUTES

=head2 username

This is the username (or localpart in XMPP parlance) to use when connecting to the Jabber server. E.g., if your bot's login name is C<bot@example.com>, the username is "bot".

=cut

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 domain

This is the domain (or domainpart) to use when connecting to the Jabber server. E.g., f your bot's login mame is C<bot@example.com>, the domain is "example.com".

=cut

has domain => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 group_domain

This is the domain to contact for group chats. Normally, this is the same as L</domain>, but with "conference." tacked on at the front.

=cut

has group_domain => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return join '.', 'conference', $self->domain
    },
);

=head2 resource

This is a the resourcepart of your login name. You may not really care what this is set to, but it shows up in some chat clients. By default it will be set to "backbone-bot", but you can set it something else, if you like.

=cut

has resource => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'backbone-bot',
);

=head2 password

This is the password to use when logging in to the Jabber server.

=cut

has password => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 host

This is the host to contact to login. If not set, the L</domain> will be used.

If you run your bot on Google Talk, you will probably want this set to L<talk.google.com>.

=cut

has host => (
    is          => 'ro',
    isa         => 'Str',
);

=head2 port

This is the port to connect. If you do not set it to anything, the default of 5222 will be used.

=cut

has port => (
    is          => 'ro',
    isa         => 'Int',
);

=head2 connection_args

These are additional connection arguments to pass to the XMPP connector. See
L<AnyEvent::XMPP::Connection> for a list of available options.

=cut

has connection_args => (
    is          => 'ro',
    isa         => 'HashRef',
);

=head2 xmpp_client

This is the XMPP client object for organizing connections.

=cut

has xmpp_client => (
    is          => 'ro',
    isa         => 'AnyEvent::XMPP::Client',
    required    => 1,
    lazy_build  => 1,
);

sub _build_xmpp_client { AnyEvent::XMPP::Client->new }

=head2 xmpp_disco

This is the XMPP discovery extension helper.

=cut

has xmpp_disco => (
    is          => 'ro',
    isa         => 'AnyEvent::XMPP::Ext::Disco',
    required    => 1,
    lazy_build  => 1,
);

sub _build_xmpp_disco { AnyEvent::XMPP::Ext::Disco->new }

=head2 xmpp_muc

This is the XMPP multi-user chat extension helper.

=cut

has xmpp_muc => (
    is          => 'ro',
    isa         => 'AnyEvent::XMPP::Ext::MUC',
    required    => 1,
    lazy_build  => 1,
);

sub _build_xmpp_muc {
    my $self = shift;
    AnyEvent::XMPP::Ext::MUC->new( disco => $self->xmpp_disco );
}

=head2 session_ready

Once the connection has been made and is ready to start sending and receiving
messages, this will be set to true.

=cut

has session_ready => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

=head2 group_options

This is a list of multi-user chat groups the bot has joined or intends to join
once L</session_ready> becomes true.

=cut

has group_options => (
    is          => 'rw',
    isa         => 'ArrayRef[HashRef]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        all_group_options => 'elements',
        add_group_options => 'push',
    },
);

=head1 METHODS

=head2 jid

This assembles a full JID (Jabber ID) using the L</username>, L</domain>, and
L</resource>.

=cut

sub jid {
    my $self = shift;
    return $self->username
         . '@' . $self->domain
         . '/' . $self->resource;
}

=head2 group_jid

  my $group_jid = $chat->group_jid('bar');

Given a short group name, returns the bare JID for that group.

=cut

sub group_jid {
    my ($self, $name) = @_;
    return $name . '@' . $self->group_domain,
}

=head2 xmpp_account

Returns the XMPP account object.

=cut

sub xmpp_account {
    my $self = shift;
    return $self->xmpp_client->get_account($self->jid);
}

=head2 xmpp_connection

Returns teh XMPP connection object.

=cut

sub xmpp_connection {
    my $self = shift;
    return $self->xmpp_account->connection;
}

=head2 xmpp_room

  my $xmpp_room = $chat->xmpp_room('qux');

Returns the XMPP room object for the named room.

=cut

sub xmpp_room {
    my ($self, $name) = @_;
    return $self->xmpp_muc->get_room(
        $self->xmpp_connection,
        $self->group_jid($name),
    );
}

=head2 xmpp_contact

  my $xmpp_contact = $chat->xmpp_contact('user@example.com/blah');

Given a JID, returns the XMPP contact object for that user.

=cut

sub xmpp_contact {
    my ($self, $name) = @_;
    return $self->xmpp_connection->get_roster->get_contact($name);
}

=head2 initialize

Connects to the Jabber server and registers the events for receiving messages
from it.

=cut

sub initialize {
    my $self = shift;

    # Make the connection
    $self->xmpp_client->add_account(
        $self->jid,
        $self->password,
        $self->host,
        $self->port,
        $self->connection_args,
    );

    # TODO These messages should really verify that they are intended for us by
    # checking that the account passed is the account expected. Otherwise, if
    # someone were to setup multiple JabberChat connections using the same
    # client (which we ought to expect), all JabberChats will react to all
    # connections simultaneously... which is bad.

    # Register the IM message callback
    $self->xmpp_client->reg_cb(
        session_ready => sub { 

            # Register the extensions we use
            $self->xmpp_connection->add_extension($self->xmpp_disco);
            $self->xmpp_connection->add_extension($self->xmpp_muc);

            $self->session_ready(1);
            $self->_join_pending_groups;
        },
        message       => sub { $self->got_direct_message(@_) },

        # TODO Need more robust logging
        error         => sub { 
            my ($client, $account, $error) = @_;
            warn "XMPP Error: ", $error->string, "\n";
        },
    );

    # Register the group message callback
    $self->xmpp_muc->reg_cb(
        message => sub { $self->got_group_message(@_) },
    );

    # Start the client
    $self->xmpp_client->start;
}

=head2 join_group

Asks to join the named multi-user chat groups on the Jabber server. If L</session_ready> is false, the chat service will only record a desire to join the group. No actual join will take place. Once the session becomes ready, all pending groups will be joined.

If the session is ready already, then the group will be joined immediately.

=cut

sub _join_pending_groups {
    my $self = shift;

    # Perform join from either the params or list of group options
    my @pending_group_options;
    if (@_) {
        @pending_group_options = @_;
    }
    else {
        @pending_group_options = $self->all_group_options;
    }

    my $account = $self->xmpp_account;
    my $conn    = $self->xmpp_connection;

    # Join each group requested
    for my $group_options (@pending_group_options) {
        my $nickname = $account->nickname_for_jid($self->jid);
        $nickname = $group_options->{nickname}
            if defined $group_options->{nickname};

        $self->xmpp_muc->join_room(
            $conn,
            $self->group_jid($group_options->{group}),
            $nickname,
        );
    }
}

sub join_group {
    my ($self, $options) = @_;

    $self->add_group_options($options);
    $self->_join_pending_groups($options) if $self->session_ready;
}

=head1 EVENT HANDLERS

=head2 got_direct_message

Whenever someone sends the bot a direct message throught eh Jabber server, this
handler is called. It builds a L<Bot::Backbone::Message> and then passes that
message on the associated chat consumers and the dispatcher.

=cut

sub got_direct_message {
    my ($self, $client, $account, $xmpp_message) = @_;

    return unless defined $xmpp_message->body;

    my $to_contact   = $self->xmpp_contact($xmpp_message->to);
    my $from_contact = $self->xmpp_contact($xmpp_message->from);

    my $message = Bot::Backbone::Message->new({
        chat => $self,
        from => Bot::Backbone::Identity->new(
            username => $from_contact->jid,
            nickname => $from_contact->name // $from_contact->jid,
            me       => $from_contact->is_me,
        ),
        to   => Bot::Backbone::Identity->new(
            username => $to_contact->jid,
            nickname => $to_contact->name // $to_contact->jid,
            me       => $to_contact->is_me,
        ),
        group => undef,
        text  => $xmpp_message->body,
    });

    $self->resend_message($message);
    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}

=head2 is_to_me

  my $bool = $self->is_to_me($user, $text);

Given the user that identifies the bot in a group chat and text that was just sent to the chat, this detects if the message was directed at the bot. Normally, this includes messages that start with the following:

  nick: ...
  nick, ...
  nick- ...

It also includes suffix references like this:

  ..., nick.
  ..., nick

and infix references like this:

  ..., nick, ...

If you want something different, you may subclass service and override this method.

=cut

sub is_to_me {
    my ($self, $me_user, $text) = @_;

    my $me_nick = $me_user->nick;
    return scalar $text =~ s/^ $me_nick \s* [:,\-]
                            |  , \s* $me_nick [.]? $
                            |  , \s* $me_nick \s* , 
                            //x;
}

=head2 got_group_message

Whenever someone posts to a conference room that the bot has joined, this method
will be called to create a L<Bot::Backbone::Message> and pass that message on to
chat consumers and the dispatcher.

=cut

sub got_group_message {
    my ($self, $client, $room, $xmpp_message, $is_echo) = @_;

    # Ignore messages echoed back to the bot
    return if $is_echo;

    # Ignore messages from the room itself
    return unless defined $xmpp_message->from_nick;

    # Ignore delayed messages (e.g., received as a replay of recent room discussion)
    return if $xmpp_message->is_delayed;

    # Figure out which group this is
    my $group_domain = $self->group_domain;
    my $group        =  $room->jid;
       $group        =~ s/\@$group_domain$//;

    # Figure out who sent this message
    my $from_user = $room->get_user($xmpp_message->from_nick);

    # Prefer the real JID as the username
    my $from_username = $from_user->real_jid // $from_user->in_room_jid;
    my $from_nickname = $from_user->nick;

    # This will never actually be true right now, but in case I decide
    # handling echos is a good thing someday...
    my $me_user = $room->get_me;
    my $is_me   = $me_user->in_room_jid eq $from_user->in_room_jid;

    # See if the group message is talking to us...
    my $to_identity;
    my $text    = $xmpp_message->body;
    if ($self->is_to_me($me_user, $text)) {
        $to_identity = Bot::Backbone::Identity->new(
            username => $me_user->real_jid // $me_user->in_room_jid,
            nickname => $me_user->nick,
            me       => 1,
        );
    }

    # Is this a message sent privately within the room?
    my $private = $xmpp_message->is_private;
    my $volume  = $private ? 'whisper' : 'spoken';

    # Build the message
    my $message = Bot::Backbone::Message->new({
        chat => $self,
        from => Bot::Backbone::Identity->new(
            username => $from_username,
            nickname => $from_nickname,
            me       => $is_me,
        ),
        to     => $to_identity,
        group  => $group,
        text   => $text,
        volume => $volume,
    });

    # Pass it on
    $self->resend_message($message);
    $self->dispatch_message($message);
}

=head2 send_message

Sends a message to the Jabber server for a direct chat or group.

=cut

sub send_message {
    my ($self, $params) = @_;

    my $to    = $params->{to};
    my $group = $params->{group};
    my $text  = $params->{text};
    my $contact;

    # Select a group to receive the message
    if (defined $group) {
        $contact = $self->xmpp_room($group);
    }

    # Select a contect to receive the message
    else {
        $contact = $self->xmpp_contact($to);
    }

    unless (defined $contact) {
        Carp::carp("JabberChat: no contact found for $to/$group to send $text\n");
        return;
    }

    $contact->make_message(body => $text)->send;
}

__PACKAGE__->meta->make_immutable;
