#!/bin/sh
cd /opt/
mv /tmp/go/* /opt/

go mod init tgo
go mod tidy
go build -ldflags="-s -w" -o $WORKDIR/bin/tgo main.go