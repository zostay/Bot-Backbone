package Bot::Backbone::Types;
use v5.10;
use Moose;

use List::MoreUtils qw( all );
use MooseX::Types::Moose qw( ArrayRef ClassName CodeRef HashRef Object );
use MooseX::Types -declare => [ qw(
    DispatcherType
    EventLoop
    PredicateList
    ServiceList
    VolumeLevel
) ];
use Scalar::Util qw( blessed );

use namespace::autoclean;

# ABSTRACT: The type library for Bot::Backbone

=head1 DESCRIPTION

This is a container for the various types used by L<Bot::Backbone>. It is built
using L<MooseX::Types>.

=head1 TYPES

=head2 DispatcherType

This is an enum with the following values:

    bot
    service

=cut

class_type 'Moose::Meta::Class';
enum DispatcherType, [qw( bot service )];
coerce DispatcherType,
    from 'Moose::Meta::Class',
    via { 
        if    ($_->name->isa('Bot::Backbone::Bot'))                     { 'bot' }
        elsif ($_->name->does('Bot::Backbone::Service::Role::Service')) { 'service' }
        else  { die "unknown meta object $_ in DispatherType coercion" }
    };

=head2 EventLoop

This is just an object with a C<run> method.

=cut

subtype EventLoop,
    as ClassName|Object,
    where { $_->can('run') };

=head2 PredicateList

This is an array of code references.

=cut

class_type 'Bot::Backbone::Dispatcher::Predicate';
subtype PredicateList,
    as ArrayRef['Bot::Backbone::Dispatcher::Predicate'];

=head2 ServiceList

This is a hash of objects that implement L<Bot::Backbone::Service::Role::Service>.

=cut

class_type 'Bot::Backbone::Service::Role::Service';
subtype ServiceList,
    as HashRef[Object],
    where { all { blessed $_ and $_->does('Bot::Backbone::Service::Role::Service') } values %$_ };

=head2 VolumeLevel

This is an enumeration of possible volume levels for chats. It must be one of the following:

    shout
    spoken
    whisper

=cut

enum VolumeLevel, [ qw( shout spoken whisper ) ];

__PACKAGE__->meta->make_immutable;
