use v6;
use lib 'lib';
use Test;
use HTTP::Server::Simple;
use HTTP::Server::Simple::PSGI;


plan 2;

my $server = HTTP::Server::Simple.new;
ok($server ~~ HTTP::Server::Simple, 'HTTP::Server::Simple can be constructed');

$server = HTTP::Server::Simple::PSGI.new;
ok($server ~~ HTTP::Server::Simple::PSGI, 'HTTP::Server::Simple::PSGI can be constructed');

