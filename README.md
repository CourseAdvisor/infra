CourseAdvisor infrastructure repository
=======================================

[ Work in progress ]

This repository contains containers and scripts for setting up the courseadvisor
backend as well as replication slaves, backup and deployment scripts.


## Prerequisites

This repository assumes a regular linux distro with the following programs accessible on the cli:
- docker
- mysql

## Usage

TBD. The general idea would be to have frontend.sh expose all functionnalities although
sub-projects should be as disconnected as possible.

For now, one can create a slave instance like this:

`./frontend.sh slave setup # Creates and starts a replication slave`

And remove it with
`./frontend.sh slave remove`

The container can be started/stopped using the start and stop commands
```sh
./frontend.sh slave stop
./frontend.sh slave start
```
