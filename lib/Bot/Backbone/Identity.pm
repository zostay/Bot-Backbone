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

__PACKAGE__->meta->make_immutable;
