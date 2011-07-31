package Bot::Backbone::Role::Service;
use Moose::Role;

# ABSTRACT: Role implemented by all bot services

=head1 DESCRIPTION

All bot services must implement this role.

=head1 ATTRIBUTES

=head2 name

This is the name of the service configured for the bot. It will be unique for
that bot.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 bot

This is a back link to the L<Bot::Backbone::Bot> that owns this service.

=cut

has bot => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Bot',
    required    => 1,
    weak_ref    => 1,
);

=head1 REQUIRED METHODS

=head2 initialize

This method will be called after construction, but before the event loop starts.
This is where the service should initalize connections, prepare to receive
messages, etc.

It will be passed no arguments.

=cut

requires qw( initialize );

=head1 METHODS

=head2 shutdown

This method will be called just before the bot destroys the service and exits.
If called, your service is expected to terminate any pending jobs, kill any
child processes, and clean up so that the bot will exit cleanly.

A default implementation is provided, which does nothing.

=cut

sub shutdown { }

1;
