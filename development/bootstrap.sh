#!/usr/bin/env bash

MYSQLD_PID=""

echo "Generating/Regenerating configuration files from templates."

set -a
ENVSUBST_IGNORE='$'
source "../.env"
set +a

envsubst < "config/my.cnf.template" > "config/my.cnf"

echo "Initializing the database data directory if necessary."

function startDatabaseServer () {
    echo "Starting the database server."

    mysqld --defaults-file="config/my.cnf"                    \
           --pid-file="$(pwd)/run/mysqld.pid"                 \
           --socket="$(pwd)/run/mysqld.sock"                  \
           --datadir="$(pwd)/data"                            \
           --log-error="$(pwd)/log/mysqld.error.log"          \
           --general_log_file="$(pwd)/log/mysqld.general.log" \
           --slow_query_log_file="$(pwd)/log/mysqld.slow.log" \
           --log-tc="$(pwd)/log/mysqld.tc.log" &

    MYSQLD_PID="$!"

    echo "Giving it time to start..."

    sleep 5
}

if [ -z "$(ls 'data')" ] ; then
    mysqld --defaults-file="config/my.cnf"                    \
           --pid-file="$(pwd)/run/mysqld.pid"                 \
           --socket="$(pwd)/run/mysqld.sock"                  \
           --datadir="$(pwd)/data"                            \
           --log-error="$(pwd)/log/mysqld.error.log"          \
           --general_log_file="$(pwd)/log/mysqld.general.log" \
           --slow_query_log_file="$(pwd)/log/mysqld.slow.log" \
           --log-tc="$(pwd)/log/mysqld.tc.log"                \
           --initialize-insecure

    startDatabaseServer

    echo "Changing the password for the root database user."

    mysqladmin --defaults-file="config/my.cnf"   \
               --user="root"                     \
               --socket="$(pwd)/run/mysqld.sock" \
               --host="$DATABASE_HOST"           \
               --port="$DATABASE_PORT"           \
               password "$DATABASE_ROOT_PASSWORD" &> log/mysqladmin.error.log
else
    startDatabaseServer
fi

echo "Generating bootstrap SQL data."

cat <<SQL > temp/bootstrap.sql
-- blog
CREATE USER IF NOT EXISTS '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';
CREATE USER IF NOT EXISTS '$DATABASE_USER'@'%' IDENTIFIED BY '$DATABASE_PASSWORD';
CREATE DATABASE IF NOT EXISTS \`$DATABASE_NAME\` DEFAULT CHARACTER SET 'utf8';
GRANT ALL PRIVILEGES ON \`${DATABASE_NAME//_/\\_}\`.* TO '$DATABASE_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`${DATABASE_NAME//_/\\_}\`.* TO '$DATABASE_USER'@'%';
SQL

echo "Bootstrapping the database and its development user."

mysql --defaults-file="config/my.cnf"      \
      --user="root"                        \
      --password="$DATABASE_ROOT_PASSWORD" \
      --socket="$(pwd)/run/mysqld.sock"    \
      --host="$DATABASE_HOST"              \
      --port="$DATABASE_PORT"              \
      --execute="source temp/bootstrap.sql" &> log/mysql.error.log

echo "Stopping the database server."

kill -TERM $MYSQLD_PID
wait $MYSQLD_PID

