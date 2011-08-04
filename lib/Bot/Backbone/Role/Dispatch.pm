package Bot::Backbone::Role::Dispatch;
use v5.10;
use Moose::Role;

use namespace::autoclean;

# ABSTRACT: Role for services that can perform dispatch

=head1 DESCRIPTION

Any service that can use a dispatcher employ this role to make that happen.

=head1 ATTRIBUTES

=head2 dispatcher_name

  dispatcher default => as {
      ...
  };

  service some_service => (
      service    => '=My::Service',
      dispatcher => 'default',
  );

During construction, this is named C<dispatcher>. This is the name of the
dispatcher to load from the bot during initialization.

=cut

has dispatcher_name => (
    is          => 'ro',
    isa         => 'Str',
    init_arg    => 'dispatcher',
    predicate   => 'has_dispatcher',
);

=head2 dispatcher

  my $dispatcher = $service->dispatcher;

Do not set this attribute. It will be loaded using the L</dispatcher_name>
automatically. It returns a L<Bot::Bakcbone::Dispatcher> object to use for
dispatch.

A C<dispatch_message> method is also delegated to the dispatcher.

=cut

has dispatcher => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Dispatcher',
    init_arg    => undef,
    lazy_build  => 1,

    # lazy_build implies (predicate => has_dispatcher)
    predicate   => 'has_setup_the_dispatcher', 
);

sub _build_dispatcher {
    my $self = shift;
    $self->bot->meta->dispatchers->{ $self->dispatcher_name };
}

=head1 METHODS

=head2 dispatch_message

  $service->dispatch_message($message);

If the service has a dispatcher configured, this will call the L<Bot::Backbone::Dispatcher/dispatch_message> method on the dispatcher.

=cut

sub dispatch_message {
    my ($self, $message) = @_;

    if ($self->has_dispatcher) {
        $self->dispatcher->dispatch_message($self, $message);
    }
}

1;
