//CREATE KEYSPACE cc_<username>
//    WITH REPLICATION = {
//            'class' : 'NetworkTopologyStrategy', 
//            'datacenter1' : 1, 
//    };

//Lets create simple settings table
//
//CREATE TABLE settings ( 
//	name text, 
//	value text,
//	PRIMARY KEY (name) 
//);

//insert INTO settings (name, value) 
//	VALUES ('host', 'mod1.finntech.no'); 
//insert INTO settings (name, value) 
//	VALUES ('socketTimeout', '1500'); 
//select * from settings;

//Add some versioning

//ALTER TABLE settings ADD version int;
//select * from settings;
//UPDATE settings SET version = 1
//WHERE name = 'host';
//select * from settings where name = 'host';
//select * from settings where value = 'key1';
//Det går ikke fordi cassandra må ha partisjon.

//INSERT INTO settings (name, value, version)
//	VALUES ('host', 'dev-mod1.finntech.no', 2);

//select * from settings where name = 'host';
//select * from settings;
//overwriten:(

//DROP TABLE settings;

//// pic 3
//CREATE TABLE settings ( 
//	name text, 
//    version int,
//	value text,
//	PRIMARY KEY (name, version) 
//);
//INSERT INTO settings (name, version, value) 
//	VALUES ('host', 1, 'mod1.finntech.no'); 
//insert INTO settings (name, version, value) 
//	VALUES ('socketTimeout', 1, '1500'); 
//select * from settings;
//Nå må det bare funke
//INSERT INTO settings (name, version, value) 
//	VALUES ('host', 2, 'dev-mod1.finntech.no'); 
//select * from settings where name = 'host';
//For ordens skyld
//INSERT INTO settings (name, version, value) 
//	VALUES ('host', 3, 'dev001.finn.amazonws.com');
//clustering key - sortering 
//select * from settings where name = 'host' order by version desc;
//hente siste version
//select * from settings where name = 'host' order by version desc limit 1;
//drop TABLE settings;
//CREATE TABLE settings ( 
//	name text, 
//    version int,
//	value text,
//	PRIMARY KEY (name, version) 
//) WITH CLUSTERING ORDER BY (version DESC);
//INSERT INTO settings (name, version, value) 
//	VALUES ('host', 1, 'mod1.finntech.no'); 
//INSERT INTO settings (name, version, value) 
//	VALUES ('host', 2, 'dev-mod1.finntech.no'); 
//INSERT INTO settings (name, version, value) 
//	VALUES ('host', 3, 'dev001.finn.amazonws.com');
//select * FROM settings where name = 'host';
//select * FROM settings where name = 'host' limit 1;

//drop TABLE settings;

//Legg til env-miljø variable (flere kolonner i clustering key)
// 4c
//CREATE TABLE settings ( 
//	name text,
//	env text, 
//    version int,
//	value text,
//	PRIMARY KEY (name, env, version) 
//);

//INSERT INTO settings (name, env, version, value) 
//	VALUES ('host', 'dev', 1, 'mod1.finntech.no'); 
//INSERT INTO settings (name, env, version, value) 
//	VALUES ('host', 'dev', 2, 'dev-mod1.finntech.no'); 
//INSERT INTO settings (name, env, version, value) 
//	VALUES ('host', 'prod', 1, 'mod01.finn.no');
//INSERT INTO settings (name, env, version, value) 
//	VALUES ('host', 'prod', 2, 'mod001.finn.amazonws.com');
//select * from settings where name = 'host' and env = 'prod';
//select * from settings where name = 'host' and version = 1; //funker ikke
//select * from settings where name = 'host' and env = 'prod' and version = 1; //funker 
//select * from settings where name = 'host' and (env, version) = ('prod', 1); // alternativ måte

////One-To-Many(pic5). Én setting (f.ex. host) kan brukes av mange apper. 
////How to get all settings for an app in a particular env.
//// Approach 1. Normalize
//CREATE TABLE app_settings (
//	app text,
//	env text,
//	setting_name text,
//	version int,
//	PRIMARY KEY (app, env, setting_name)
//);

