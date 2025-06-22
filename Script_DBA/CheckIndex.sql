SELECT 
     TableName = t.name,
     IndexName = ind.name,
     IndexId = ind.index_id,
     ColumnId = ic.index_column_id,
     ColumnName = col.name INTO #B
     --ind.*,
     --ic.*,
     --col.* 
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t ON ind.object_id = t.object_id 
WHERE    ind.type=1
    -- ind.is_primary_key = 1 
     -- ind.is_unique = 0 
   --and  ind.is_unique_constraint = 0 
   --  AND t.is_ms_shipped = 0 
--ORDER BY  t.name, ind.name, ind.index_id, ic.is_included_column, ic.key_ordinal;


 --DROP TABLE  #C
SELECT B.*,C.DATA_TYPE,I.name INTO #C FROM #B as B LEFT OUTER JOIN INFORMATION_SCHEMA.COLUMNS  AS C
ON B.TableName=C.TABLE_NAME AND B.ColumnName=C.COLUMN_NAME 
LEFT OUTER JOIN sys.identity_columns AS I ON  C.TABLE_NAME= OBJECT_NAME(I.object_id) AND c.COLUMN_NAME=I.name

--SELECT OBJECT_NAME(object_id),*
--FROM sys.identity_columns

SELECT * FROM  #C
 
--SELECT B.*,I.DATA_TYPE INTO #C FROM #B as B LEFT OUTER JOIN INFORMATION_SCHEMA.COLUMNS  AS I
--ON B.TableName=I.TABLE_NAME AND B.ColumnName=I.COLUMN_NAME


--SELECT TableName,IndexName,IndexId,ColumnName,DATA_TYPE,CASE WHEN name IS NOT NULL THEN 'True' ELSE 'False' END IS_identity  FROM  #C
--WHERE TableName NOT  IN  (
--SELECT TableName FROM  #C
--GROUP BY TableName
--HAVING COUNT(*)>1)
--ORDER BY DATA_TYPE

--SELECT * FROM  #C
--WHERE TableName IN  (
--SELECT TableName FROM  #C
--GROUP BY TableName
--HAVING COUNT(*)>1)
--ORDER BY TableName




