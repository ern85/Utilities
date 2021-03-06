SELECT 'TBL' ORIGEM, TABLE_NAME, 'EXEC DBMS_STATS.GATHER_TABLE_STATS(''' || OWNER || ''',''' || TABLE_NAME || ''',CASCADE => TRUE);' DBMS_EXEC
  FROM DBA_TABLES
WHERE OWNER = 'SIGA'
   AND (
   TABLE_NAME LIKE 'SBR%' OR
   TABLE_NAME LIKE 'SGN%' OR
   TABLE_NAME LIKE 'OCN%' OR
   TABLE_NAME LIKE 'CRM%' OR
   TABLE_NAME LIKE 'CRS%' OR
   TABLE_NAME LIKE 'CRW%' OR
   TABLE_NAME LIKE 'CRQ%' OR
   TABLE_NAME LIKE 'ECM%' OR
   TABLE_NAME LIKE 'SZ%'
    );