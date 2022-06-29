break on sql_text
col sql_text for a60
col "CPU (Minutos)" for 99.99
 
 
SELECT * 
  FROM (SELECT sql_text,
               executions, 
               rows_processed, 
               rows_processed/executions "Rows/Exec",
               disk_reads, 
               round(((cpu_time/1000000)/60),2) "CPU (Minutes)"
          FROM V$SQLAREA
         WHERE executions > 100
         ORDER BY executions DESC)
  WHERE rownum <= 10 ; 