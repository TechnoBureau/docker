#!/bin/sh
cd /opt/
mv /tmp/go/* /opt/

go mod init tgo
go mod tidy
go build -o $WORKDIR/bin/tgo main.go