-- N'$(MSSQL_DB_NAME)'
-- N'$(MSSQL_DB_USER)'
-- N'$(MSSQL_DB_PASS)'

DECLARE @HasDb BOOLEAN = FALSE
DECLARE @HasUser BOOLEAN = FALSE

-- Create Database if it's declared and not setup
IF (LEN(N'$(MSSQL_DB_NAME)') > 0)
BEGIN
  SET @HasDb = TRUE
  IF NOT EXISTS(select *
  from sys.databases
  where name = N'$(MSSQL_DB_NAME)')
  BEGIN
    CREATE DATABASE [$(MSSQL_DB_NAME)]
  END
END
GO

-- Create User if it's declared and not setup
IF (LEN(N'$(MSSQL_DB_USER)') > 0 AND LEN(N'$(MSSQL_DB_USER)') > 0)
BEGIN
  SET @HasUser = TRUE
  IF NOT EXISTS (
    SELECT name
    FROM master.sys.server_principals
    WHERE name = N'$(MSSQL_DB_USER)'
  )
  BEGIN
    CREATE LOGIN [$(MSSQL_DB_USER)] with PASSWORD=N'$(MSSQL__ST_PASS)', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  END
END
GO

-- If user and db are not declared, jump to end of script
IF (@HasDb = FALSE OR @HasUser = FALSE)
BEGIN
  GOTO EndOfScript
END

-- Ensure the User has DBO for the database
USE [$(MSSQL_DB_NAME)]
IF NOT EXISTS(
  SELECT *
  FROM sys.database_principals
  WHERE NAME = N'$(MSSQL_DB_USER)'
)
BEGIN
  CREATE USER [$(MSSQL_DB_USER)] FOR LOGIN [$(MSSQL_DB_USER)]
  EXEC sp_addrolemember N'db_owner', N'$(MSSQL_DB_USER)'
END
GO


-- Finished Initialization
EndOfScript: