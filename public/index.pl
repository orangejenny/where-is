#!/usr/bin/perl

use lib "..";

use strict;
use CGI;
use Data::Dumper;
use URI::Escape;

use WhereIsCGI;
use WhereIsData;

my $dbh = WhereIsData::dbh;

# Data related to current user
my $request = WhereIsCGI::request_data;
my $name = $request->{NAME};
my $query = $request->{QUERY};
my ($url, $data);
my ($location, $person);
my @errors;
if ($query) {
	$person = WhereIsData::person_by_name($dbh, $name);
	$location = WhereIsData::location_by_query($dbh, $query);

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
			WhereIsData::add_person_location($dbh, {
				PERSONID => $person->{ID},
				LOCATIONID => $location->{ID},
			});
		}
	}
}

# Data for all users
my @personlocations = WhereIsData::person_locations($dbh);

my $cgi = CGI->new;
print $cgi->header();

# Page header
print qq{
	<html>

		<head>
			<link rel="stylesheet" type="text/css" href="WhereIs.css">
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
}, WhereIsCGI::escape_attribute($name), WhereIsCGI::escape_attribute($query));

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
