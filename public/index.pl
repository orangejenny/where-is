#!/usr/bin/perl

use lib "..";

use strict;
use CGI;
use Data::Dumper;
use URI::Escape;

use DimagiCGI;
use DimagiData;

my $dbh = DimagiData::dbh;

# Data related to current user
my $request = DimagiCGI::request_data;
my $name = $request->{NAME};
my $query = $request->{QUERY};
my ($url, $data);
my ($location, $person);
my @errors;
if ($query) {
	# Dysfunctional: "Please add a username to each call in order for geonames to be able to identify the calling application and count the credits usage."
	# ...but there's a username	
	$url = 'http://api.geonames.org/searchJSON?maxRows=3&username=dimagi&name=' . uri_escape($query);
	$data = `curl $url`;

	$person = DimagiData::person_by_name($dbh, $name);
	$location = DimagiData::location_by_query($dbh, $query);

	if (!$person->{ID}) {
		push(@errors, "Could not find you, $name.");
	}
	if (!$location->{ID}) {
		push(@errors, "Could not find $query.");
	}

	if ($person->{ID}) {
		$name = $person->{NAME};
		if ($location->{ID}) {
			$query = $location->{NAME};
			DimagiData::add_person_location($dbh, {
				PERSONID => $person->{ID},
				LOCATIONID => $location->{ID},
			});
		}
	}
}

# Data for all users
my @personlocations = DimagiData::person_locations($dbh);

my $cgi = CGI->new;
print $cgi->header();

# Page header
print qq{
	<html>

		<head>
			<link rel="stylesheet" type="text/css" href="dimagi.css">
			<script type="text/javascript">
				window.onload = function() {
					document.getElementById("name").focus();
				}
			</script>
		</head>

		<body>
};

if ($request->{DEBUG}) {
	print "<pre>" . Dumper($request) . "</pre>";
	print "<pre>" . Dumper($location) . "</pre>";
	print "<pre>" . Dumper($person) . "</pre>";
	print "<pre>" . Dumper($data) . "</pre>";
}

# Form for user's data
print sprintf(qq{
	<form method="POST">
		Hi, I'm
		<input type="text" name="name" id="name" value="%s" />
		and I'm in 
		<input type="text" name="query" value="%s" />
		<input type="submit" value="Post" />
	</form>
}, DimagiCGI::escape_attribute($name), DimagiCGI::escape_attribute($query));

# Any errors in previous submission.
foreach my $error (@errors) {
	print "<div class='error'>$error</div>";
}

# Current data
print "<ul>";

foreach my $personlocation (@personlocations) {
	print sprintf(qq{
			<li>
				<a href='mailto:%s'>%s</a> is in %s (%s, %s), as of %s
			</li>
		},
		$personlocation->{EMAIL},
		$personlocation->{PERSONNAME},
		$personlocation->{LOCATIONNAME},
		$personlocation->{LATITUDE},
		$personlocation->{LONGITUDE},
		$personlocation->{CREATED},
	);
}

if ($request->{DEBUG}) {
	print "<pre>" . Dumper(\@personlocations) . "</pre>";
}


print "</ul>";

# Page footer
print qq {
		</body>
	</html>
};
