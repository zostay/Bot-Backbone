package Bot::Backbone::Role::GroupJoiner;
use v5.10;
use Moose::Role;

# ABSTRACT: Chat services that can join a chat group

=head1 DESCRIPTION

This is only useful to chat services (probably).

=head1 REQUIRED METHODS

=head2 join_group

  $chat->join_group('foo');

Given the name of a group to join, this performs the operations required to join
the group.

=cut

requires 'join_group';

1;
