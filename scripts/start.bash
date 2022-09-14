#!/bin/bash

# Environment Variables Needed Here

# export SA_PASSWORD=
# export MSSQL_DB_NAME
# export MSSQL_DB_USER
# export MSSQL_DB_PASS


_term() {
  echo "Stopping SQL Server..."
  pkill -SIGINT -c -e sql
  sleep 2
  pkill -SIGTERM -c -e sql
}

echo "Starting SQL Server..."

# Remove running/healthcheck marker
[ -f "/var/opt/mssql/sql-server-up.marker" ] && rm /var/opt/mssql/sql-server-up.marker

# remove prior runtime log - this outputs to docker anyway.
[ -f "/tmp/sqlserver.log" ] && rm /tmp/sqlserver.log

# Block outside connections until ready
iptables -A INPUT -p tcp -s 127.0.0.1 --destination-port 1433 -j ACCEPT
iptables -A INPUT -p tcp --destination-port 1433 -j DROP

# run SQL Server in the background
nohup /opt/mssql/bin/sqlservr --accept-eula 2>&1 > /tmp/sqlserver.log &

# capture the child process reference
child=$!

# start outputting the sqlserver.log to stdout (detached)
tail -q --retry -n 1000 -f /tmp/sqlserver.log &

# trap for SIGTERM, forward to child
trap _term SIGTERM

# wait for SQL Server to be ready to accept connections
grep -q "Service Broker manager has started" <(tail -q --retry -n 1000 -f /tmp/sqlserver.log)
sleep 3
echo "SQL Server Started, "

# Run script that accepts variables that will create database and user if needed
[[ -v SA_PASSWORD ]] && \
&& echo "Initializing Database..." \
&& /opt/mssql-tools/bin/sqlcmd \
    -S tcp:127.0.0.1,1433 \
    -U SA \
    -P "$SA_PASSWORD" \
    -v "MSSQL_DB_NAME=$MSSQL_DB_NAME" \
    -v "MSSQL_DB_USER=$MSSQL_DB_USER" \
    -v "MSSQL_DB_PASS=$MSSQL_DB_PASS" \
    -i /scripts/init-databases.sql \
&& echo "Databases Initialized"


# Remove existing iptables rules, and allow app 1433 connections for mssql
sleep 1
iptables -D INPUT -p tcp -s 127.0.0.1 --destination-port 1433 -j ACCEPT
iptables -D INPUT -p tcp --destination-port 1433 -j DROP
iptables -I INPUT -p tcp --destination-port 1433 -j ACCEPT
touch /var/opt/mssql/sql-server-up.marker

echo "Ready for connections"

# Unblock/allow connections
wait "$child"