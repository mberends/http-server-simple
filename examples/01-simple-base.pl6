# http-server-simple/examples/01-simple-base.pl6
# A port of the Perl 5 version's first synopsis example

use HTTP::Server::Simple;
my $server = HTTP::Server::Simple.new; # base class without inheritance
$server.run;  # now browse http://localhost:8080/whatever?name=value
