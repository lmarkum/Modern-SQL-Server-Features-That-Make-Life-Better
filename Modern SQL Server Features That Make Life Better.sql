/*                                                                                                                                                                                                        dWWI.sql***/

https://github.com/microsoft/bobsql/tree/master/sql2019book 

*/
USE WideWorldImporters
GO

-- Build a new rowmode table called OrderHistory based off of Orders
DROP TABLE IF EXISTS Sales.InvoiceLinesExtended
GO

SELECT 'Building InvoiceLinesExtended from InvoiceLines...'
GO

CREATE TABLE [Sales].[InvoiceLinesExtended](
	[InvoiceLineID] [int] IDENTITY NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[LineProfit] [decimal](18, 2) NOT NULL,
	[ExtendedPrice] [decimal](18, 2) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Sales_InvoiceLinesExtended] PRIMARY KEY CLUSTERED 
(
	[InvoiceLineID] ASC
))
GO

CREATE INDEX IX_StockItemID
ON Sales.InvoiceLinesExtended([StockItemID])
WITH(DATA_COMPRESSION=PAGE)
GO

INSERT Sales.InvoiceLinesExtended(InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
SELECT InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen
FROM Sales.InvoiceLines
GO

-- Table should have 228,265 rows
SELECT 'Number of rows in Sales.InvoiceLinesExtended = ', COUNT(*) FROM Sales.InvoiceLinesExtended
GO

SELECT 'Increasing number of rows for InvoiceLinesExtended...'
GO
-- Make the table bigger
INSERT Sales.InvoiceLinesExtended(InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
SELECT InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen
FROM Sales.InvoiceLinesExtended
GO 4

-- Table should have 3,652,240 rows
SELECT 'Number of rows in Sales.InvoiceLinesExtended = ', COUNT(*) FROM Sales.InvoiceLinesExtended
GO

SELECT COUNT(DISTINCT(StockItemID)) FROM Sales.InvoiceLinesExtended




/***mysmartslqquery.sql***/


USE WideWorldImporters
GO
SELECT si.CustomerID, sil.InvoiceID, sil.LineProfit
FROM Sales.Invoices si
INNER JOIN Sales.InvoiceLines sil
ON si.InvoiceID = si.InvoiceID
OPTION (MAXDOP 1)
GO


/***

Run this in another Window

Show_Active_Queries.sql

***/

-- Step 1: Only show requests with active queries except for this one
SELECT er.session_id, er.command, er.status, er.wait_type, er.cpu_time, er.logical_reads, eqsx.query_plan, t.text
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_query_statistics_xml(er.session_id) eqsx
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) t
WHERE er.session_id <> @@SPID
GO
 
-- Step 2: What does the plan profile look like for the active query
SELECT session_id, physical_operator_name, node_id, thread_id, row_count, estimate_row_count
FROM sys.dm_exec_query_profiles
WHERE session_id <> @@SPID
ORDER BY session_id, node_id DESC
GO

-- Step 3: Go back and look at the plan and query text for a clue in the Nested Loop
SELECT er.session_id, er.command, er.status, er.wait_type, er.cpu_time, er.logical_reads, eqsx.query_plan, t.text
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_query_statistics_xml(er.session_id) eqsx
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) t
WHERE er.session_id <> @@SPID
GO


/***Demonstrating Temporal Tables

Copyright Lee Markum July 2021

***/

USE [CollegeFootball]
GO

