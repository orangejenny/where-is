drop table person;
create table person (
	id int not null auto_increment,
	email varchar(32),
	image varchar(332),
	primary key (id)
);

drop table personname;
create table personname (
	id int not null auto_increment,
	personid int not null,
	name varchar(32) not null,
	preferred bool,
	primary key (id),
	foreign key (personid) references person(id)
);

drop table location;
create table location (
	id int not null,
	name varchar(64) not null,
	latitude decimal(8, 5) not null,
	longitude decimal(8, 5) not null,
	countrycode varchar(2),
	population int,
	timezone varchar(32),
	primary key (id)
);

drop table personlocation;
create table personlocation (
	id int not null auto_increment,
	personid int not null,
	locationid int not null,
	created datetime not null,
	primary key (id),
	foreign key (personid) references person(id),
	foreign key (locationid) references location(id)
);
