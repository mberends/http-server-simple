# HTTP/Server/Simple/PSGI.pm6
use v6;
use HTTP::Server::Simple;

class HTTP::Server::Simple::PSGI does HTTP::Server::Simple {
    # The Perl 6 version inherits from H::T::Simple, not H::T::S::CGI
    has $!psgi_app;
    has %!env;

    method app( $app ) {
        $!psgi_app = $app;
    }
    method setup ( :$localname, :$localport, :$method, :$request_uri,
        :$path, :$query_string, :$peername, :$peeraddr, *%rest )
    {
        %!env = 
            'SERVER_NAME'       => $localname,
            'SERVER_PORT'       => $localport,
            'REQUEST_METHOD'    => $method,
            'REQUEST_URI'       => $request_uri,
            'PATH_INFO'         => $path,
            'QUERY_STRING'      => $query_string,
            'REMOTE_NAME'       => $peername,
            'REMOTE_ADDR'       => $peeraddr,
            # required PSGI members
            'psgi.version'      => [1,0],
            'psgi.url_scheme'   => 'http',
            'psgi.multithread'  => Bool::False,
            'psgi.multiprocess' => Bool::False,
            # optional PSGI members
            'psgi.runonce'      => Bool::False,
            'psgi.nonblocking'  => Bool::False,
            'psgi.streaming'    => Bool::False,
        ;
    }
    method headers (@headers) {
        for @headers -> [$key is copy, $value] {
            $key ~~ s:g /\-/_/;
            $key .= uc;

            $key = 'HTTP_' ~ $key unless $key eq any(<CONTENT_LENGTH CONTENT_TYPE>);
            # RAKUDO: :exists doesn't exist yet
            if %!env{$key}:exists {
                # This is how P5 Plack::HTTPParser::PP handles this
                %!env{$key} ~= ", $value";
            }
            else {
                %!env{$key} = $value;
            }
        }
    }
    method handler { # overrides HTTP::Server::Simple
        # $*ERR.say: "in PSGI.handler";
        # Note: the handler method in HTTP::Server::Simple calls the
        # handle_request method but that becomes psgi_app() over here.
        # Instead it calls handle_response later on.
        my $response_ref = defined($!psgi_app)
            ?? $!psgi_app(%!env) # app must return [status,[headers],[body]]
            !! [500,[Content-Type => 'text/plain'],[self.WHAT.perl,"app missing"]];
        my $status  = $response_ref[0];
        my @headers = $response_ref[1];
        my @body    = $response_ref[2];
        # $*ERR.say: "Status: $status";
        # $*ERR.say: "Headers: {@headers}";
		# $*ERR.say: "Body: {@body}";
        $.connection.print( "HTTP/1.1 $status OK\x0D\x0A" );
        $.connection.print(
            @headers.map({ $_[0].key ~ ': ' ~ $_[0].value }).join("\n")
        );
        $.connection.print( "\x0D\x0A" );
        $.connection.print( "\x0D\x0A" );
        $.connection.print( @body );
        # $*ERR.say: "end PSGI.handler";
    }
}

=begin pod

=head1 NAME
HTTP::Server::Simple::PSGI - Perl Server Gateway Interface web server

    my $host = 'localhost';
    my port = 80;
    my $app = sub(%env) {
        return [
          '200',
          [ 'Content-Type' => 'text/plain' ],
          [ "Hello World" ]  # or IO::Handle-like object
        ];
    }

    my $server = HTTP::Server::Simple::PSGI.new($port);
    $server.host($host);
    $server.app($app);
    $server.run;

=head1 DESCRIPTION
After implementing about half of HTTP::Server::Simple::PSGI on Rakudo
Perl 6, the importance of HTTP::Server::Simple became apparent.  That
epiphany caused a renaming of the project and a shift of development
emphasis.

This Perl 6 module provides a lightweight in process web server that
conforms to the Perl Server Gateway Interface specification.  It should
work exactly like the Perl 5 version.  In the synopsis above, the only
difference between Perl 6 and Perl 5 is the use of '.' instead of '->'
to address object methods.

The PSGI spec replaces CGI with something equally simple, but Perl
specific and likely to be more efficient because of not spawning
child processes.  Read the SEE ALSO links below for more information.

The Perl Dancer project uses HTTP::Server::Simple::PSGI in Perl 5.  The
initial motivation for this work was to enable the development of a
Perl 6 version of Dancer.  That work can begin only after this
foundation proves itself.

=head1 TESTING
Unfortunately the Perl 5 test suite is limited to only verifying that
the module loads and compiles ok.  Admittedly it is hard to test I/O
based software such as a web server, but it would be worth the effort to
try.

The documentation is written in Pod6 L<http://perlcabal.org/syn/S26.html>
to get some experience with the format.

=head1 SEE ALSO
The Perl 6 Web.pm project L<http://github.com/masak/web>
The Perl Dancer project L<perldancer.org>
PSGI spec L<http://github.com/miyagawa/psgi-specs/blob/master/PSGI.pod>
Rack spec L<http://rack.rubyforge.org/doc/SPEC.html>

=end pod
