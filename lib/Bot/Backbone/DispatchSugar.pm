package Bot::Backbone::DispatchSugar;
use v5.10;
use Moose();
use Moose::Exporter;
use Carp();

# ABSTRACT: Shared sugar methods for dispatch

=head1 DESCRIPTION

Do not use this package directly. 

See L<Bot::Backbone> and L<Bot::Backbone::Service>.

=cut

Moose::Exporter->setup_import_methods(
    as_is => [ qw( 
        command not_command
        given_parameters parameter 
        as 
        also
        respond respond_by_method 
        redispatch_to 
    ) ],
);

sub redispatch_to($) {
    my ($name) = @_;
    my $dispatcher = $_;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;

        my $redispatch_service = $service->bot->services->{$name};
        return $redispatch_service->dispatch_message($message);
    });
}

sub also($) {
    my ($code) = @_;
    my $dispatcher = $_;

    $dispatcher->add_also_predicate(sub {
        my ($service, $message) = @_;
        return $code->($service, $message);
    });
}

sub command($$) { 
    my ($name, $code) = @_;
    my $dispatcher = $_;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;

        return $message->set_bookmark_do(sub {
            if ($message->match_next($name)) {
                $message->add_flag('command');
                my $result = $code->($service, $message);

                return $result;
            }

            return '';
        });
    });
}

sub not_command($) {
    my ($code) = @_;
    my $dispatcher = $_;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;
        
        unless ($message->has_flag('command')) {
            return $code->($service, $message);
        }

        return '';
    });
}

our $WITH_ARGS;
sub given_parameters(&$) {
    my ($arg_code, $code) = @_;
    my $dispatcher = $_;

    my @args;
    {
        local $WITH_ARGS = \@args;
        $arg_code->();
    }

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;

        return $message->set_bookmark_do(sub {
            for my $arg (@args) {
                my ($name, $config) = @$arg;
                my $match = $config->{match};

                if (my $value = $message->match_next($match)) {
                    $message->set_parameter($name => $value);
                }
                else {
                    return '';
                }
            }

            return $code->($service, $message);
        });
    });
}

sub parameter($@) {
    my ($name, %config) = @_;
    push @$WITH_ARGS, [ $name, \%config ];
}

sub as(&) { 
    my $code = shift;
    return $code;
}

sub respond(&) { 
    my $code = shift;
    my $dispatcher = $_;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;

        my @responses = $code->($service, $message);
        if (@responses) {
            for my $response (@responses) {
                $message->reply($response);
            }

            return 1;
        }

        return '';
    });
}

sub _by_method {
    my ($name) = @_;

    return sub {
        my ($service, $message) = @_;

        my $method = $service->can($name);
        if (defined $method) {
            return $service->$method($message);
        }
        else {
            Carp::croak("no such method as $name found on ", $service->meta->name);
        }
    };
}

sub respond_by_method($) {
    my ($name) = @_;

    my $code = _by_method($name);
    respond(\&$code);
}

1;
