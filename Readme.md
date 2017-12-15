portable-mysql
==============

Scripts to make MySQL portable.

## Required Software

* _MySQL (>= 5.7.18) in PATH_

## Usage

Create an `.env` file with secrets and parameters for all the components.

```bash
# Database
DATABASE_HOST=the location of the database server
DATABASE_PORT=the database port
DATABASE_NAME=the name of the database
DATABASE_USER=the user of the database with write permissions
DATABASE_PASSWORD=his pasword (can be empty)
```

Ensure that `mysqld` binary is in the `PATH` environment variable.

```bash
cd development
./bootstrap # create the database; run the script only once
./start     # start MySQL with the local database and the blog server
```

## Credits

Toksaitov Dmitrii Alexandrovich (<dmitrii@toksaitov.com>)
