--Mother of all search queries 
--Sam Nesbitt
--v1
--2016-03-01

--user definable
declare @colType		int
declare @searchData		varchar(50)
declare @searchOpp		varchar(10)	--enter seach opperator
declare @searchTable	varchar(100)

set @colType = 61			--56:int, 61:datetime, 104:bit --http://avian.netne.net/blog/?p=277
set @searchData = '''2000-03-31'''		--Enter search data here, add '' for text
set @searchOpp = '<='				--Enter your search opporator here							--'<='
set @searchTable = '%'				--Give the query a hint to the column name its looking for	--'%start_dt%','%'

--table to store search results
IF OBJECT_ID('tempdb..##searchResults') IS NOT NULL
	DROP TABLE ##searchResults
CREATE TABLE ##searchResults(
	tableName	varchar(100)
	,columnName	varchar(100)
	,result		datetime		--make sure this data type matches the type specified by @colType
)

--system use
declare @tableName	varchar(100)
declare @colName	varchar(100)

--tables and columns that will be searched
declare @searchTables table(
	tableName	varchar(100)
	,columnName	varchar(100)
)

insert into @searchTables
select QUOTENAME(d.TableName), QUOTENAME(d.ColName)
from
	(SELECT c.name AS ColName, t.name AS TableName
	FROM sys.columns c
		JOIN sys.tables t ON c.object_id = t.object_id
	WHERE c.name LIKE @searchTable
		and c.system_type_id = @colType	--is datetime
	) as d

--create a cursor for memory table
declare c1 cursor read_only
for select tableName, columnName
from @searchTables

print 'begin queries'

open c1
fetch next from c1
into @tableName, @colName

while @@FETCH_STATUS = 0
begin

	--magic happens here
	EXEC
	( 
		'INSERT INTO ##searchResults select ''' + @tableName + ''', ''' + @colName + ''', d.' + @colName + ' from' +
		'(SELECT ' + @colName
		+ ' from dbo.' + @tableName
		+ ' where ' + @colName + ' ' + @searchOpp + ' ' + @searchData + ' ) as d'
	)
	
	--dump queries to log
	print 'INSERT INTO ##searchResults select ''' + @tableName + ''', ''' + @colName + ''', d.' + @colName + ' from' +
		'(SELECT ' + @colName
		+ ' from dbo.' + @tableName
		+ ' where ' + @colName + ' ' + @searchOpp + ' ' + @searchData + ' ) as d'
	
	fetch next from c1
	into @tableName, @colName
end

close c1
deallocate c1

--select * from @searchTables
--select * from ##searchResults

--pull summary of results here
select tableName, columnName, count(result)
from ##searchResults
group by tableName, columnName
order by tableName, columnName

--comment this out if you want to use the results before they are dropped
IF OBJECT_ID('tempdb..##searchResults') IS NOT NULL
	DROP TABLE ##searchResults
