# HTTP/Server/Simple.pm6

role HTTP::Server::Simple[IO::Socket ::SocketType = IO::Socket::INET] {
    has $.port;
    has $.host is rw;
    has SocketType $!listener;
    has $.connection;   # returned by accept()
    has Str $!request;
    has Str @!headers;

    my class Output-Interceptor {
        has $.socket is rw;
        multi method print(*@a) {
            # $*ERR.say: "Intercepting print " ~ @a;
            $.socket.print(@a);
        }
        multi method say(*@a) {
            # $*ERR.say: "Intercepting say " ~ @a;
            $.socket.print(@a ~ "\x0D\x0A");
        }
    }

    method new ( :$port = 8080 ) {
        self.bless(
            port    => $port,
            host    => self.lookup_localhost,
        );
    }
    method lookup_localhost () {
        # should return this computer's "127.0.0.1" or somesuch
        return 'localhost';
    }
    method run ( *@arguments ) { self.net_server(); }

    method net_server () {
        # an overrideable, minimal implementation called by run()
        self.print_banner;
        self.setup_listener;
        self.after_setup_listener;
        while $!connection = $!listener.accept {
            self.accept_hook;
            # receive only one request per session - no keepalive yet
            my $received = $!connection.recv();
            @!headers = split("\x0D\x0A", $received);
            $!request = @!headers.shift;
            my ($method, $uri, $protocol) = self.parse_request;
            unless self.valid_http_method($method) { self.bad_request; }
            my ( $path, $query-string ) = $uri.split('?',2);
            $query-string //= ''; # // confuses P5 syntax highlighters
            self.setup(
                :method($method), # rakudobug RT
                protocol     => $protocol || 'HTTP/0.9',
                query_string => $query-string,
                request_uri  => $uri,
                path         => $path,
                localname    => $!host,
                localport    => $!port,
                peername     => 'NYI',
                peeraddr     => 'NYI',
            );
            self.headers( self.parse_headers() );
            self.post_setup_hook;
            my $res = self.handler;
            $!connection.close();
        }
    }
    # Methods that a sub-class may want to override
    method handler () {
        # Called from net_server()
        # $*ERR.say: "in handler";
        my $stash-stdout = $*OUT;
        my Output-Interceptor $myIO .= new( socket => $!connection );
        $*OUT = $myIO;
        self.handle_request();
        $*OUT = $stash-stdout;
        # $*ERR.say: "end handler";
    }
    method handle_request () {
        # Called from handler()
        # generate a default reply to show that it works
        # $*ERR.say: "in handle_request";
        print "HTTP/1.0 200 OK\x0D\x0A\x0D\x0A";
        say "<html>\n<body>";
        say self.WHAT, " at {$!host}:{$!port}<br/><br/>";
        say "{hhmm} {$!request}<br/>";
        say "</body>\n</html>";
        # $*ERR.say: "end handle_request";
    }
    method setup ( :$method, :$protocol, :$request_uri, :$path,
        :$query_string, :$localport, :$peername, :$peeraddr, :$localname ) {
    }
    method headers (@headers) {
        for @headers -> [$key, $value] {
            self.header( $key, $value );
        }
    }
    method header ( $key, $value ) {
        # $*ERR.say: "header $key => $value";
    }
    method accept_hook () {
        # $*ERR.say: "accepted";
    }
    method post_setup_hook {
#       my $seconds = floor(time()) % 86400; # 24*60*60
#       my $hhmm = floor($seconds/3600).fmt('%02d')
#                ~ floor(($seconds/60) % 60).fmt(':%02d');
        $*ERR.say: "{hhmm} {$!request}";
    }
    method print_banner {
        say "{hhmm} ", self.WHAT, " started at {$!host}:{$!port}";
    }
    sub hhmm {
        my $seconds = floor(time) % 86400; # 24*60*60
        my $hhmm = floor($seconds/3600).fmt('%02d')
                 ~ floor(($seconds/60) % 60).fmt(':%02d');
        $hhmm;
    }
    # Methods below are probably not useful to override
    method parse_request () {
        $!request.split( /\s/ );
    }
    method parse_headers () {
        return gather for @!headers -> $line {
            my ( $key, $value ) = $line.split( ': ' );
            if defined($key) and defined($value) {
                # $*ERR.say: "parse_headers $key => $value";
                take $key, $value;
            }
        }
    }
    method setup_listener () {
        # say "setup listener on port $!port";
        # PF_INET=2, SOCK_STREAM=1, TCP=6
        $!host //= '0.0.0.0'; # // confuses P5 syntax highlighters
        $!listener = IO::Socket::INET.new(
            :localhost($!host),
            :localport($!port),
            :listen,
        );
    }
    method valid_http_method (Str $candidate_method) {
        $candidate_method eq any( <GET POST HEAD PUT DELETE> );
    }
    # Not Yet Implemented
    method background ( *@arguments ) { <...> }
    method restart () { <...> }
    method stdio_handle () { <...> }
    method stdin_handle () { <...> }
    method stdout_handle () { <...> }
    method after_setup_listener () { }
    method bad_request () { <...> }
}

=begin pod

=head1 NAME
HTTP::Server::Simple - small embedded HTTP server

=head1 SYNOPSIS

    use HTTP::Server::Simple;
    HTTP::Server::Simple $server.new;
    $server.run;   # says "alive" on port 8080

Normally one would use a class that wraps this server with a familiar
web API, such as CGI, FastCGI or PSGI.  HTTP::Server::Simple is a role
that classes can import with a 'does'.  For example:

    class HTTP::Server::Simple::Example does HTTP::Server::Simple;

=head1 DESCRIPTION
This is a Perl 6 re-implementation of the Perl 5 HTTP::Server::Simple.
Web applications generally do use this directly, but use a subclass such
as HTTP::Server::Simple::CGI, or similar ones based on FastCGI or PSGI.

=head1 ATTRIBUTES

=head2 host
The server's IP address (rw)

=head2 port
The port server is to run on (ro)

=head1 METHODS

=head2 new
Construct and return a server object.  The optional argument is a port
number (default 8080).  The server begins to listen and accept incoming
connections on the port when the run method is executed.

=head2 run
Start the server as foreground process in an infinite loop.  The server
is either a Net::Server, a subclass of that, or (default) a minimal
emulation of it.

=head2 background
Fork and run the child process as a server daemon.  Not Yet Implemented.

=head2 handler
Called from C<process_request>.  Sends a default response to the client.

=head2 setup
Called with named parameters: method, protocol, request_uri, path,
query_string, port, peername, peeraddr, localname.
As in the Perl 5 version, the default setup handler takes each
 tries to call 

=head2 headers

=head2 print_banner
Announces on the console that the server is running.

=head2 process_request
Called from C<_default_run>. Calls C<getpeername>, C<valid_http_method>,
C<setup>, C<parse_headers>, C<headers>, C<post_setup_hook>,
C<handler>.

=head2 parse_request

=head2 parse_headers

=head2 setup_listener
Prepares the server TCP socket up to the bind and listen operations.
Called from C<run>.

=head2 after_setup_listener
Called by C<run> as an event hook, the default handler does nothing.

=head1 TODO
Refactor and re-structure if necessary to be more compatible with the
Perl 5 version.  This requires testing with webserver applications that
have been ported.

=head1 SEE ALSO
Most of the code was inspired by the following Perl 5 modules:
L<HTTP::Server::Simple> L<Net::Server> L<HTTP::Daemon>

=end pod
