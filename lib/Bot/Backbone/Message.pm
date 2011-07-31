package Bot::Backbone::Message;
use v5.10;
use Moose;

use Bot::Backbone::Identity;

# ABSTRACT: Describes a message or response

=head1 SYNOPSIS

  # E.g., passed in to dispatcher predicates
  my $message = ...;

  say $message->from->nickname, ' says, "', $message->text, '"';

  my $chatroom = $message->group;

=head1 ATTRIBUTES

=head2 chat

This is the L<Bot::Backbone::Role::Chat> chat engine where the message
originated.

=cut

has chat => (
    is          => 'ro',
    does        => 'Bot::Backbone::Role::Chat',
    required    => 1,
    weak_ref    => 1,
);

=head2 from

This is the L<Bot::Backbone::Identity> representing the user sending the
message.

=cut

has from => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Identity',
    required    => 1,
);

=head2 to

This is C<undef> or the L<Bot::Backbone::Identity> representing hte user the
message is directed toward. If sent to a room or if this is a broadcast message,
this will be C<undef>.

A message to a room may also be to a specific person, this may show that as
well.

=cut

has to => (
    is          => 'rw',
    isa         => 'Maybe[Bot::Backbone::Identity]',
    required    => 1,
);

=head2 group

This is the name of the chat room.

=cut

has group => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
);

=head2 text

This is the message that was sent.

=cut

has text => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

=head2 flags

These are flags associated with the message. These may be used by dispatcher to
make notes about how the message has been dispatched or identifying features of
the message.

See L<add_flag>, L<add_flags>, L<remove_flag>, L<remove_flags>, L<has_flag>, and
L<has_flags>.

=cut

has flags => (
    is          => 'ro',
    isa         => 'HashRef[Bool]',
    required    => 1,
    default     => sub { +{} },
);

=head2 bookmarks

When processing a dispatcher, the predicates consume parts of the message in the
process. This allows us to keep a stack of pass message parts in case the
predicate ultimately fails.

=cut

has bookmarks => (
    is          => 'ro',
    isa         => 'ArrayRef[Bot::Backbone::Message]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        _set_bookmark     => 'push',
        _restore_bookmark => 'pop',
    },
);

=head2 parameters

These are parameters assoeciated with the message created by the dispatcher
predicates while processing the message.

=cut

has parameters => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        set_parameter => 'set',
        get_parameter => 'get',
    },
);

=head2 is_group

Returns true if this message happened in a chat group/room/channel.

=head2 is_direct

Returns true if this message was sent directly to the receipient.

=cut

sub is_group  { defined shift->group }
sub is_direct { not defined shift->group }

=head2 add_flag

=head2 add_flags

  $message->add_flag('foo');
  $message->add_flags(qw( bar baz ));

Set a flag on this message.

=head2 remove_flag

=head2 remove_flags

  $message->remove_flag('foo');
  $message->remove_flags(qw( bar baz ));

Unsets a flag on this message.

=head2 has_flag

=head2 has_flags

  $message->has_flag('foo');
  $message->has_flags(qw( bar baz ));

Returns true if all the flags passed are set. Returns false if any of the flags
named are not set.

=cut

sub add_flag     { shift->flags->{$_} = 1 for @_ } 
sub add_flags    { shift->flags->{$_} = 1 for @_ }
sub remove_flag  { delete shift->flags->{$_} for @_ }
sub remove_flags { delete shift->flags->{$_} for @_ }
sub has_flag     { all { shift->flags->{$_} } @_ }
sub has_flags    { all { shift->flags->{$_} } @_ }

=head2 set_bookmark

  $message->set_bookmark;

Avoid using this method. See L</set_bookmark_do>.

Saves the current message in the bookmarks stack.

=cut

sub set_bookmark {
    my $self = shift;
    my $bookmark = Bot::Backbone::Message->new(
        chat  => $self->chat,
        to    => $self->to,
        from  => $self->from,
        group => $self->group,
        text  => $self->text,
    );
    $self->_set_bookmark($bookmark);
}

=head2 restore_bookark

  $mesage->restore_bookmark;

Avoid using this method. See L</set_bookmark_do>.

Restores the bookmark on the top of the bookmarks stack. The L</to>, L</from>,
L</group>, and L</text> are restored. All other attribute modifications will
stick.

=cut

sub restore_bookmark {
    my $self = shift;
    my $bookmark = $self->_restore_bookmark;
    $self->to($bookmark->to);
    $self->from($bookmark->from);
    $self->group($bookmark->group);
    $self->text($bookmark->text);
}

=head2 set_bookmark_do

  $message->set_bookmark_do(sub {
      ...
  });

Saves the current message on the top of the stack using L</set_bookmark>. Then,
it runs the given code. Afterwards, any modifications to the message will be
restored to the original using L</restore_bookmark>.

=cut

sub set_bookmark_do {
    my ($self, $code) = @_;
    $self->set_bookmark;
    $code->();
    $self->restore_bookmark;
}

=head2 match_next

  my $value = $message->match_next(qr{bar[rz]});

Given a regular expression or string, matches that against the start of the
message and strips off the match. It returns the match if the match is
successful or returns C<undef>.

=cut

sub match_next {
    my ($self, $regex) = @_;

    my $text = $self->text;
    if ($text =~ s/^($regex)\s*//) {
        my $value = $1;
        $self->text($text);
        return $value;
    }

    return;
}

=head2 reply

  $message->reply('blah blah blah');

Sends a reply back to the entity sending the message or the group that sent it,
using the chat service that created the message.

=cut

sub reply {
    my ($self, $text) = @_;
    $self->chat->send_reply($self, $text);
}

__PACKAGE__->meta->make_immutable;