/****** 

Create Backup of Table to Test Temporal Tables and add a Primary Key. 
System-versioned tables have to have a PK

******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[WinLossMajorNCAASchoolsBackup];
GO
CREATE TABLE [dbo].[WinLossMajorNCAASchoolsBackup]
(ID INT IDENTITY(1,1) NOT NULL,
	[School] [varchar](100) NULL,
	[StartYear] [int] NULL,
	[EndYear] [int] NULL,
	[NumofYearsPlayed] [tinyint] NULL,
	[OverallGamesPlayed] [smallint] NULL,
	[OverallWins] [smallint] NULL,
	[OverallLosses] [smallint] NULL,
	[OverallTies] [tinyint] NULL,
	[OverallWinningPercentage] [float] NULL,
	[TotalBowlGames] [tinyint] NULL,
	[BowlGamesWon] [tinyint] NULL,
	[BowlGamesLossed] [tinyint] NULL,
	[BowlGamesTied] [tinyint] NULL,
	[BowlGamesWinningPercentage] [float] NULL,
	[SimpleRatingSystem] [float] NULL,
	[StrengthOfSchedule] [float] NULL,
	[NumOfYearsRankedInFinalAPPoll] [tinyint] NULL,
	[ConferenceChampionships] [tinyint] NULL,
	[Notes] [nvarchar](255) NULL
) ON [PRIMARY]
GO
ALTER TABLE WinLossMajorNCAASchoolsBackup ADD CONSTRAINT PK_WinLossMajorNCAASchoolsBackup PRIMARY KEY CLUSTERED (ID)

--Load source data to my new table
INSERT INTO WinLossMajorNCAASchoolsBackup
SELECT *
FROM dbo.WinLossMajorNCAASchools
GO
--Create schema to hold system-versoined tables
CREATE SCHEMA History;

GO
/**
Change existing table to set up system-versioning by adding the required SysStartTime and SysendTime columns

These columns will be used to determine when a version of the row was in the temporal/source table.
*/

ALTER TABLE WinLossMajorNCAASchoolsBackup
	ADD SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN
		     CONSTRAINT DF_SysStart DEFAULT SYSUTCDATETIME()
      , SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN
            CONSTRAINT DF_SysEnd DEFAULT CONVERT(DATETIME2, '9999-12-31 23:59:59.9999999')
        ,PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);
GO
/*
Enable system-versioning using a named history table. 

You can let the SQL Server give it a name, but naming it makes things cleaner and more consistent
*/
ALTER TABLE WinLossMajorNCAASchoolsBackup 
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.WinLossMajorNCAASchoolsBackup));

--Review the contents of both tables
SELECT *
FROM dbo.WinLossMajorNCAASchoolsBackup;


SELECT *
FROM History.WinLossMajorNCAASchoolsBackup

/*
Update some rows. 

Apparently Air Force started playing football in 1957. Let's change that!

*/
UPDATE dbo.WinLossMajorNCAASchoolsBackup
SET StartYear = 1900 
	WHERE School = 'Air Force';

/*Akron was never good at football so let's delete that school*/
DELETE dbo.WinLossMajorNCAASchoolsBackup
WHERE School = 'Akron';

--Review the contents of both tables. Akron is gone and Air Force's start year is now 1900.
SELECT *
FROM dbo.WinLossMajorNCAASchoolsBackup
WHERE School = 'Air Force' OR School = 'Akron';

/*
The two changes are recorded in the History table.

Note the System Start and End Time values for each row are recorded.

This time range represents when this version of the record was "active" in the table dbo.WinLossMajorNCAASchoolsBackup
*/
SELECT SysStartTime, SysEndTime, *
FROM History.WinLossMajorNCAASchoolsBackup;

/*Post demo cleanup*/
ALTER TABLE dbo.WinLossMajorNCAASchoolsBackup SET (System_Versioning = OFF);
DROP TABLE History.WinLossMajorNCAASchoolsBackup;
DROP SCHEMA History;
GO

/*Creating a table as a temporal table from the start*/

CREATE SCHEMA History;
GO
DROP TABLE IF EXISTS dbo.Employee;
GO

CREATE TABLE dbo.Employee
(
ID INT IDENTITY(1,1) NOT NULL,
LastName VARCHAR(100) NOT NULL,
FirstName VARCHAR(75) NOT NULL,
JobTitle VARCHAR(50) NOT NULL,
BirthDate DATE NOT NULL,
HireDate DATE NOT NULL,
SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
 PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime),
CONSTRAINT PK_Employees PRIMARY KEY CLUSTERED (ID),
INDEX IX_LastName_FirstName (LastName,FirstName),

)
WITH (SYSTEM_VERSIONING = ON(HISTORY_TABLE = History.EmployeeHistory,
/*By default history is kept permanently, but the below is one way to 
specify how long to keep the data in the history table.
Options for retention are DAYS, WEEKS, MONTHS, YEARS
*/
History_Retention_Period = 6 months
));

