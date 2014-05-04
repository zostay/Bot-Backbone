package Bot::Backbone::Service;
use v5.10;
use Moose();
use Bot::Backbone::DispatchSugar();
use Moose::Exporter;
use Moose::Util qw( ensure_all_roles );
use Class::Load;

use Bot::Backbone::Meta::Class::Service;
use Bot::Backbone::Dispatcher;
use Bot::Backbone::Service::Role::Service;

# ABSTRACT: Useful features for services

=head1 SYNOPSIS

  package MyBot::Service::Echo;
  use v5.14; # because newer Perl is cooler than older Perl
  use Bot::Backbone::Service;

  with qw(
      Bot::Backbone::Service::Role::Service
      Bot::Backbone::Service::Role::Responder
  );

  # Instead of Bot::Backbone::Service::Role::Responder, you may prefer to
  # apply the Bot::Backbone::Service::Role::ChatConsumer role instead. It
  # really depends on if this module will be used across multiple chats or
  # needs to be tied to a specific chat.

  service_dispatcher as {
      command '!echo' => given_parameters {
          parameter thing => ( match => qr/.+/ );
      } respond_by_method 'echo_back';
  };

  sub echo_back {
      my ($self, $message) = @_;
      return $message->parameters->{thing};
  }

  __PACKAGE__->meta->make_immutable; # very good idea

=head1 DESCRIPTION

This is a Moose-replacement for bot backbone services. It provides a similar set of features to a service class as are provided to bot classes by L<Bot::Backbone>.

=head1 SUBROUTINES

=cut

Moose::Exporter->setup_import_methods(
    with_meta => [ qw( service_dispatcher with_bot_roles ) ],
    also      => [ qw( Moose Bot::Backbone::DispatchSugar ) ],
);

=head2 init_meta

Setup the bot package by applying the L<Bot::Backbone::Service::Role::Service> role to the class.

=cut

sub init_meta {
    shift;
    Moose->init_meta(@_, 
        metaclass => 'Bot::Backbone::Meta::Class::Service',
    );
};

=head1 SETUP ROUTINES

=head2 with_bot_roles

  with_bot_roles ...;

Similar to C<with> provided by L<Moose>, this defines a list of roles that should be applied to the bot that uses this service.

=cut

sub with_bot_roles {
    my ($meta, @roles) = @_;
    Class::Load::load_class($_) for @roles;
    $meta->add_bot_roles(@roles);
}

=head2 service_dispatcher

  service_dispatcher ...;

Setup the default dispatcher for this service. Use of this method will cause the L<Bot::Backbone::Service::Role::Dispatch> role to be applied to the class.

=cut

sub service_dispatcher($) {
    my ($meta, $code) = @_;

    ensure_all_roles($meta->name, 'Bot::Backbone::Service::Role::Dispatch');

    $meta->dispatch_builder(sub {
        my $dispatcher = Bot::Backbone::Dispatcher->new;
        {
            $meta->building_dispatcher($dispatcher);
            $code->();
            $meta->no_longer_building_dispatcher,
        }
        return $dispatcher;
    });
}

=head1 DISPATCHER PREDICATES

This exports all the same dispatcher predicates as L<Bot::Backbone>.

=over

=item *

C<redispatch_to>

=item *

C<command>

=item *

C<not_command>

=item *

C<given_parameters> (and C<parameter>)

=item *

C<to_me>

=item *

C<not_to_me>

=item *

C<shouted>

=item *

C<spoken>

=item *

C<whispered>

=item *

C<also>

=back

=head1 RUN MODE OPERATIONS

This exports all the same run mode operations as L<Bot::Backbone>.

=over

=item *

C<as>

=item *

C<respond>. This run mode operation will be passed the service object as the first argument, rather than that bot object.

=item *

C<respond_with_method>. As stated for C<respond>, the first argument is the service object. The method is also a method defined within the current service package rather than the bot.

=item *

C<respond_with_bot_method>. This is similar to C<respond_with_method>, but instead of calling a method within the service, it will call a method directly on the bot to which the service has been added.

=item *

C<run_this>. This run mode operation will be passed the service object as the first argument, rather than that bot object.

=item *

C<run_this_method>. As stated for C<respond>, the first argument is the service object. The method is also a method defined within the current service package rather than the bot.

=item *

C<run_this_bot_method>. This is similar to C<run_this_method>, but results in a call to a method on the bot object rather than on the service.

=back

=cut

1;
