     DECLARE @ProcDate VARCHAR(MAX);
	 DECLARE @part VARCHAR(2);
	 DECLARE @Table VARCHAR(max);

	  DECLARE date_cursor CURSOR
        FOR
            --SELECT  FarsiDate
            --FROM    CommonDB..DateTbl
            --WHERE   FarsiDate > @MinDate
            --        AND FarsiDate <= @MaxDate
            --ORDER BY FarsiDate;
	--SELECT  ' ALTER TABLE [ReportDBTXT].'+ [table] +' REBUILD PARTITION = '+CAST([partition]AS CHAR(2))+' WITH (ONLINE = on ,DATA_COMPRESSION = PAGE) ; ',[table],[partition]
	--   FROM PartitionControlTable ORDER BY sizeDAtA DESC
	--		 WHERE sizedata>'444816 KB' AND [table] LIKE 'Imported.%'
	--		 AND Compression<>'PAGE'
	--		ORDER BY [table]DESC,[partition] ASC
			SELECT  ' ALTER TABLE [ReportDBTXT].'+ [table] +' REBUILD PARTITION = '+CAST([partition]AS CHAR(2))+' WITH (ONLINE = off ,DATA_COMPRESSION = PAGE) ; '
			,[table],[partition]
	   FROM PartitionControlTable_new --ORDER BY sizeDAtA DESC
			 WHERE  [table] LIKE 'Imported.%' AND [partition]>13  AND Compression<>'PAGE' AND [table] LIKE '%Journal%' AND Partition BETWEEN 14 AND 15
			 ORDER BY sizeDAtA

        OPEN date_cursor;

        FETCH NEXT FROM date_cursor INTO @ProcDate,@Table,@part

        WHILE @@FETCH_STATUS = 0 AND GETDATE()<'2019-01-19 22:55:45.183'
            BEGIN
		
		UPDATE dbo.PartitionControlTable_New
		SET Sdate=GETDATE()
	    WHERE  [table]=@Table AND [partition]=@part          
                EXEC (@ProcDate);
				
		UPDATE  dbo.PartitionControlTable_New
		SET	Ndate=GETDATE(),Compression='Page'
				WHERE  [table]=@Table AND [partition]=@part

       DBCC SHRINKFILE (N'ReportDBTXT_log' , 0, TRUNCATEONLY)
                FETCH NEXT FROM date_cursor INTO @ProcDate,@Table,@part

            END; 
		
        CLOSE date_cursor;
        DEALLOCATE date_cursor;

		--SELECT GETDATE()
		--2018-10-13 16:00:45.183

		--ALTER TABLE [ReportDBTXT].Imported.Kart REBUILD PARTITION = 14 WITH (ONLINE = on ,DATA_COMPRESSION = PAGE)

		 --ALTER TABLE [ReportDBTXT].Imported.GLIF REBUILD PARTITION = 14 WITH (ONLINE = on ,DATA_COMPRESSION = PAGE) ; 

--EXEC dbo.sp_SHRINK_2 @Run = 0, -- bit
--    @Top = 50, -- int
--    @Drv = 'h', -- char(1)
--    @MinSize = 500, -- int
--    @Split = 500 -- int
