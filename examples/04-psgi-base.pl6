# http-server-simple/examples/04-psgi-base.pl6
# Try the PSGI base class
use HTTP::Server::Simple::PSGI;

HTTP::Server::Simple::PSGI.new.run;
# now browse http://localhost:8080/whatever?name=value
