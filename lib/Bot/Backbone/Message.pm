package Bot::Backbone::Message;
use v5.10;
use Moose;

# ABSTRACT: Describes a message or response

has from => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Identity',
    # required    => 1,
);

has to => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Identity',
    # required    => 1,
);

has text => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has flags => (
    is          => 'ro',
    isa         => 'HashRef[Bool]',
    required    => 1,
    default     => sub { +{} },
);

around BUILDARGS => sub {
    my $next = shift;
    my $self = shift;

    return $self->$next(@_) unless @_ == 1;;

    return { text => $_[0] };
};

sub add_flag     { shift->flags->{$_} = 1 for @_ } 
sub add_flags    { shift->flags->{$_} = 1 for @_ }
sub remove_flag  { delete shift->flags->{$_} for @_ }
sub remove_flags { delete shift->flags->{$_} for @_ }
sub has_flag     { all { shift->flags->{$_} } @_ }
sub has_flags    { all { shift->flags->{$_} } @_ }

__PACKAGE__->meta->make_immutable;
