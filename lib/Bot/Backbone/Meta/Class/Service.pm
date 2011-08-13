package Bot::Backbone::Meta::Class::Service;
use Moose;

extends 'Moose::Meta::Class';
with 'Bot::Backbone::Meta::Class::DispatchBuilder';

# ABSTRACT: Metaclass attached to backbone bot services

=head1 DESCRIPTION

This provides some tools necessary for building a dispatcher. It has no additional services to be used after the service has been setup.

=cut

__PACKAGE__->meta->make_immutable;