//Koble search-management til den globale hosts-variabelen
//INSERT INTO app_settings (app, env, setting_name, version)
//VALUES ('search-management', 'dev', 'host', 2);

//Create specific setting for search-managenment
//Atomic insert into both tables
//BEGIN BATCH 
//	INSERT INTO settings (name, env, version, value)
//		VALUES ('SearchManagementService.maxActive', 'dev', 1, '15');
//	INSERT INTO app_settings (app, setting_name, env, version)
//		VALUES ('search-management', 'SearchManagementService.maxActive', 'dev', 1);
//APPLY BATCH;
//select * from app_settings where app = 'search-management' and env = 'dev';
//select name, value from settings 
//	where name = 'SearchManagementService.maxActive' and env = 'dev' and version = 1;
//select name, value from settings 
//	where name = 'host' and env = 'dev' and version = 2;
//drop table app_settings;

////Approach 2.  Denormalize
//CREATE TABLE app_settings (
//	app text,
//	env text,
//	setting_name text,
//	version int,
//	value text,
//	PRIMARY KEY (app, env, setting_name, version)
//);
//INSERT INTO app_settings (app, env, setting_name, version, value) 
//	VALUES ('search-management', 'dev', 'host', 1, 'mod1.finntech.no');
//INSERT INTO app_settings (app, env, setting_name, version, value) 
//	VALUES ('search-management', 'dev', 'SearchManagementService.maxActive', 1, '15');
//INSERT INTO app_settings (app, env, setting_name, version, value) 
//	VALUES ('ad-lookup', 'dev', 'host', 1, 'mod1.finntech.no');
//select setting_name, value from app_settings where app = 'search-management' and env = 'dev';
////duplisering av data, men det går fint så lenge man har version på plass 
//select * from app_settings;

////Many-to-many. (pic 6) Mange settings kan brukes av flere apper. 
////How-to get all teams for a particular setting
////Approach 1. Normalize
//CREATE TABLE settings_app (
//	setting_name text,
//	app text,
//	PRIMARY KEY (setting_name, app)
//);

//CREATE TABLE app (
//	app text PRIMARY KEY,
//	owner_team text
//);
//
//INSERT INTO settings_app (setting_name, app)
//	VALUES ('host', 'search-management');
//INSERT INTO settings_app (setting_name, app)
//	VALUES ('host', 'myinbox');
//INSERT INTO app (app, owner_team)
//	VALUES ('myinbox', 'Team Kode');
//INSERT INTO app (app, owner_team)
//	VALUES ('login-management', 'Team Kundeadmin');
//INSERT INTO app (app, owner_team)
//	VALUES ('search-management', 'Team Data');
//select * from settings_app where setting_name = 'host';
//SELECT owner_team FROM app WHERE app IN ('myinbox', 'search-management');

////Approach 2 boring denormalize by moving owner_team as a non-PK column to settings_app
////Approach 3 fun denormalize by using map-column
//select * from settings;
//alter table settings ADD apps_owners map<text, text>;
//UPDATE settings SET apps_owners = apps_owners + {'myinbox':'Team Kode', 'search-management':'Team Data'}
//	WHERE name = 'host' and env = 'dev' and version = 2; 
//select * from settings;

////List of values (pic 7)
//alter table settings ADD values list<text>;
//update settings set values = ['mod01.finn.no', 'mod02.finn.no', 'mod03.finn.no'] 
//	where name = 'host' and env = 'prod' and version = 1;
//select * from settings;

//// Static columns, common for whole partition
//drop TABLE settings;
//CREATE TABLE settings ( 
//	name text,
//	env text, 
//    version int,
//	value text,
//	description text static,
//	PRIMARY KEY (name, env, version) 
//);
//
//INSERT INTO settings (name, env, version, value, description) 
//	VALUES ('host', 'dev', 1, 'mod1.finntech.no', 'maskiner å kjøre på'); 
//INSERT INTO settings (name, env, version, value) 
//	VALUES ('host', 'dev', 2, 'dev-mod1.finntech.no'); 
//select * from settings;


 





