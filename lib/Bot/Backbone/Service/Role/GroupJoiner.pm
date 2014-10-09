package Bot::Backbone::Service::Role::GroupJoiner;

use v5.10;
use Moose::Role;

# ABSTRACT: Chat services that can join a chat group

=head1 DESCRIPTION

This is only useful to chat services (probably).

=head1 REQUIRED METHODS

=head2 join_group

  $chat->join_group(\%options);

This method will cause the service to join the group described by the options in
the way described by the options. Generally, the options will include (but are
not limited to and all of these might not be supported):

=over

=item group

This is the name of the group to join. Every implementation must support this
option.

=item nickname

This is the nickname to give the bot within this group.

=back

=cut

requires 'join_group';

1;
