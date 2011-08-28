package Bot::Backbone::Service::Role::Sender;
use Moose::Role;

# ABSTRACT: Marks a service as one that may send messages

=head1 DESCRIPTION

A sender is a service that provides C<send_message> and C<send_reply> methods.

=head1 REQUIRED METHODS

=head2 send_reply

  $chat->send_reply($message, \%options);

This is often just a wrapper provided around C<send_message>.  The first
argument is the original L<Bot::Backbone::Message> that this is in reply to. 

The second argument is the options to describe the reply being sent.

=head2 send_message

  $chat->send_message(%options);

The options describe the to send.

=cut

requires qw( send_message send_reply );

1;
