SELECT S1.INST_ID, S2.PREV_EXEC_START,S1.SQL_ADDRESS,
       S1.USERNAME || '@' || S1.MACHINE || ' ( SID=' || S1.SID || ' )  IS BLOCKING ' ||
       S2.USERNAME || '@' || S2.MACHINE || ' ( SID=' || S2.SID || ' ) '              AS BLOCKING_STATUS
       ,' alter system kill session '''||s1.sid||','||s1.serial#||',@' || S1.inst_id ||''' IMMEDIATE;' "--Matanca"
  FROM GV$LOCK L1, GV$SESSION S1, GV$LOCK L2, GV$SESSION S2
WHERE S1.INST_ID = L1.INST_ID
   AND L1.INST_ID = L2.INST_ID
   AND S1.SID     = L1.SID
	 
   AND S2.SID     = L2.SID
   AND L1.BLOCK   = 1
   AND L2.REQUEST > 0
   AND L1.ID1     = L2.ID1
   AND L2.ID2     = L2.ID2 
;

 
SELECT *
  FROM GV$SQLTEXT
 WHERE ADDRESS = '00000003D24B7B90'
 ORDER BY PIECE;
 

SELECT 
       INST_ID
,      SID
--,      OSUSER
,      MACHINE
,      SQL_ADDRESS
,      Decode( command, '0','IDLE','1','CREATE TABLE','2','INSERT','3','SELECT','4','CREATE CLUSTER','5','ALTER CLUSTER','6','UPDATE','7','DELETE','8','DROP CLUSTER','9','CREATE INDEX','10','DROP INDEX',
												'11','ALTER INDEX','12','DROP TABLE','13','CREATE SEQUENCE','14','ALTER SEQUENCE','15','ALTER TABLE','16','DROP SEQUENCE','17','GRANT','18','REVOKE',
												'19','CREATE SYNONYM','20','DROP SYNONYM','21','CREATE VIEW','22','DROP VIEW','23','VALIDATE INDEX','24','CREATE PROCEDURE','25','ALTER PROCEDURE','26','LOCK TABLE',
												'27','NO OPERATION','28','RENAME','29','COMMENT','30','AUDIT','31','NOAUDIT','32','CREATE DATABASE LINK','33','DROP DATABASE LINK','34','CREATE DATABASE',
												'35','ALTER DATABASE','36','CREATE ROLLBACK SEGMENT','37','ALTER ROLLBACK SEGMENT','38','DROP ROLLBACK SEGMENT','39','CREATE TABLESPACE','40','ALTER TABLESPACE',
												'41','DROP TABLESPACE','42','ALTER SESSION','43','ALTER USE','44','COMMIT','45','ROLLBACK','46','SAVEPOINT','47','PL/SQL EXECUTE','48','SET TRANSACTION',
												'49','ALTER SYSTEM SWITCH LOG','50','EXPLAIN','51','CREATE USER','52','CREATE ROLE','53','DROP USER','54','DROP ROLE','55','SET ROLE','56','CREATE SCHEMA',
												'57','CREATE CONTROL FILE','58','ALTER TRACING','59','CREATE TRIGGER','60','ALTER TRIGGER','61','DROP TRIGGER','62','ANALYZE TABLE','63','ANALYZE INDEX',
												'64','ANALYZE CLUSTER','65','CREATE PROFILE','66','DROP PROFILE','67','ALTER PROFILE','68','DROP PROCEDURE','69','DROP PROCEDURE','70','ALTER RESOURCE COST',
												'71','CREATE SNAPSHOT LOG','72','ALTER SNAPSHOT LOG','73','DROP SNAPSHOT LOG','74','CREATE SNAPSHOT','75','ALTER SNAPSHOT','76','DROP SNAPSHOT','79','ALTER ROLE',
												'85','TRUNCATE TABLE','86','TRUNCATE CLUSTER','88','ALTER VIEW','91','CREATE FUNCTION','92','ALTER FUNCTION','93','DROP FUNCTION','94','CREATE PACKAGE','95','ALTER PACKAGE',
												'96','DROP PACKAGE','97','CREATE PACKAGE BODY','98','ALTER PACKAGE BODY','99','DROP PACKAGE BODY',COMMAND) ACAO
,' alter system kill session '''||sid||','||serial#||',@' || inst_id || ''' IMMEDIATE;' "--Matanca"                        
,      username
,      MODULE  MODULO
,      Action Usuario
,PREV_EXEC_START
--,      SUBSTR(TO_CHAR( PREV_EXEC_START,'DD/MM/YYYY HH24:MI:SS' ), 1, 20 ) INICIO_EXECUCAO

 
--  SELECT *
  FROM GV$SESSION
