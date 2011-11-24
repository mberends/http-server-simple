# http-server-simple/examples/02-simple-small.pl6
# An implementation of the Perl 5 version's second synopsis example
# (using a sub-class).

use v6;
use HTTP::Server::Simple;

class Example::Simple::Small is HTTP::Server::Simple {
    has %!header;
    has $!path;
    has $!query_string;
    method setup ( :$path, :$query_string, *%rest ) {
        $!path = $path;
        $!query_string = $query_string;
    }
    method header ( $key, $value ) {
        %!header{$key} = $value;
    }
    # override the request handler of the base class
    method handle_request () {
        print "HTTP/1.0 200 OK\x0D\x0A\x0D\x0A";
        say "<html>\n<body>";
        say self.WHAT, " at {$.host}:{$.port}";
        say "<table border=\"1\">";
        for %!header.keys -> $key {
            my $value = %!header{$key};
            say "<tr><td>{$key}</td><td>{$value}</td></tr>";
        }
        say "</table>";
        say "Path: {$!path}<br/>";
        say "Query string: {$!query_string}<br/>";
        say "</body>\n</html>";
    }
}
my Example::Simple::Small $server .= new;
$server.run;  # now browse http://localhost:8080/whatever?name=value
