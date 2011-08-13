package Bot::Backbone::Meta::Class::DispatchBuilder;
use Moose::Role;

# ABSTRACT: Metaclass role providing dispatcher setup helps

=head1 DESCRIPTION

This metaclass role is used to help the sugar subroutines setup a dispatcher. That is all. There are no additional services provided here that should be used directly.

=cut

has building_dispatcher => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Dispatcher',
    clearer     => 'no_longer_building_dispatcher',
);

1;
