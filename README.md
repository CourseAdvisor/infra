CourseAdvisor infrastructure repository
=======================================

[ Work in progress ]

This repository contains containers and scripts for setting up the courseadvisor
backend as well as replication slaves, backup and deployment scripts.


## Prerequisites

This repository assumes a regular linux distro with the following programs accessible on the cli:
- docker
- mysql (+ mysqldump)

## Usage

TBD. The general idea would be to have frontend.sh expose all functionnalities although
sub-projects should be as disconnected as possible.


### Replication slave

Set up a replication slave like this:

`sudo ./frontend.sh slave setup`

And remove it with

`./frontend.sh slave remove`

Additionnal commands available: `stop`, `start`

(Notice: you must take care of `start`ing the instance after a reboot yourself)


### Master database

Master DB is deployed like this:

`sudo ./frontend.sh master setup -b backup_db.sql` where `backup_db.sql` is a sql
file containing a backup of the production data.

Additionnal commands: `stop`, `start`, `remove`
