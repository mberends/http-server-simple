# http-server-simple/examples/01-simple-base.pl6
use HTTP::Server::Simple;
my HTTP::Server::Simple $server .= new; # base class without inheritance
$server.run;   # says "HTTP::Server::Simple at localhost:8080"
