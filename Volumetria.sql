SELECT *
  FROM dba_indexes
 WHERE TABLE_OWNER = 'SIGA'
   AND STATUS = 'UNUSABLE';

SELECT *
  FROM SYS.index_stats;
  
  
select *
  from dba_lobs
 where 
 segment_name = 'SYS_LOB0000527410C00005$$';--621
  
 ALTER TABLE SIGA.CRM_SMTP_EMAIL MODIFY LOB(MENSAGEM)(SHRINK SPACE);

SELECT *
  FROM crm_smtp_email;
  
ANALYZE INDEX OCN_REF_PRODUTO_PK VALIDATE STRUCTURE;
ANALYZE INDEX OCN_REF_PRODUTO_PK VALIDATE STRUCTURE;

SELECT *
  FROM OCN_REF_PRODUTO;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tamanho de Cada Tabela
  SELECT owner
       , tablespace_name
       , segment_name 
       , round(sum(bytes/1024/1024),2) as Tamanho_MB 
       , extents as Num_extents
    FROM dba_segments
   WHERE 
--   tablespace_name = 'CRMLOGDATA'
   owner = 'OCEAN'
--     AND segment_type = 'TABLE'
--     AND segment_name like 'SBR_EXECUCAO_JOB'
  GROUP BY owner, tablespace_name, segment_name, extents
  ORDER BY TAMANHO_MB DESC;
  
----


 
 select *
   from crm_smtp_email;

truncate table siga.SBR_EXECUCAO_JOB;



SELECT *
  FROM dba_segments
 WHERE SEGMENT_NAME LIKE '%SYS_LOB0000564535C00004$$%';
 
select *
  from crm_smtp_email;


alter table crm_smtp_email enable row movement;  
alter table crm_smtp_email modify lob (MENSAGEM) (shrink space);

alter table crm_smtp_email deallocate unused;
alter table crm_smtp_email shrink space compact;

alter table crm_smtp_email shrink space compact;

select * from dba_datapump_jobs;

select * from user_recyclebin;
drop table crm_smtp_email;
purge recyclebin;

select * from dba_lobs;




select *
  from dba_tab_columns
 where table_name like '%CRM_SMTP%';
 
select *
  from crm_smtp_email;

SELECT *
  FROM OCN_INFO_PRODUTO;
  
  
