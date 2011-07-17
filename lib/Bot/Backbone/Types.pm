package Bot::Backbone::Types;
use v5.10;
use Moose;

use List::MoreUtils qw( all );
use MooseX::Types::Moose qw( ArrayRef CodeRef Object );
use MooseX::Types -declare => [ qw(
    PredicateList
    ServiceList
) ];
use Scalar::Util qw( blessed );

use namespace::autoclean;

class_type 'Bot::Backbone::Role::Service';
subtype ServiceList,
    as ArrayRef[Object],
    where { all { blessed $_ and $_->does('Bot::Backbone::Role::Service') } @$_ };

subtype PredicateList,
    as ArrayRef[CodeRef];

__PACKAGE__->meta->make_immutable;
