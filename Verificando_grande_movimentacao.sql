SELECT to_char(begin_interval_time,'YY-MM-DD HH24') snap_time,
        dhso.object_name,
        sum(db_block_changes_delta) BLOCK_CHANGED
  FROM dba_hist_seg_stat dhss,
       dba_hist_seg_stat_obj dhso,
       dba_hist_snapshot dhs
  WHERE dhs.snap_id = dhss.snap_id
    AND dhs.instance_number = dhss.instance_number
    AND dhss.obj# = dhso.obj#
    AND dhss.dataobj# = dhso.dataobj#
    AND begin_interval_time BETWEEN to_date('20170320 08:00','YYYYMMDD HH24:MI')
                                AND to_date('20170320 10:00','YYYYMMDD HH24:MI')
  GROUP BY to_char(begin_interval_time,'YY-MM-DD HH24'),
           dhso.object_name
  HAVING sum(db_block_changes_delta) > 0
ORDER BY sum(db_block_changes_delta) desc ;

SELECT *
  FROM OCN_RESOURCES
 WHERE CHAVE LIKE '%ead%';


SELECT * FROM DBA_ROLLBACK_SEGS WHERE STATUS <> 'OFFLINE';
  
  
  
  
  
  
  