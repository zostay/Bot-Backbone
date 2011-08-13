package Bot::Backbone::Identity;
use v5.10;
use Moose;

# ABSTRACT: Describes an account sending or receiving a message

=head1 SYNOPSIS

  my $account = Bot::Backbone::Identity->new(
      username => $username,
      nickname => $nickname,
  );

=head1 DESCRIPTION

Holds username and display name information for a chat account.

=head1 ATTRIBUTES

=head2 username

This is the protocol specific username.

=cut

has username => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

=head2 nickname

This is the display name for the account.

=cut

has nickname => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_nickname',
);

=head2 me

This is a boolean value that should be set to true if this identity identifies the robot itself. 

And, by the way, the accessor for this is named C<is_me>.

=cut

has me  => (
    isa         => 'Bool',
    accessor    => 'is_me',
    required    => 1,
    default     => 0,
);


__PACKAGE__->meta->make_immutable;
