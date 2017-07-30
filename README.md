# HTTP::Server::Simple

[![Build Status](https://travis-ci.org/gfldex/http-server-simple.svg?branch=master)](https://travis-ci.org/gfldex/http-server-simple)

This simple embedded web server is similar to HTTP::Daemon, but provides
more hooks for subclassing and extending.  The subclasses CGI and PSGI give
ways to host existing web applications or frameworks that use those APIs.

The Perl Server Gateway Interface is a more powerful and efficient web
server API than CGI.  Several well known Perl 5 products are based on it,
for example Plack and Dancer.  This Perl 6 based project offers the same
web server foundation on Rakudo, to assist the porting of such web
frameworks to Perl 6.

The object hierarchy follows its Perl 5 based prototype closely, except
where the CGI concerns were not separated from the web server.  In this
Perl 6 implementation the PSGI concerns are fully separated from the CGI
ones.

# EXAMPLES

Included are examples of minimal web servers and some that demonstrate use
of extension hooks and subclassing.

# TESTING

The code is badly under tested, contributions would be welcome.

# SEE ALSO

The Perl 6 Web.pm project: http://github.com/masak/web
The Perl Dancer project: perldancer.org
PSGI spec: http://github.com/miyagawa/psgi-specs/blob/master/PSGI.pod
Rack spec: http://rack.rubyforge.org/doc/SPEC.html