--ALTER TABLE dbo.Employee ADD CONSTRAINT Default_SysStart DEFAULT SYSUTCDATETIME() FOR SysStartTime;
--ALTER TABLE dbo.Employee ADD CONSTRAINT Default_SysEndTime DEFAULT SYSUTCDATETIME() FOR SysEndTime;

ALTER TABLE dbo.Employee SET (System_Versioning = OFF);
DROP TABLE History.EmployeeHistory;
DROP TABLE dbo.Employee;
DROP SCHEMA History;

/*
https://learn.microsoft.com/en-us/sql/relational-databases/tables/changing-the-schema-of-a-system-versioned-temporal-table?view=sql-server-ver16

https://learn.microsoft.com/en-us/sql/relational-databases/tables/temporal-table-considerations-and-limitations?view=sql-server-ver16

You can:
Add a column to the temporal table and it is added for you to the history table.

Change the data type of a column in the temporal table and it is changed for you in the history table.

You can drop a column in the temporal table and it will be dropped from the history table.

Some other types of changes, like truncating a table, require that system versioning be
	set to OFF first, then make the change and then set system versioning on.



*/

/***Demonstrate T-SQL Enhancements***/


/*Demonstrate Drop If Exists*/
--Execute to make the table, then execute again to simulate a deployment script and note the error.
  USE DBAUTility;
  GO

  CREATE TABLE MyTestTable
  (
  ID INT IDENTITY (1,1),
  ProductName VARCHAR (100)
  )

--A previous method to test for existence then drop if it exists. 

IF EXISTS (
  SELECT 1 FROM sys.objects
  WHERE object_id = object_id(N'[dbo].[MyTestTable]')
    AND type in (N'U') 
)
BEGIN
  DROP TABLE [dbo].[MyTestTable]
END;


--Drop If Exists. 

DROP TABLE IF EXISTS MyTestTable


/****Demonstrate CREATE OR ALTER****/

USE DBAUtility;
GO
CREATE OR ALTER PROC GetSQLServerVersions 
AS 
BEGIN
	SELECT TOP 5*
	FROM dbo.SqlServerVersions
END

--Returns 5 rows just as defined above
EXEC GetSQLServerVersions

USE DBAUtility;
GO
CREATE OR ALTER PROC GetSQLServerVersions 
AS 
BEGIN
	SELECT TOP 50*
	FROM dbo.SqlServerVersions
END

--Returns 50 rows just as defined above
EXEC GetSQLServerVersions


/****Demonstrate Inline specification for Indexes****/
USE DBAUtility;
GO
DROP TABLE IF Exists t1;

--filtered index
CREATE TABLE t1
(
    c1 INT,
    index IX1 (c1) WHERE c1 > 0
);

DROP TABLE IF Exists t2;

--multi-column index
CREATE TABLE t2
(
    c1 INT,
    c2 INT,
    INDEX ix_1 NONCLUSTERED (c1,c2)
);

DROP TABLE IF Exists t3;

--multi-column unique index
CREATE TABLE t3
(
    c1 INT,
    c2 INT,
    INDEX ix_1 UNIQUE NONCLUSTERED (c1,c2)
);

DROP TABLE IF Exists t4;
-- make unique clustered index
CREATE TABLE t4
(
    c1 INT,
    c2 INT,
    INDEX ix_1 UNIQUE CLUSTERED (c1,c2)
);



/****Demonstrate TRIM versus LTRIM/RTRIM

https://www.sqlshack.com/sql-trim-function/ 

***/
SELECT TRIM( ' This is a test    ') AS Result;
SELECT RTRIM(LTRIM(' This is a test    ')) AS Result;


SELECT DATALENGTH(TRIM( ' This is a test    ')) AS Result;
SELECT DATALENGTH(LTRIM(' This is a test    ')) AS Result;
SELECT DATALENGTH(RTRIM(' This is a test    ')) AS Result;
SELECT DATALENGTH(RTRIM(LTRIM(' This is a test    '))) AS Result;

DECLARE @String VARCHAR(24)= 'ApplicationA';
SELECT @String as OriginalString, 
       TRIM('A' from @String) AS StringAfterTRIM, 
       DATALENGTH(@String) AS 'DataLength String (Bytes)', 
       DATALENGTH( TRIM('A' from @String) ) AS 'DataLength String (Bytes) After TRIM';
