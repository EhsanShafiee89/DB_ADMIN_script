----------------------------------Space Srv
CREATE table #ls (name varchar(255), LogSize real, LogSpaceUsed real, Status int) 
SELECT * FROM #ls
insert #ls exec ('dbcc sqlperf(logspace)') 

declare @name varchar(255), @sql varchar(1000); 

select d.name, DATABASEPROPERTYEX(d.name, 'Status') Status, 
   case when DATABASEPROPERTYEX(d.name, 'IsAutoCreateStatistics') = 1
      then 'ON' else 'OFF' end AutoCreateStatistics, 
   case when DATABASEPROPERTYEX(d.name, 'IsAutoUpdateStatistics') = 1
      then 'ON' else 'OFF' end AutoUpdateStatistics, 
   case when DATABASEPROPERTYEX(d.name, 'IsAutoShrink') = 1
      then 'ON' else 'OFF' end AutoShrink, 
   case when DATABASEPROPERTYEX(d.name, 'IsAutoClose') = 1
      then 'ON' else 'OFF' end AutoClose, 
   DATABASEPROPERTYEX(d.name, 'Collation') Collation, 
   DATABASEPROPERTYEX(d.name, 'Updateability') Updateability,
   DATABASEPROPERTYEX(d.name, 'UserAccess') UserAccess, 
   replace(page_verify_option_desc, '_', ' ') PageVerifyOption, 
   d.compatibility_level CompatibilityLevel, 
   DATABASEPROPERTYEX(d.name, 'Recovery') RecoveryModel,
   convert(bigint, 0) as Size, convert(bigint, 0) Used, 
   case when sum(NumberReads+NumberWrites) > 0
      then sum(IoStallMS)/sum(NumberReads+NumberWrites) else -1 end AvgIoMs,
   ls.LogSize, ls.LogSpaceUsed, 
   b.backup_start_date LastBackup
INTO #dbs1
--_temp_CARD..Databases_info
   
from master.sys.databases as d 
left join msdb..backupset b
   on d.name = b.database_name and b.backup_start_date = (
      select max(backup_start_date)
      from msdb..backupset
      where database_name = b.database_name
      and type = 'D') 
left join ::fn_virtualfilestats(-1, -1) as vfs
   on d.database_id = vfs.DbId 
join #ls as ls
   on d.name = ls.name 
group by d.name, DATABASEPROPERTYEX(d.name, 'Status'), 
case when DATABASEPROPERTYEX(d.name, 'IsAutoCreateStatistics') = 1
   then 'ON' else 'OFF' end, 
case when DATABASEPROPERTYEX(d.name, 'IsAutoUpdateStatistics') = 1
   then 'ON' else 'OFF' end, 
case when DATABASEPROPERTYEX(d.name, 'IsAutoShrink') = 1
   then 'ON' else 'OFF' end, 
case when DATABASEPROPERTYEX(d.name, 'IsAutoClose') = 1
   then 'ON' else 'OFF' end, 
DATABASEPROPERTYEX(d.name, 'Collation'), 
DATABASEPROPERTYEX(d.name, 'Updateability'), 
DATABASEPROPERTYEX(d.name, 'UserAccess'), 
page_verify_option_desc, 
d.compatibility_level, 
DATABASEPROPERTYEX(d.name, 'Recovery'), 
ls.LogSize, ls.LogSpaceUsed, b.backup_start_date; 

create table #dbsize1 (
   fileid int,
   filegroup int,
   TotalExtents bigint,
   UsedExtents bigint,
   dbname varchar(255),
   FileName varchar(255)); 

declare c1 cursor for select name from #dbs1; 
open c1; 

fetch next from c1 into @name; 
while @@fetch_status = 0 
begin 
   set @sql = 'use [' + @name + ']; DBCC SHOWFILESTATS WITH NO_INFOMSGS;' 
   insert #dbsize1 exec(@sql); 
   update #dbs1 
   set Size = (select sum(TotalExtents) / 16 from #dbsize1),
      Used = (select sum(UsedExtents) / 16 from #dbsize1) 
   where name = @name; 
   truncate table #dbsize1; 
   fetch next from c1 into @name; 
end; 
close c1; 
deallocate c1; 
--drop table #dbsize1; 
--drop table #dbs1;
--drop table #ls;
-------------------------------Time_BackUp---------------------------------------------
SELECT 
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
WHEN 'D' THEN 'Database' 
WHEN 'L' THEN 'Log' 
END AS backup_type, 
msdb.dbo.backupset.backup_size, 
msdb.dbo.backupmediafamily.logical_device_name, 
msdb.dbo.backupmediafamily.physical_device_name, 
msdb.dbo.backupset.name AS backupset_name, 
msdb.dbo.backupset.description INTO ##Space_118
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
--AND msdb..backupset.type  IN ('d')
ORDER BY 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_finish_date 

------------------------Pivot--------------------------------------------------------------------------
SELECT database_name 'Name',[DataBase] AS 'Full',[Diff] AS 'Diff' ,[Log] AS 'Log' INTO #temp
 FROM ( 
 SELECT database_name, ISNULL(backup_type,'Diff') backup_type  FROM ##space_118
 ) AS p
 PIVOT 
 (
 COUNT(backup_type)
  FOR backup_type  IN ([Diff],[Database],[Log])
  ) AS PivoteTable
  --ORDER BY p.Backup_Type

----------------------------------------------------------------------------------------------
SELECT d.name,Size+d.LogSize AS 'SizeMG',RecoveryModel,t.[FULL] AS 'Time_Full/Date',t.diff AS 'Time_Diff/Date',t.Log  AS 'Time_Log/Date' 
FROM #dbs1 d
LEFT OUTER JOIN #temp t ON d.name=t.Name
ORDER BY DB_ID(d.name)

---------------------------------------------------------
