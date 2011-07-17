package Bot::Backbone::Message;
use v5.10;
use Moose;

use Bot::Backbone::Identity;

# ABSTRACT: Describes a message or response

has from => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Identity',
    required    => 1,
);

has to => (
    is          => 'rw',
    isa         => 'Maybe[Bot::Backbone::Identity]',
    required    => 1,
);

has text => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has flags => (
    is          => 'ro',
    isa         => 'HashRef[Bool]',
    required    => 1,
    default     => sub { +{} },
);

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

sub add_flag     { shift->flags->{$_} = 1 for @_ } 
sub add_flags    { shift->flags->{$_} = 1 for @_ }
sub remove_flag  { delete shift->flags->{$_} for @_ }
sub remove_flags { delete shift->flags->{$_} for @_ }
sub has_flag     { all { shift->flags->{$_} } @_ }
sub has_flags    { all { shift->flags->{$_} } @_ }

sub set_bookmark {
    my $self = shift;
    my $bookmark = Bot::Backbone::Message->new(
        to   => $self->to,
        from => $self->from,
        text => $self->text,
    );
    $self->_set_bookmark($bookmark);
}

sub restore_bookmark {
    my $self = shift;
    my $bookmark = $self->_restore_bookmark;
    $self->to($bookmark->to);
    $self->from($bookmark->from);
    $self->text($bookmark->text);
}

sub set_bookmark_do {
    my ($self, $code) = @_;
    $self->set_bookmark;
    $code->();
    $self->restore_bookmark;
}

sub match_next {
    my ($self, $regex) = @_;

    my $text = $self->text;
    if (my ($value) = $text =~ s/^($regex)\s*//) {
        $self->text($text);
        return $value;
    }

    return;
}

__PACKAGE__->meta->make_immutable;
