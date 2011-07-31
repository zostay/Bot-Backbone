package Bot::Backbone::Types;
use v5.10;
use Moose;

use List::MoreUtils qw( all );
use MooseX::Types::Moose qw( ArrayRef ClassName CodeRef HashRef Object );
use MooseX::Types -declare => [ qw(
    EventLoop
    PredicateList
    ServiceList
) ];
use Scalar::Util qw( blessed );

use namespace::autoclean;

# ABSTRACT: The type library for Bot::Backbone

=head1 DESCRIPTION

This is a container for the various types used by L<Bot::Backbone>. It is built
using L<MooseX::Types>.

=head1 TYPES

=head2 EventLoop

This is just an object with a C<run> method.

=cut

subtype EventLoop,
    as ClassName|Object,
    where { $_->can('run') };

=head2 PredicateList

This is an array of code references.

=cut

subtype PredicateList,
    as ArrayRef[CodeRef];

=head2 ServiceList

This is a hash of objects that implement L<Bot::Backbone::Role::Service>.

=cut

class_type 'Bot::Backbone::Role::Service';
subtype ServiceList,
    as HashRef[Object],
    where { all { blessed $_ and $_->does('Bot::Backbone::Role::Service') } values %$_ };

__PACKAGE__->meta->make_immutable;
