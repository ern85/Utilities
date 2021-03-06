SELECT * 
  FROM DBA_DATA_FILES;
  
CREATE TABLESPACE rman DATAFILE '+DATA/desenv/datafile/rman01.dbf' size 100M AUTOEXTEND ON NEXT 20M MAXSIZE 2000M force logging;
  
SELECT *
  FROM DBA_USERS;
  
CREATE USER rman IDENTIFIED BY rman DEFAULT TABLESPACE RMAN TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON RMAN;

GRANT RECOVERY_CATALOG_OWNER TO rman;
GRANT CONNECT, RESOURCE TO rman;

SELECT *
  FROM DBA_TABLES
 WHERE TABLESPACE_NAME = 'RMAN';
 
SELECT *
  FROM RMAN.rc_DATABASE;
SELECT *
  FROM RMAN.RC_BACKUP_PIECE_DETAILS;
SELECT *
  FROM RMAN.RC_BACKUP_SET;
SELECT *
  FROM RMAN.RC_RMAN_BACKUP_JOB_DETAILS;
  
SELECT LOG_MODE
  FROM V$DATABASE;
  
SELECT *
  FROM V_$RMAN_STATUS
  ORDER BY COMMAND_ID DESC;