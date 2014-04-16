package DimagiData;

use strict;
use Data::Dumper;
use DBI;
use YAML;

sub add_person_location {
	my ($dbh, $args) = @_;

	my $sql = "
		insert into personlocation(
			personid,
			locationid,
			created
		)
		values (?, ?, now())
	";

	_results($dbh, {
		SQL => $sql,
		BINDS => [$args->{PERSONID}, $args->{LOCATIONID}],
		SKIPFETCH => 1,
	});
}

sub location_by_query {
	my ($dbh, $query) = @_;

	$query = _sanitize($query);
	my $sql = "select id, name from location where lower(name) = ? order by population desc";

	my @results = _results($dbh, {
		SQL => $sql,
		COLUMNS => [qw(id name)],
		BINDS => [lc $query],
	});

	return shift(@results) || {};
}

sub person_by_name {
	my ($dbh, $name) = @_;
	$name = _sanitize($name);

	my @columns = (
		'person.id id',
		'person.email email',
		'person.image image', 
		'personname.name name',
	);

	my $sql = sprintf("
		select 
			%s
		from
			person,
			personname
		where
			person.id = personname.personid
			and lower(name) = ?
	", join(", ", @columns));

	my @people = _results($dbh, {
		SQL => $sql,
		COLUMNS => \@columns,
		BINDS => [lc $name],
	});

	return shift @people || {};
}

sub person_locations {
	my ($dbh) = @_;

	my @columns = (
		'personname.name personname', 
		'person.id personid', 
		'person.email email',
		'person.image image',
		'location.name locationname', 
		'location.latitude latitude', 
		'location.longitude longitude', 
		'personlocation.created created',
	);

	my $sql = sprintf("
		select 
			%s
		from 
			person, 
			personname, 
			location, 
			personlocation 
		where 
			personlocation.personid = person.id 
			and personlocation.locationid = location.id 
			and personname.personid = person.id 
			and created = (
				select max(created) 
				from personlocation pl 
				where pl.personid = personlocation.personid) 
			and personname.preferred = 1
		order by
			created desc
	", join(",", @columns));

	return _results($dbh, {
		SQL => $sql,
		COLUMNS => \@columns,
	});
}

sub _results {
	my ($dbh, $args) = @_;

	my @binds = $args->{BINDS} ? @{ $args->{BINDS} } : ();

	my $sql = $args->{SQL};
	my $query = $dbh->prepare($sql) or die "PREPARE: $DBI::errstr ($sql)";
	$query->execute(@binds) or die "EXECUTE: $DBI::errstr ($sql)";

	my @results;
	my @rawcolumns = $args->{COLUMNS} ? @{ $args->{COLUMNS} } : ();
	my @columns;
	foreach my $column (@rawcolumns) {
		my $shortcolumn = uc $column;
		$shortcolumn =~ s/.*\s+//;
		push(@columns, $shortcolumn);
	}
	while (!$args->{SKIPFETCH} && (my @row = $query->fetchrow())) {
		my %labeledrow;
		for (my $i = 0; $i < @columns; $i++) {
			$labeledrow{uc($columns[$i])} = $row[$i];
		}
		push @results, \%labeledrow;
	}
	$query->finish();

	return @results;
}

# rather harsh
sub _sanitize {
	my ($string) = @_;

	$string =~ s/[^\w\s]//g;

	return $string;
}

sub dbh {
	my $config = YAML::LoadFile("../database.yml");

	my $host = $config->{host};
	my $database = $config->{database};
	my $user = $config->{user};
	my $password = $config->{password};

	return DBI->connect("dbi:mysql:host=$host:$database", $user, $password) or die $DBI::errstr;
}

1;
