package Bot::Backbone::Meta::Class::Bot;

use Moose;

extends 'Moose::Meta::Class';
with 'Bot::Backbone::Meta::Class::DispatchBuilder';

# ABSTRACT: Metaclass attached to backbone bots

=head1 SYNOPSIS

  my $bot = My::Bot->new;

  # Introspect send policies
  for my $name ($bot->meta->list_send_policies) {
      my $policy = $bot->meta->send_policies->{$name};
      say Dumper($policy);
  }

  # Introspect services
  for my $name ($bot->meta->list_services) {
      my $service = $bot->meta->services->{$name};
      say Dumper($service);
  }

  # Introspect a dispatcher
  say Dumper($bot->meta->dispatcher->{default});

=head1 DESCRIPTION

This provides the metaclass features needed for each bot and allow some introspection of the bot's structure.

=head1 EXTENDS

L<Moose::Meta::Class>

=head1 ATTRIBUTES 

=head2 send_policies

This is a has of send policy configurations.

=cut

has send_policies => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        add_send_policy    => 'set',
        list_send_policies => 'keys',
    },
);

=head2 services

This is a hash of service configurations.

=cut

has services => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        add_service   => 'set',
        list_services => 'keys',
    },
);

=head2 dispatcher

This is a hash of dispatchers.

=cut

has dispatchers => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        add_dispatcher => 'set',
    },
);

__PACKAGE__->meta->make_immutable;
