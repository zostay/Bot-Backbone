package Bot::Backbone::Meta::Class::Service;

use Moose;

extends 'Moose::Meta::Class';
with 'Bot::Backbone::Meta::Class::DispatchBuilder';

# ABSTRACT: Metaclass attached to backbone bot services

=head1 DESCRIPTION

This provides some tools necessary for building a dispatcher. It also lists all the additional roles that should be applied to a bot using this service.

=head1 ATTRIBUTES

=head2 bot_roles

This is a list of packages that will be applied as roles to the bot when this service is configured.

=cut

has bot_roles => (
    is          => 'rw',
    isa         => 'ArrayRef[ClassName]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        'add_bot_roles' => 'push',
        'all_bot_roles' => 'elements',
        'has_bot_roles' => 'count',
    },
);

__PACKAGE__->meta->make_immutable;