WHERE USERNAME IS NOT NULL
   AND OSUSER <> Sys_Context('userenv','os_user')
   AND STATUS = 'ACTIVE'
   AND USERNAME NOT IN ('SYS','DBSNMP','SYSMAN','SPOTLIGHT')
--  AND USERNAME = 'ICEBERG'
--  AND COMMAND = '7'	
--  AND COMMAND IN ('2','6','7')
--   AND MODULE LIKE '%Pump%'
--   AND sid = 2154
--   AND serial# = 969
--   AND USERNAME LIKE '%GPI%'
ORDER BY PREV_EXEC_START;
-- ORDER BY 2;





 
--SELECT DISTINCT S.INST_ID, ORACLE_USERNAME USERNAME, OWNER OBJECT_OWNER,
--       OBJECT_NAME, OBJECT_TYPE, S.OSUSER, S.SID, S.SADDR, ACTION, OSUSER, USERNAME, TERMINAL,
--       DECODE(L.BLOCK,0,'NOT BLOCKING', 1,'BLOCKING',2,'GLOBAL') STATUS,
--       DECODE(V.LOCKED_MODE,0,'NONE',1,'NULL',2,'ROW-S (SS)',3,'ROW-X (SX)',4,'SHARE',5,'S/ROW-X (SSX)',6,'EXCLUSIVE', TO_CHAR(LMODE)) MODE_HELD,
--       ' alter system kill session '''||s.sid||','||s.serial#||',@' || S.inst_id ||''' IMMEDIATE;' Matanca
-- 
--  FROM GV$LOCKED_OBJECT V, DBA_OBJECTS D, GV$LOCK L, GV$SESSION S
--WHERE V.INST_ID    = S.INST_ID
--   AND V.INST_ID    = L.INST_ID
--   AND V.OBJECT_ID  = D.OBJECT_ID
--   AND V.OBJECT_ID  = L.ID1
--   AND V.SESSION_ID = S.SID
----order by object_name	 
	 ;
	 


 




	SELECT
		username,
		s.process,
		s.command,
		s.program ,
		s.osuser osuser ,
		s.sid sid ,
		s.serial# serial ,
		l.lmode lmode ,
		DECODE(L.LMODE,1,'No Lock', 2,'Row Share', 3,'Row Exclusive', 4,'Share', 5,'Share Row Exclusive', 6,'Exclusive','NONE') lmode_desc ,
		l.type type ,
		DECODE(l.type,'BL','Buffer hash table instance lock', 'CF',' Control file schema global enqueue lock', 'CI','Cross-instance function invocation instance lock', 'CS','Control file schema global enqueue lock', 'CU','Cursor bind lock', 'DF','Data file instance lock', 'DL','Direct loader parallel index create', 'DM','Mount/startup db primary/secondary instance lock', 'DR','Distributed recovery process lock', 'DX','Distributed transaction entry lock', 'FI','SGA open-file information lock', 'FS','File set lock', 'HW','Space management operations on a specific segment lock', 'IN','Instance number lock', 'IR','Instance recovery serialization global enqueue lock', 'IS','Instance state lock', 'IV','Library cache invalidation instance lock', 'JQ','Job queue lock', 'KK','Thread kick lock', 'MB','Master buffer hash table instance lock', 'MM','Mount definition gloabal enqueue lock', 'MR','Media recovery lock', 'PF','Password file lock', 'PI','Parallel operation lock', 'PR','Process startup lock'
		, 'PS','Parallel operation lock', 'RE','USE_ROW_ENQUEUE enforcement lock', 'RT','Redo thread global enqueue lock', 'RW','Row wait enqueue lock', 'SC','System commit number instance lock', 'SH','System commit number high water mark enqueue lock', 'SM','SMON lock', 'SN','Sequence number instance lock', 'SQ','Sequence number enqueue lock', 'SS','Sort segment lock', 'ST','Space transaction enqueue lock', 'SV','Sequence number value lock', 'TA','Generic enqueue lock', 'TD','DDL enqueue lock', 'TE','Extend-segment enqueue lock', 'TM','DML enqueue lock', 'TT','Temporary table enqueue lock', 'TX','Transaction enqueue lock', 'UL','User supplied lock', 'UN','User name lock', 'US','Undo segment DDL lock', 'WL','Being-written redo log instance lock', 'WS','Write-atomic-log-switch global enqueue lock') type_desc ,
		request ,
		block
				FROM
		v$lock l ,
		v$session s
			WHERE
		s.sid = l.sid AND l.type <> 'MR' AND s.type <> 'BACKGROUND' AND (block = 1 OR request > 0)
ORDER BY
		username;




	 
	 
	 
select * from v$lock;


select 	p.spid,
	s.username,
	s.osuser,
	s.machine,
	p.program,
	l.lmode,
	l.block
from 	v$session s,
	v$process p,
	v$lock l
where	s.paddr = p.addr
AND	L.SID = S.SID
and 	s.username is not null;