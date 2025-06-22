GO

/****** Object:  View [dbo].[TablNeedSHRINK]    Script Date: 11/11/2017 10:08:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[TablNeedSHRINK]
AS
    SELECT  S.name AS [Name] ,
            S.physical_name AS [FileName] ,
            S.size * CONVERT(FLOAT, 8) / 1024 AS [Size] ,
            CAST(CASE S.type
                   WHEN 2 THEN 0
                   ELSE CAST(FILEPROPERTY(S.name, 'SpaceUsed') AS FLOAT)
                        * CONVERT(FLOAT, 8)
                 END AS FLOAT) / 1024 AS [UsedSpace] ,
            ( S.size * CONVERT(FLOAT, 8)
              - CAST(CASE S.type
                       WHEN 2 THEN 0
                       ELSE CAST(FILEPROPERTY(S.name, 'SpaceUsed') AS FLOAT)
                            * CONVERT(FLOAT, 8)
                     END AS FLOAT) ) / 1024 AS FreeSpace ,
            S.file_id AS [ID]
    FROM    sys.database_files AS D WITH ( READUNCOMMITTED )
            INNER JOIN sys.master_files AS S WITH ( READUNCOMMITTED ) ON D.physical_name COLLATE Arabic_CI_AS = S.physical_name COLLATE Arabic_CI_AS
  --      INNER JOIN sys.master_files AS s ON --( s.database_id = DB_ID()
  ----                                            
  ----                                          )
  ----                                          AND
		--									 ( s.data_space_id = D.data_space_id )
  --                                          AND s.database_id = DB_ID()
  --                                          AND ( s.drop_lsn IS NULL )
		----( s.type = 2
  ----                                              OR s.type = 0
  ----                                            ) sys.master_files
--WHERE (CAST(cast(g.name as varbinary(256)) AS sysname)='ReportDBTXT_89')
--DBCC SHRINKFILE (N'ReportDBTXT_89' , 289333)

GO


