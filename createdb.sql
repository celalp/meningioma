

CREATE SCHEMA IF NOT EXISTS samples_users;

CREATE TABLE IF NOT EXISTS samples_users.users
(
 "userid"     serial PRIMARY KEY,
 "username"   varchar(75) NOT NULL,
 "name"       varchar(50) NOT NULL,
 "middlename" varchar(50) NULL,
 "lastname"   varchar(50) NOT NULL,
 "created"    timestamp NOT NULL,
 "password"   varchar(128) NOT NULL,
 "secret"     varchar(128) NOT NULL,
 "admin"      boolean NOT NULL,
 "active"     boolean NOT NULL, 
 "email"      varchar(150) NOT NULL
);



CREATE TABLE IF NOT EXISTS samples_users.samples
(
 "sampleid"      serial PRIMARY KEY,
 "samplename"    varchar(75) NOT NULL,
 "added"         timestamp NOT NULL,
 "who_grade"     varchar(10),
 "simpson_score" varchar(10),
 "status"        varchar(500),
 "detection_p"   real,
 "methylome_prob" real,
 "recurrence_prob" real,
 "description"   varchar(500)
);


CREATE TABLE IF NOT EXISTS samples_users.access
(
 "id"     serial PRIMARY KEY,
 "time"   timestamp NOT NULL,
 "username" varchar(75) NOT NULL,
 "action" varchar(50) NOT NULL,
 "status" varchar(50) NOT NULL
);

CREATE INDEX "user_access" ON samples_users.access
(
 "username"
);


CREATE TABLE IF NOT EXISTS samples_users.samples_users_linked
(
  "userid"   serial NOT NULL,
 "sampleid" serial NOT NULL,
  PRIMARY KEY (userid, sampleid)
);



CREATE TABLE IF NOT EXISTS samples_users.analysis
(
 "id"       serial PRIMARY KEY,
 "time"     timestamp NOT NULL,
 "message"  varchar(500) NOT NULL,
 "status"   varchar(50) NOT NULL,
 "username"   varchar(75) NOT NULL,
 "samplename" varchar(75) NOT NULL
);


CREATE INDEX "analysis_sampleid" ON samples_users.analysis
(
 "samplename"
);

CREATE INDEX "analysis_userid" ON samples_users.analysis
(
 "username"
);


