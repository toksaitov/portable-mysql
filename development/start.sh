#!/usr/bin/env bash

PIDS=""

echo "Generating/Regenerating configuration files from templates."

set -a
ENVSUBST_IGNORE='$'
source "../.env"
set +a

envsubst < "config/my.cnf.template" > "config/my.cnf"

echo "Starting the database server."

mysqld --defaults-file="config/my.cnf"                    \
       --pid-file="$(pwd)/run/mysqld.pid"                 \
       --socket="$(pwd)/run/mysqld.sock"                  \
       --port="$BLOG_DATABASE_PORT"                       \
       --datadir="$(pwd)/data"                            \
       --log-error="$(pwd)/log/mysqld.error.log"          \
       --general_log_file="$(pwd)/log/mysqld.general.log" \
       --slow_query_log_file="$(pwd)/log/mysqld.slow.log" \
       --log-tc="$(pwd)/log/mysqld.tc.log" &> log/mysqld.std.log &

echo "Giving it time to start..."

sleep 5

PIDS="$!"

function cleanup () {
    echo "Cleaning up..."

    for pid in $PIDS; do
        kill -TERM $pid
    done
}

trap cleanup INT

for pid in $PIDS; do
    wait $pid
done
