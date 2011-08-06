package Bot::Backbone::Service;
use v5.10;
use Moose();
use Bot::Backbone::DispatchSugar();
use Moose::Exporter;
use Moose::Util qw( ensure_all_roles );

use Bot::Backbone::Dispatcher;
use Bot::Backbone::Role::Service;

# ABSTRACT: Useful features for services

=head1 SYNOPSIS

  package MyBot::Service::Echo;
  use v5.14; # because newer Perl is cooler than older Perl
  use Bot::Backbone::Service;

  with 'Bot::Backbone::Role::Service';

  dispatch as {
      command '!echo' => given_parameters {
          parameter thing => ( match => qr/.+/ );
      } respond by_method 'echo_back';
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
    with_meta => [ qw( service_dispatcher ) ],
    also      => [ qw( Moose Bot::Backbone::DispatchSugar ) ],
);

=head2 init_meta

Setup the bot package by applying the L<Bot::Backbone::Role::Service> role to the class.

=cut

sub init_meta {
    shift;
    Moose->init_meta(@_);
};

=head1 SETUP ROUTINES

=head2 dispatcher

  service_dispatcher ...;

Setup the default dispatcher for this service. Use of this method will cause the L<Bot::Backbone::Role::Dispatch> role to be applied to the class.

=cut

sub service_dispatcher($) {
    my ($meta, $code) = @_;

    ensure_all_roles($meta->name, 'Bot::Backbone::Role::Dispatch');

    my $dispatcher_name_attr = $meta->find_attribute_by_name('dispatcher_name');
    my $new_dispatcher_name_attr = $dispatcher_name_attr->clone_and_inherit_options(
        default => '<From Bot::Backbone::Service>',
    );
    $meta->add_attribute($new_dispatcher_name_attr);

    my $dispatcher_attr = $meta->find_attribute_by_name('dispatcher');
    my $new_dispatcher_attr = $dispatcher_attr->clone_and_inherit_options(
        default => sub {
            my $dispatcher = Bot::Backbone::Dispatcher->new;
            {
                local $_ = $dispatcher;
                $code->();
            }
            return $dispatcher;
        },
    );
    $meta->add_attribute($new_dispatcher_attr);
}

1;
