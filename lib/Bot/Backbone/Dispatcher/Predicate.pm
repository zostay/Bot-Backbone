package Bot::Backbone::Dispatcher::Predicate;
use v5.10;
use Moose;

# ABSTRACT: Defines the predicate packages responsible for aiding dispatch

=head1 DESCRIPTION

Not much to see here unless you want to define custom predicates. If that is your goal, you must read the code. You probably also want to read the code in L<Bot::Backbone::DispatchSugar> while you're at it.

=cut

__PACKAGE__->meta->make_immutable;

{
    package Bot::Backbone::Dispatcher::Predicate::RedispatchTo;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate';

    has name => ( is => 'ro', isa => 'Str', required => 1 );

    sub do_it {
        my ($self, $service, $message) = @_;

        my $redispatch_service = $service->get_service($self->name);
        return $redispatch_service->dispatch_message($message);
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package Bot::Backbone::Dispatcher::Predicate::Nesting;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate';

    has next_predicate => ( 
        is           => 'ro', 
        isa          => 'Bot::Backbone::Dispatcher::Predicate',
        required     => 1,
        handles      => [ 'do_it' ],
    );

    # sub do_it {
    #     my ($self, $service, $message) = @_;
    #     return $self->next_predicate->do_it($service, $message);
    # }

    __PACKAGE__->meta->make_immutable;
}

{
    package Bot::Backbone::Dispatcher::Predicate::Command;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate::Nesting';

    has match => (
        is          => 'ro',
        isa         => 'Str|RegexpRef',
        required    => 1,
    );

    override do_it => sub {
        my ($self, $service, $message) = @_;

        return $message->set_bookmark_do(sub {
            if ($message->match_next($self->match)) {
                $message->add_flag('command');
                return super();
            }

            return '';
        });
    };

    __PACKAGE__->meta->make_immutable;
}

{
    package Bot::Backbone::Dispatcher::Predicate::NotCommand;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate::Nesting';

    override do_it => sub {
        my ($self, $service, $message) = @_;

        unless ($message->has_flag('command')) {
            return super();
        }

        return '';
    };

    __PACKAGE__->meta->make_immutable;
}

{
    package Bot::Backbone::Dispatcher::Predicate::ToMe;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate::Nesting';

    has negate => (
        is          => 'ro',
        isa         => 'Bool',
        required    => 1,
        default     => '',
    );

    override do_it => sub {
        my ($self, $service, $message) = @_;
        
        # XORs break my brain, so just as a reminder...
        #
        # negate | is_to_me | xor result
        #   F    |    F     |    F
        #   F    |    T     |    T
        #   T    |    F     |    T
        #   T    |    T     |    F

        if ($self->negate xor $message->is_to_me) {
            return super();
        }

        return '';
    };

    __PACKAGE__->meta->make_immutable;
}

{
    package Bot::Backbone::Dispatcher::Predicate::GivenParameters;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate::Nesting';

    has parameters => (
        is          => 'ro',
        isa         => 'ArrayRef',
        required    => 1,
        traits      => [ 'Array' ],
        handles     => {
            all_parameters => 'elements',
        },
    );

    override do_it => sub {
        my ($self, $service, $message) = @_;

        return $message->set_bookmark_do(sub {
            for my $arg ($self->all_parameters) {
                my ($name, $config) = @$arg;

                # Match against ->args
                if (defined $config->{match}) {
                    my $match = $config->{match};

                    if (exists $config->{default} 
                            and not $message->has_more_args) {
                        $message->set_parameter($name => $config->{default});
                    }
                    else {
                        my $value = $message->match_next($match);
                        if (defined $value) {
                            $message->set_parameter($name => $value);
                        }
                        else {
                            return '';
                        }
                    }
                }

                # Match against ->text
                elsif (defined $config->{match_original}) {
                    my $match = $config->{match_original};

                    my $value = $message->match_next_original($match);
                    if (defined $value) {
                        $message->set_parameter($name => $value);
                    }
                    elsif (exists $config->{default}) {
                        $message->set_parameter($name => $config->{default});
                    }
                    else {
                        return '';
                    }
                }

                # What the...?
                else {
                    Carp::carp("parameter $name missing 'match' or 'match_original'");
                    return '';
                }
            }

            return super();
        });
    };

    __PACKAGE__->meta->make_immutable;
}

{
    package Bot::Backbone::Dispatcher::Predicate::Functor;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate';

    use Bot::Backbone::Types qw( DispatcherType );

    has dispatcher_type => (
        is          => 'ro',
        isa         => DispatcherType,
        required    => 1,
        coerce      => 1,
    );

    sub select_invocant {
        my ($self, $service) = @_;
        return $self->dispatcher_type eq 'bot' ? $service->bot : $service;
    }

    has the_code => (
        is          => 'ro',
        isa         => 'CodeRef',
        required    => 1,
        traits      => [ 'Code' ],
        handles     => {
            'call_the_code' => 'execute',
        },
    );
}

{
    package Bot::Backbone::Dispatcher::Predicate::Respond;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate::Functor';

    sub do_it {
        my ($self, $service, $message) = @_;

        my $invocant = $self->select_invocant($service);
        my @responses = $self->call_the_code($invocant, $message);
        if (@responses) {
            for my $response (@responses) {
                $message->reply($response);
            }

            return 1;
        }

        return '';
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package Bot::Backbone::Dispatcher::Predicate::Run;
    use v5.10;
    use Moose;

    extends 'Bot::Backbone::Dispatcher::Predicate::Functor';

    sub do_it {
        my ($self, $service, $message) = @_;
        my $invocant = $self->select_invocant($service);
        return $self->call_the_code($invocant, $message);
    }

    __PACKAGE__->meta->make_immutable;
}

1;
