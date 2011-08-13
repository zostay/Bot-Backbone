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

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;

        my $redispatch_service = $service->bot->services->{$name};
        return $redispatch_service->dispatch_message($message);
    });
}

sub also($) {
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_also_predicate(sub {
        my ($service, $message) = @_;
        return $code->($service, $message);
    });
}

sub command($$) { 
    my ($meta, $name, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

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
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;
        
        unless ($message->has_flag('command')) {
            return $code->($service, $message);
        }

        return '';
    });
}

sub to_me($) {
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;

        if ($message->is_to_me) {
            return $code->($service, $message);
        }

        return '';
    });
}

sub not_to_me($) {
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;

        unless ($message->is_to_me) {
            return $code->($service, $message);
        }

        return '';
    });
}

our $WITH_ARGS;
sub given_parameters(&$) {
    my ($meta, $arg_code, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

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

sub _respond { 
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

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

sub respond(&) {
    my ($meta, $code) = @_;
    _respond($meta, $code);
}

sub _run_this {
    my ($meta, $code) = @_;
    my $dispatcher = $meta->building_dispatcher;

    $dispatcher->add_predicate_or_return(sub {
        my ($service, $message) = @_;
        return $code->($service, $message);
    });
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
    my ($meta, $name) = @_;

    my $code = _by_method($meta, $name);
    _respond($meta, \&$code);
}

sub run_this_method($) {
    my ($meta, $name) = @_;

    my $code = _by_method($meta, $name);
    _run_this($meta, \&$code);
}

1;
