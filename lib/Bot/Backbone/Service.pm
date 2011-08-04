package Bot::Backbone::Service;
use v5.10;
use Moose();
use Bot::Backbone::DispatchSugar();
use Moose::Exporter;
use Moose::Util qw( apply_all_roles );

use Bot::Backbone::Dispatcher;
use Bot::Backbone::Role::Service;

# ABSTRACT: Useful features for services

=head1 SYNOPSIS

  package MyBot::Service::Echo;
  use v5.14; # because newer Perl is cooler than older Perl
  use Bot::Backbone::Service;

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

Implementers of this class are automatically setup with L<Bot::Backbone::Role::Service>.

=head1 SUBROUTINES

=cut

Moose::Exporter->setup_import_methods(
    with_meta => [ qw( dispatcher ) ],
    also      => [ qw( Moose Bot::Backbone::DispatchSugar ) ],
);

=head2 init_meta

Setup the bot package by applying the L<Bot::Backbone::Role::Service> role to the class.

=cut

sub init_meta {
    shift;
    my %args = @_;
    apply_all_roles($args{for_class}, 'Bot::Backbone::Role::Service');
    return Moose->init_meta(@_);
};

=head1 SETUP ROUTINES

=head2 dispatcher

  dispatcher ...;

Setup the default dispatcher for this service. Use of this method will cause the L<Bot::Backbone::Role::Dispatch> role to be applied to the class.

=cut

sub dispatcher($) {
    my ($meta, $dispatcher) = @_;

    apply_all_roles($meta->name, 'Bot::Backbone::Role::Dispatch');

    my $dispatcher_name_attr = $meta->find_attribute('dispatcher_name');
    $dispatcher_name_attr->clone_and_inherit_options(
        default => '<From Bot::Backbone::Service>',
    );

    my $dispatcher_attr = $meta->find_attribute('dispatcher');
    $dispatcher_attr->clone_and_inherit_options(
        default => sub {
            my $dispatcher = Bot::Backbone::Dispatcher->new;
            {
                local $_ = $dispatcher;
                $code->();
            }
            return $dispatcher;
        },
    );
}

1;
