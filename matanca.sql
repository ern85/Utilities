SELECT INST_ID,
SID
,      OSUSER
,      MACHINE
,      username
,      MODULE  MODULO
,      Action Usuario
,      SQL_ADDRESS
,      Decode( command, '0','IDLE',
                        '1','CREATE TABLE',
                        '2','INSERT',
                        '3','SELECT',
                        '4','CREATE CLUSTER',
                        '5','ALTER CLUSTER',
                        '6','UPDATE',
                        '7','DELETE',
                        '8','DROP CLUSTER',
                        '9','CREATE INDEX',
                       '10','DROP INDEX',
                       '11','ALTER INDEX',
                       '12','DROP TABLE',
                       '13','CREATE SEQUENCE',
                       '14','ALTER SEQUENCE',
                       '15','ALTER TABLE',
                       '16','DROP SEQUENCE',
                       '17','GRANT',
                       '18','REVOKE',
                       '19','CREATE SYNONYM',
                       '20','DROP SYNONYM',
                       '21','CREATE VIEW',
                       '22','DROP VIEW',
                       '23','VALIDATE INDEX',
                       '24','CREATE PROCEDURE',
                       '25','ALTER PROCEDURE',
                       '26','LOCK TABLE',
                       '27','NO OPERATION',
                       '28','RENAME',
                       '29','COMMENT',
                       '30','AUDIT',
                       '31','NOAUDIT',
                       '32','CREATE DATABASE LINK',
                       '33','DROP DATABASE LINK',
                       '34','CREATE DATABASE',
                       '35','ALTER DATABASE',
                       '36','CREATE ROLLBACK SEGMENT',
                       '37','ALTER ROLLBACK SEGMENT',
                       '38','DROP ROLLBACK SEGMENT',
                       '39','CREATE TABLESPACE',
                       '40','ALTER TABLESPACE',
                       '41','DROP TABLESPACE',
                       '42','ALTER SESSION',
                       '43','ALTER USE',
                       '44','COMMIT',
                       '45','ROLLBACK',
                       '46','SAVEPOINT',
                       '47','PL/SQL EXECUTE',
                       '48','SET TRANSACTION',
                       '49','ALTER SYSTEM SWITCH LOG',
                       '50','EXPLAIN',
                       '51','CREATE USER',
                       '52','CREATE ROLE',
                       '53','DROP USER',
                       '54','DROP ROLE',
                       '55','SET ROLE',
                       '56','CREATE SCHEMA',
                       '57','CREATE CONTROL FILE',
                       '58','ALTER TRACING',
                       '59','CREATE TRIGGER',
                       '60','ALTER TRIGGER',
                       '61','DROP TRIGGER',
                       '62','ANALYZE TABLE',
                       '63','ANALYZE INDEX',
                       '64','ANALYZE CLUSTER',
                       '65','CREATE PROFILE',
                       '66','DROP PROFILE',
                       '67','ALTER PROFILE',
                       '68','DROP PROCEDURE',
                       '69','DROP PROCEDURE',
                       '70','ALTER RESOURCE COST',
                       '71','CREATE SNAPSHOT LOG',
                       '72','ALTER SNAPSHOT LOG',
                       '73','DROP SNAPSHOT LOG',
                       '74','CREATE SNAPSHOT',
                       '75','ALTER SNAPSHOT',
                       '76','DROP SNAPSHOT',
                       '79','ALTER ROLE',
                       '85','TRUNCATE TABLE',
                       '86','TRUNCATE CLUSTER',
                       '88','ALTER VIEW',
                       '91','CREATE FUNCTION',
                       '92','ALTER FUNCTION',
                       '93','DROP FUNCTION',
                       '94','CREATE PACKAGE',
                       '95','ALTER PACKAGE',
                       '96','DROP PACKAGE',
                       '97','CREATE PACKAGE BODY',
                       '98','ALTER PACKAGE BODY',
                       '99','DROP PACKAGE BODY',COMMAND) Acao
,PREV_EXEC_START
--,      SUBSTR(TO_CHAR( PREV_EXEC_START,'DD/MM/YYYY HH24:MI:SS' ), 1, 20 ) INICIO_EXECUCAO
,' alter system kill session '''||sid||','||serial#||',@' || inst_id || ''' IMMEDIATE;' "--Matanca"
 
