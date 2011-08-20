#!/usr/bin/perl
use v5.10;
use Moose;

use lib 't/lib';
use Bot::Backbone::TestEventLoop;
use Test::More tests => 7;

{
    package TestBot::Service::Foo;
    use Bot::Backbone::Service;

    with 'Bot::Backbone::Service::Role::Service';

    use Test::More;

    service_dispatcher as {
        run_this { 
            isa_ok($_[0], 'TestBot::Service::Foo'); 
            is($_[1]->text, 'blah blee bloo', 'dispatched to service'); 
            1 
        };
    };

    sub initialize { 
        pass('initialized');
    }
}

{
    package TestBot;
    use Bot::Backbone;

    use Test::More;

    service chat => (
        service    => 'TestChat',
        dispatcher => 'test',
    );

    service foo => (
        service => '.Foo',
    );

    dispatcher test => as {
        command '!foo' => run_this { 
            #diag explain \@_;
            isa_ok($_[0], 'TestBot');
            is($_[1]->text, '', '!foo #1 runs'); 
            1
        };
        command '!foo' => run_this { fail('!foo #2 never runs'); 1 };

        command '!bar' => run_this { is($_[1]->text, 'blah blah', '!bar #1 runs'); 0 };
        command '!bar' => run_this { is($_[1]->text, 'blah blah', '!bar #2 runs'); 1 };
        command '!bar' => run_this { fail('!bar #3 never runs'); 1 };

        command '!baz' => redispatch_to 'foo';
    };
}

my $bot = TestBot->new( event_loop => 'Bot::Backbone::TestEventLoop' );
$bot->run;

my $chat = $bot->get_service('chat');
$chat->dispatch( text => '!foo' );
$chat->dispatch( text => '!bar blah blah' );
$chat->dispatch( text => '!baz blah blee bloo' );
