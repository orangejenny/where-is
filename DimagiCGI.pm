package DimagiCGI;

use strict;
use CGI;

sub escape_attribute {
	my ($attribute) = @_;
	$attribute =~ s/"/&quot;/g;
	return $attribute;
}

sub request_data {
	my $cgi = CGI->new;

	my $request;

	foreach my $key ($cgi->param(), $cgi->url_param()) {
		$request->{uc $key} = $cgi->param($key) || $cgi->url_param($key);
	}

	return $request;
}

1;