--  SELECT *
  FROM GV$SESSION
WHERE USERNAME IS NOT NULL
   AND OSUSER <> Sys_Context('userenv','os_user')
   AND STATUS = 'ACTIVE'
   AND USERNAME NOT IN ('SYS','DBSNMP','SYSMAN','SPOTLIGHT')
--  AND USERNAME = 'ICEBERG'
--  AND COMMAND = '7'
--   AND MODULE LIKE '%Pump%'
--   AND sid = 2154
--   AND serial# = 969
--   AND USERNAME LIKE '%GPI%'
ORDER BY PREV_EXEC_START;
-- ORDER BY 2;


   alter system kill session '2155,32455,@1' IMMEDIATE;



SELECT COUNT (*),
        status
        FROM v$session
group by status;


select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||''' IMMEDIATE;'
from v$session
where username is not null
   and status <> 'ACTIVE'
   and username not in ('SYS', 'SYSMAN', 'DBSNMP')
   and last_call_et > 1500;
   
   ALTER SYSTEM DISCONNECT SESSION '50,19867' IMMEDIATE;


select sid,
   serial#,
   status,
   username,
   osuser,
   program,
   blocking_session blocking,
   event
    from v$session
   where blocking_session is not null;
 
SELECT *
  FROM GV$SQLTEXT
 WHERE ADDRESS = '07000107EF33A490'
 ORDER BY PIECE;
 
 
--Sesões travando... 
SELECT c.owner,
  c.object_name,
  c.object_type,
  b.sid,
  b.serial#,
  b.status,
  b.osuser,
  b.machine
FROM v$locked_object a ,
  v$session b,
  dba_objects c
WHERE b.sid     = a.session_id
AND a.object_id = c.object_id;

  

SELECT os_user_name "OS User",
  process "OS Pid",
  oracle_username "Oracle User",
  l.sid "SID",
  DECODE(type, 'MR', 'Media Recovery', 'RT', 'Redo Thread', 'UN', 'User Name', 'TX', 'Transaction', 'TM', 'DML', 'UL', 'PL/SQL User Lock', 'DX', 'Distributed Xaction', 'CF', 'Control File', 'IS', 'Instance State', 'FS', 'File Set', 'IR', 'Instance Recovery', 'ST', 'Disk Space Transaction', 'TS', 'Temp Segment', 'IV', 'Library Cache Invalidation', 'LS', 'Log Start or Switch', 'RW', 'Row Wait', 'SQ', 'Sequence Number', 'TE', 'Extend Table', 'TT', 'Temp Table', type) "Lock Type",
  DECODE(lmode, 0, 'None', 1, 'Null', 2, 'Row-S (SS)', 3, 'Row-X (SX)', 4, 'Share', 5, 'S/Row-X (SSX)', 6, 'Exclusive', lmode) "Lock Held",
  DECODE(request, 0, 'None', 1, 'Null', 2, 'Row-S (SS)', 3, 'Row-X (SX)', 4, 'Share', 5, 'S/Row-X (SSX)', 6, 'Exclusive', request) "Lock Requested",
  DECODE(block, 0, 'Not Blocking', 1, 'Blocking', 2, 'Global', block) "Status",
  owner "Owner",
  object_name "Object name"
FROM v$locked_object lo,
  dba_objects DO,
  v$lock l
WHERE lo.object_id = do.object_id
AND l.sid          = lo.session_id ;











SELECT inst_id,
  COUNT(*)
FROM gv$session
WHERE username IS NOT NULL
GROUP BY inst_id;


select *
  from gv$session
 where inst_id = 1
   and username is not null;
   
  SELECT *
    FROM OCN_FILIAL;
  SELECT *
    FROM SBR_PESSOA_JURIDICA
   WHERE ID_PESSOA = 498312;
   
   06.981.980/0001-37;
   
   
SELECT *
  FROM SBR_NOTAFISCAL --UPDATE SBR_NOTAFISCAL SET ESPECIE_VOLUMES = 'CAIXA', QTDE_VOLUMES = 1
 WHERE ID = 987574;