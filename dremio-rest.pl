#!/usr/bin/perl -ws

# Copyright 2022 Mariano Dominguez
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Dremio REST API client
# Use -help for options

use strict;
use REST::Client;
use MIME::Base64;
use JSON;
use Data::Dumper;
use IO::Prompter;

use vars qw($help $version $d $u $p $https $host $noredirect $m $b $f $t $json $login $r);

if ( $version ) {
	print "Dremio REST API client\n";
	print "Author: Mariano Dominguez\n";
	print "Version: 1.1.1\n";
	print "Release date: 2022-12-10\n";
	exit;
}

&usage if $help;
die "Use -login or set -r (REST resource|endpoint)\nUse -help for options\n" unless ( $login || $r );

if ( $login ) {
	my $dremio_cred_file = "$ENV{'HOME'}/.dremio_rest";
	print "Credentials file $dremio_cred_file " if $d;

	if ( -e $dremio_cred_file ) {
		print "found\n" if $d;
		open my $fh, '<', $dremio_cred_file or die "Can't open file $dremio_cred_file: $!\n";
		my @dremio_cred = grep /DREMIO_REST_/, <$fh>;
		foreach ( @dremio_cred ) {
			# Colon-separated key/value pair
			# For credentials containing white spaces, use quotes and -u|-p options
			# or environment variables instead of the credentials file
			my ($env_var, $env_val) = $_ =~ /([^\s]+)\s*:\s*([^\s]+)/;
			$ENV{$env_var} = $env_val if ( defined $env_var && defined $env_val );
		}
		close $fh;
	} else {
		print "not found\n" if $d;
	}

	if ( $d ) {
		print "DREMIO_REST_USER = $ENV{DREMIO_REST_USER}\n" if $ENV{DREMIO_REST_USER};
		print "DREMIO_REST_PASS is set\n" if $ENV{DREMIO_REST_PASS};
	}

	if ( $u && $u eq '1' ) {
		$u = prompt "Username [$ENV{USER}]:", -in=>*STDIN, -timeout=>30, -default=>"$ENV{USER}";
		die "Timed out\n" if $u->timedout;
		print "Using default username\n" if $u->defaulted;
	}

	my $dremio_user = $u || $ENV{'DREMIO_REST_USER'} || $ENV{USER};
	print "username = $dremio_user\n" if $d;

	my $dremio_password = $p || $ENV{'DREMIO_REST_PASS'} || undef;
	unless ( $dremio_password ) {
		print "Prompting for password...\n" if $d;
		$p = 1;
	}

	if ( $p && $p eq '1' ) {
		$p = prompt 'Password:', -in=>*STDIN, -timeout=>30, -echo=>'';
		die "Timed out\n" if $p->timedout;
		$dremio_password = $p;
	}

	print "Password file " if $d;
	if ( -e $dremio_password ) {
		print "$dremio_password found\n" if $d;
		$dremio_password = qx/cat $dremio_password/ || die "Can't get password from file $dremio_password\n";
		chomp($dremio_password);
	} else {
		print "not found\n" if $d;
	}

	$m = 'POST';
	my $login_body = { 'userName' => ''.$dremio_user, 'password' => ''.$dremio_password };
	$b = to_json $login_body;
	$r = '/apiv2/login';
}

my $scheme = $https ? 'https' : 'http';
my ($dremio_host, $dremio_port) = split(/:/, $host, 2) if ( $host && $host ne '1' );

