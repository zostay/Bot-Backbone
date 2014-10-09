package Bot::Backbone::Service::Role::Responder;

use v5.10;
use Moose::Role;

# ABSTRACT: A role for services that respond to messages

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

This role will provide implementations of C<send_message> and C<send_reply> methods appropriate if you build a service that just replies to input passed to it.

=head1 METHODS

=head2 send_reply

  $service->send_reply($message, \%options);

This will send a reply back to the given message.

=cut

sub send_reply {
    my ($self, $message, $options) = @_;

    $self->send_message({
        chat  => $message->chat,
        group => $message->group,
        to    => $message->from->username,
        %$options,
    });
}

=head2 send_message

  $service->send_message({
      chat => $chat,
      %options,
  });

This works just like your typical C<send_message> method, but it requires a C<chat> argument to tell it where to send the message. This is mostly useful if all you need to do is reply to whatever message was received from whichever source it was received from.

=cut

sub send_message {
    my ($self, $options) = @_;

    my $chat = delete $options->{chat};

    $chat->send_message($options);
}

1;
