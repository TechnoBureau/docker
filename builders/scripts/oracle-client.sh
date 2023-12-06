#!/bin/sh
### For Oracle DB
mkdir -p /opt/technobureau/oracle/lib
mv /tmp/instantclient_21_9/* /opt/technobureau/oracle/lib/
sh -c "echo /opt/technobureau/oracle/lib > /mnt/rootfs/etc/ld.so.conf.d/oracle-instantclient.conf"