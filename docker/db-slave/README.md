Replication slave
=================

Creates a mysql docker container configured to replicate the production server.
`conf/` is mounted to the container's /etc/mysql/conf.d and contains a configuration file
edited on the fly to contain appropriate host values.

The container exports it's mysql port to the host's $SLAVE_EXPORTED_PORT (default 3300)