SELECT Count(1),
       To_Char(NTIMESTAMP#, 'YYYY')
  FROM sys.aud$
 GROUP BY To_Char(NTIMESTAMP#, 'YYYY');




select * from dba_tables where ((length(table_name) = 6 and table_name like '_____0') OR TABLE_NAME LIKE 'RC%') and owner = 'SIGA';

SELECT *
-- DELETE 
  FROM se5010;
 WHERE dh_acess < SYSDATE -1;
 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Tamanho das Tabelas Por Usuário

SELECT owner
     , round(sum(bytes/1024/1024),2) as Tamanho_MB 
--     , extents as Num_extents
  FROM dba_segments
  GROUP BY owner;
  
--------------------------------------------------------------------------------  
--------------------------------------------------------------------------------
--Tamanho Total das Tabelas

SELECT round(sum(bytes/1024/1024),2) as Tamanho_MB 
--, extents as Num_extents
 FROM dba_segments;
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- % de Uso das TableSpaces

SELECT T1.TABLESPACE_NAME TableSpace_Name
     , round(T1.BYTES/1024/1024) MB_Allocated
     , round((T1.BYTES-nvl(T2.BYTES, 0)) / 1024 / 1024) MB_Used
     , nvl(round(T2.BYTES / 1024 / 1024), 0) MB_Free
     , round(((T1.BYTES-nvl(T2.BYTES, 0))/T1.BYTES)*100,2) Pct_Used
     , round((1-((T1.BYTES-nvl(T2.BYTES,0))/T1.BYTES))*100,2) Pct_Free
  FROM (SELECT TABLESPACE_NAME
             , sum(BYTES) BYTES
          FROM dba_data_files
         GROUP BY TABLESPACE_NAME) T1,
       (SELECT TABLESPACE_NAME
             , sum(BYTES) BYTES
          FROM sys.dba_free_space
         GROUP BY TABLESPACE_NAME) T2
         WHERE T1.TABLESPACE_NAME = T2.TABLESPACE_NAME (+)
         ORDER BY ((T1.BYTES-T2.BYTES)/T1.BYTES);


--------------------------------------------------------------------------------
--Tamanho do banco

select sum(bytes) / 1024 / 1024 / 1024 as GB from dba_segments;

----------------------

------Analyse tables
EXEC DBMS_STATS.gather_database_stats(estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, cascade => TRUE);

------

Status ASM
SELECT name
     , state
     , total_mb
     , free_mb 
  FROM v$asm_diskgroup;



--------------------------------------------------------------------------------         
         
         
alter database datafile '/home/oracle/ROLLOUT/crmlogdata01.dbf' autoextend on next 100m maxsize 10000m;         
ALTER tablespace SYSTEM add datafile '/home/oracle/ROLLOUT/system02.dbf' size 512m;         
         
SELECT *
  FROM dba_data_files;
  
SELECT *
  FROM dba_tablespaces;
  
truncate table sys.AUD$;


SELECT COUNT (*)FROM AUD$;

SELECT COUNT (*),
        status
        FROM v$session
group by status;

--Geração de archives
 SELECT I.INSTANCE_NAME, To_Char(AL.COMPLETION_TIME,'YYYYMMDD') DATA_ARCHIVE, Count(1) QTD_ARCHIVE, Round(Sum(BLOCKS * BLOCK_SIZE/1024/1024),2) TOT_MB 
  FROM GV$ARCHIVED_LOG AL
  
 INNER JOIN GV$INSTANCE I ON I.INST_ID = AL.INST_ID
 
 WHERE 1 = 1
   AND 1 = 1
 GROUP BY I.INSTANCE_NAME, To_Char(AL.COMPLETION_TIME,'YYYYMMDD')
 ORDER BY To_Char(AL.COMPLETION_TIME,'YYYYMMDD') DESC, I.INSTANCE_NAME;
 
 
-- Verifica ASM

 SELECT 'OK' asm_monitor ,
  a.name,
  a.total_mb ,
  ROUND(a.total_mb -a.free_mb,2) used_mb ,
  ROUND((a.total_mb-a.free_mb)*100 / a.total_mb,2) pct_used ,
  a.free_mb,
  ROUND((a.free_mb*100) / a.total_mb,2) pct_free ,
  b.MOUNT_STATUS,
  b.MODE_STATUS,
  b.STATE,
  c.status
FROM V$ASM_DISKGROUP a ,
  V$ASM_DISK b ,
  V$ASM_CLIENT c
WHERE a.group_number                       = b.group_number
AND a.group_number                         = c.group_number
AND b.MOUNT_STATUS                         = 'OPENED'
AND b.MODE_STATUS                          = 'ONLINE'
AND b.STATE                                = 'NORMAL'
AND c.status                               = 'CONNECTED'
AND ROUND((a.free_mb*100) / a.total_mb,2) >= 5
UNION
SELECT 'NOT OK' asm_monitor ,
  a.name,
  a.total_mb ,
  ROUND(a.total_mb -a.free_mb,2) used_mb ,
  ROUND((a.total_mb-a.free_mb)*100 / a.total_mb,2) pct_used ,
  a.free_mb,
  ROUND((a.free_mb*100) / a.total_mb,2) pct_free ,
  b.MOUNT_STATUS,
  b.MODE_STATUS,
  b.STATE,
  c.status
FROM V$ASM_DISKGROUP a ,
  V$ASM_DISK b ,
  V$ASM_CLIENT c
WHERE a.group_number                     = b.group_number
AND a.group_number                       = c.group_number
AND ( b.MOUNT_STATUS                    <> 'OPENED'
OR b.MODE_STATUS                        <> 'ONLINE'
OR b.STATE                              <> 'NORMAL'
OR c.status                             <> 'CONNECTED'
OR ROUND((a.free_mb*100) / a.total_mb,2) < 5 ) ;


select * FROM V$ASM_DISKGROUP 

