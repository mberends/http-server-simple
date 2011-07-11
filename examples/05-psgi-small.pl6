# http-server-simple/examples/05-psgi-small.pl6
use HTTP::Server::Simple::PSGI;

my $host = 'localhost';
my $port = 8080;
my $app = sub (%env) {
    return [
      '200',
      [ 'Content-Type' => 'text/plain' ],
      [ "Hello", "World\n\n", %env.perl ]
    ];
}

my $server = HTTP::Server::Simple::PSGI.new($port);
$server.host = $host;
$server.app($app);
$server.run;
