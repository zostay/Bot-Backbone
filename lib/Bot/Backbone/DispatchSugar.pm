package Bot::Backbone::DispatchSugar;
use v5.10;
use Moose();
use Moose::Exporter;
use Carp();

use Bot::Backbone::Dispatcher::Predicate;

# ABSTRACT: Shared sugar methods for dispatch

=head1 DESCRIPTION

Do not use this package directly. 

See L<Bot::Backbone> and L<Bot::Backbone::Service>.

=cut

Moose::Exporter->setup_import_methods(
    with_meta => [ qw( 
        command not_command
        to_me not_to_me
        given_parameters
        also
        respond respond_by_method 
        run_this run_this_method
        redispatch_to 
    ) ],
    as_is => [ qw( parameter as ) ],
);

sub redispatch_to($) {
    my ($meta, $name) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::RedispatchTo->new(
            name            => $name,
        )
    );
}

sub also($) {
    my ($meta, $predicate) = @_;
    my $dispatcher = $meta->building_dispatcher;
    $dispatcher->add_also_predicate($predicate);
}

sub command($$) { 
    my ($meta, $match, $predicate) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::Command->new(
            match           => $match,
            next_predicate  => $predicate,
        )
    );
}

sub not_command($) {
    my ($meta, $predicate) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::NotCommand->new(
            next_predicate  => $predicate,
        )
    );
}

sub to_me($) {
    my ($meta, $predicate) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::ToMe->new(
            next_predicate  => $predicate,
        )
    );
}

sub not_to_me($) {
    my ($meta, $predicate) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::ToMe->new(
            negate          => 1,
            next_predicate  => $predicate,
        )
    );
}

our $WITH_ARGS;
sub given_parameters(&$) {
    my ($meta, $arg_code, $predicate) = @_;
    my $dispatcher = $meta->building_dispatcher;

    my @args;
    {
        local $WITH_ARGS = \@args;
        $arg_code->();
    }

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::GivenParameters->new(
            parameters      => \@args,
            next_predicate  => $predicate,
        )
    );
}

sub parameter($@) {
    my ($name, %config) = @_;
    push @$WITH_ARGS, [ $name, \%config ];
}

sub as(&) { 
    my $code = shift;
    return $code;
}

sub _respond { 
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::Respond->new(
            dispatcher_type => $meta,
            the_code        => $code,
        )
    );
}

sub respond(&) {
    my ($meta, $code) = @_;
    _respond($meta, $code);
}

sub _run_this {
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(
        Bot::Backbone::Dispatcher::Predicate::Run->new(
            dispatcher_type => $meta,
            the_code        => $code,
        )
    );
}

sub run_this(&) {
    my ($meta, $code) = @_;
    _run_this($meta, $code);
}

sub _by_method {
    my ($meta, $name) = @_;

    Carp::croak("no such method as $name found on ", $meta->name)
        unless defined $meta->find_method_by_name($name);

    return sub {
        my ($self, $message) = @_;

        my $method = $self->can($name);
        if (defined $method) {
            return $self->$method($message);
        }
        else {
            Carp::croak("no such method as $name found on ", $self->meta->name);
        }
    };
}

sub respond_by_method($) {
    my ($meta, $name) = @_;

    my $code = _by_method($meta, $name);
    _respond($meta, \&$code);
}

sub run_this_method($) {
    my ($meta, $name) = @_;

    my $code = _by_method($meta, $name);
    _run_this($meta, \&$code);
}

# These are documented in Bot::Backbone and Bot::Backbone::Service


=begin Pod::Coverage

  also
  as
  command
  given_parameters
  not_command
  not_to_me
  parameter
  redispatch_to
  respond
  respond_by_method
  run_this
  run_this_method
  to_me

=end Pod::Coverage

=cut

1;