$dremio_host = 'localhost' unless $dremio_host;
$dremio_port = 9047 unless $dremio_port;
$r = $2 if $r =~ /(\/*)(.*)/; # Remove leading slashes if any

my $url = "$scheme://$dremio_host:$dremio_port";
$url .= "/$r" if $r;
my $token = $t || "$ENV{'HOME'}/.dremio_token";
my $headers = { 'Content-Type' => 'application/json' };
my $method = $m || 'GET';
my $body_content = $b || undef;

if ( $d ) {
	print "method = $method\n";
	print "url = $url\n";
}

if ( $f ) {
	my $filename = $f;
	$body_content = do {
		local $/ = undef;
		open my $fh, '<', $filename or die "Can't open file $filename: $!\n";
		<$fh>;
	}
}

if ( $d && defined $body_content ) {
	print "body_content = $body_content\n";
}

unless ( $login ) {
	print "Token file " if $d;
	
	if ( -e $token ) {
		print "$token found\n" if $d;
		open my $fh, '<', $token or die "Can't open file $token: $!\n";
		$token = <$fh>;
		chomp $token;
		close $fh;
	} else {
		print "not found\n" if $d;
	}

	if ( $token ) {
		print "token = $token\n" if $d;
		$headers->{'Authorization'} = '_dremio' . $token;
	} else {
		die "No token available\nUse -login to get a token\n";
	}
}

# http://search.cpan.org/dist/libwww-perl/lib/LWP.pm
#  PERL_LWP_SSL_VERIFY_HOSTNAME
#   The default verify_hostname setting for LWP::UserAgent. If not set the default will be 1. Set it as 0 to disable hostname verification (the default prior to libwww-perl 5.840).
# http://search.cpan.org/~ether/libwww-perl/lib/LWP/UserAgent.pm#CONSTRUCTOR_METHODS
#  verify_hostname => $bool
#   This option is initialized from the PERL_LWP_SSL_VERIFY_HOSTNAME environment variable. If this environment variable isn't set; then verify_hostname defaults to 1.
#$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

# SSL connect attempt failed error:14090086:SSL routines:ssl3_get_server_certificate:certificate verify failed

# http://search.cpan.org/~kkane/REST-Client/lib/REST/Client.pm
my $client = REST::Client->new();

while ( $url ) {
	$client->getUseragent()->ssl_opts( verify_hostname => 0 ) if ( $https || $url =~ /^https/i );

	if ( $method =~ m/GET/i ) {
		$client->GET($url, $headers);
	} elsif ( $method =~ m/POST/i ) {
		$client->POST($url, $body_content, $headers);
	} elsif ( $method =~ m/PUT/i ) {
		$client->PUT($url, $body_content, $headers);
	} elsif ( $method =~ m/DELETE/i ) {
		$client->DELETE($url, $headers);
	} else {
		die "Invalid method: $method\n";
	}

	my $http_rc = $client->responseCode();
	my $response_content = $client->responseContent();

	if ( $d ) {
		foreach ( $client->responseHeaders() ) {
			print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
		}
		print "Response code: $http_rc\n";
		print "Response content:\n" if $response_content;
	}

	if ( $client->responseHeader('location') && !$noredirect ) {
		my $location =  $client->responseHeader('location');
		if ( $location =~ '^/' ) { $url .= $location } else { $url = $location }
		print "Redirecting to $url\n";
	} else {
		undef $url;
	}

	my $is_json;
	if ( $response_content ) {
		$is_json = eval { from_json("$response_content"); 1 };
		$is_json or print "No JSON format detected\n" if $d;
		if ( $is_json && !$json ) {
			use JSON::PP ();
			$JSON::PP::true = 'true';
			$JSON::PP::false = 'false';
			my $decoded_json = JSON::PP::decode_json($response_content);
			print Dumper $decoded_json;
		} else {
			print "$response_content\n";
		}
	} else {
		print "No response content\n" if $d;
	}

	print "The request did not succeed [HTTP RC = $http_rc]\n" if $http_rc !~ /2\d\d/;

	if ( ( $login || $t ) && $is_json && from_json($response_content)->{'token'} ) {
		my $token_string = from_json($response_content)->{'token'};
		open my $fh, '>', $token or die "Can't open file $token: $!\n";
		print $fh $token_string;
		close $fh;
		print "Saved token to file: $token\n";
	}
}

sub usage {
	print "\nUsage: $0 [-help] [-version] [-d] [-u[=username]] [-p[=password]] [-https] [-host=hostname[:port]]\n";
	print "\t [-noredirect] [-m=method] [-b=body_content] [-f=json_file] [-t] [-json] -login | -r=rest_resource\n\n";

	print "\t -help : Display usage\n";
	print "\t -version : Display version information\n";
	print "\t -d : Enable debug mode\n";
	print "\t -u : Dremio username (environment variable: \$DREMIO_REST_USER | default: \$USER -current user-)\n";
	print "\t -p : Dremio password or path to password file (environment variable: \$DREMIO_REST_PASS | default: undef)\n";
	print "\t      Credentials file: \$HOME/.dremio_rest (set env variables using colon-separated key/value pairs)\n";
	print "\t -https : Use HTTPS to communicate with Dremio (default: HTTP)\n";
	print "\t -host : Dremio hostname:port (default: localhost:9047)\n";
	print "\t -noredirect : Do not follow redirects\n";
	print "\t -m : Method | GET, POST, PUT, DELETE (default: GET)\n";
	print "\t -b : Body content (JSON format)\n";
	print "\t -f : JSON file containing body content\n";
	print "\t -t : Token string or path to token file (default: \$HOME/.dremio_token)\n";
	print "\t -json : Do not use Data::Dumper to output the response content (default: disabled)\n";
	print "\t -login : Get token from Dremio and save to file (implies -t=default_token_file)\n";
	print "\t -r : REST resource|endpoint (example: /api/v3/catalog)\n\n";
	exit;
}
