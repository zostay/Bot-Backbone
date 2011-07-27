package Bot::Backbone::Service::JabberChat;
use v5.10;
use Moose;

with qw(
    Bot::Backbone::Role::Service
    Bot::Backbone::Role::Dispatch
    Bot::Backbone::Role::Chat
    Bot::Backbone::Role::GroupJoiner
);

use Bot::Backbone::Message;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::MUC;

has xmpp_client => (
    is          => 'ro',
    isa         => 'AnyEvent::XMPP::Client',
    required    => 1,
    lazy_build  => 1,
);

sub _build_xmpp_client { AnyEvent::XMPP::Client->new( debug => 1 ) }

has xmpp_disco => (
    is          => 'ro',
    isa         => 'AnyEvent::XMPP::Ext::Disco',
    required    => 1,
    lazy_build  => 1,
);

sub _build_xmpp_disco { AnyEvent::XMPP::Ext::Disco->new }

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

has username => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has domain => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has group_domain => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return join '.', 'conference', $self->jid
    },
);

has resource => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has password => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has host => (
    is          => 'ro',
    isa         => 'Str',
);

has port => (
    is          => 'ro',
    isa         => 'Int',
);

has connection_args => (
    is          => 'ro',
    isa         => 'HashRef',
);

has session_ready => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has group_names => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        all_group_names => 'elements',
        add_group_name  => 'push',
    },
);

sub jid {
    my $self = shift;
    return $self->username
         . '@' . $self->domain
         . '/' . $self->resource;
}

sub group_jid {
    my ($self, $name) = @_;
    return $name . '@' . $self->conference_domain,
}

sub xmpp_account {
    my $self = shift;
    return $self->xmpp_client->get_account($self->jid);
}

sub xmpp_connection {
    my $self = shift;
    return $self->xmpp_account->connection;
}

sub xmpp_room {
    my ($self, $name) = @_;
    return $self->xmpp_muc->get_room(
        $self->xmpp_connection,
        $self->group_jid($name),
    );
}

sub xmpp_contact {
    my ($self, $name) = @_;
    return $self->xmpp_connection->get_roster->get_contact($name);
}

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

sub _join_pending_groups {
    my $self = shift;

    # Perform join from either the params or list of group names
    my @pending_group_names;
    if (@_) {
        @pending_group_names = @_;
    }
    else {
        @pending_group_names = $self->all_group_names;
    }

    my $account = $self->xmpp_account;
    my $conn    = $self->xmpp_connection;

    # Join each group requested
    for my $group_name (@pending_group_names) {
        $self->xmpp_muc->join_room(
            $conn,
            $self->group_jid($group_name),
            $account->nickname_for_jid($self->jid),
        );
    }
}

sub join_group {
    my ($self, $name) = @_;

    $self->add_group_name($name);
    $self->_join_pending_groups($name) if $self->session_ready;
}

sub got_direct_message {
    my ($self, $client, $account, $xmpp_message) = @_;

    my $to_contact   = $self->xmpp_contact($xmpp_message->to);
    my $from_contact = $self->xmpp_contact($xmpp_message->from);

    my $message = Bot::Backbone::Message->new({
        chat => $self,
        from => Bot::Backbone::Identity->new(
            username => $from_contact->jid,
            nickname => $from_contact->name // $from_contact->jid,
        ),
        to   => Bot::Backbone::Identity->new(
            username => $to_contact->jid,
            nickname => $to_contact->name // $to_contact->jid,
        ),
        group => undef,
        text  => $xmpp_message->body,
    });

    $self->resend_message($message);
    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}

sub got_group_message {
    my ($self, $client, $room, $xmpp_message, $is_echo) = @_;

    return if $is_echo;

    my $group_domain = $self->group_domain;
    #my $to_contact   =  $self->xmpp_contact($xmpp_message->to);
    my $from_contact =  $self->xmpp_contact($xmpp_message->from);
    my $group        =  $room->jid;
       $group        =~ s/\@$group_domain$//;

    my $message = Bot::Backbone::Message->new({
        chat => $self,
        from => Bot::Backbone::Identity->new(
            username => $from_contact->jid,
            nickname => $from_contact->name // $from_contact->jid,
        ),
        to   => Bot::Backbone::Identity->new(
            username => '(room)',
            nickname => '(room)',
        ),
        group => $group,
        text  => $xmpp_message->body,
    });

    $self->resend_message($message);
    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}

sub send_reply {
    my ($self, $message, $text) = @_;

    $self->send_message(
        group => $message->group,
        to    => $message->from->username,
        text  => $text,
    );
}

sub send_message {
    my ($self, %params) = @_;

    my $to    = $params{to};
    my $group = $params{group};
    my $text  = $params{text};
    my $contact;

    # Select a group to receive the message
    if (defined $group) {
        $contact = $self->xmpp_room($group);
    }

    # Select a contect to receive the message
    else {
        $contact = $self->xmpp_contact($to);
    }

    $contact->make_message(body => $text)->send;
}

sub shutdown { }

__PACKAGE__->meta->make_immutable;
