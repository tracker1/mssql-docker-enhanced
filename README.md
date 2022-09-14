# mssql-docker-enhanced - Enhanced MSSQL Docker Container(s)

Dockerfile and Scripts to create an enhanced mssql container.

- Waits for the server to actually be ready before allowing connections
- Initializes a Database and User/Password for that database.

These are not published anywhere, you'll need to build yourself, this is for
demonstration.

## Notes/Warnings

- Needs testing, this is modified from another project rather quickly to try to
  simplify the output... should work, but untested in this repo.
- Must run in `privileged` mode (uses iptables internally).
- Cannot use in a read-only manner.
- Uses output redirection to a runtime file internally.

## MSSQL With Database/User creation on start.

You'll want to pass the following environment variables at (first) startup to
ensure a database is created, and a user is created and dbo for that database.

- `SA_PASSWORD` - Used for SA Account creation, and to run scritps to create
  db/user
- `MSSQL_DB_NAME` - Database Name to Create
- `MSSQL_DB_USER` - User login to Create
- `MSSQL_DB_PASS` - Password to use for the User specified upon creation
- `ACCEPT_EULA` - Accept MSSQL EULA (`Y` is the value you must use)
- `MSSQL_PID` (optional) - Product ID To Use (`Developer` is default)

## scripts

The `scripts/` directory will be mounted into `/scripts` and is added to the
path.

All files in `scripts/` _should_ be marked `+x`, on container initialization, if
this is not the case, you can run `chmod +x /scripts/*` inside the container.

## License

MIT Licensed
