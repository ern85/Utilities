select   ddf.tablespace_name "TablespaceName"

         , ddf.file_name "DataFile"

         , ddf.bytes/(1024*1024) "Total(MB)"

         , round((ddf.bytes - sum(nvl(dfs.bytes,0)))/(1024*1024),1) "Used(MB)"

         , round(sum(nvl(dfs.bytes,0))/(1024*1024),1) "Free(MB)"

from   sys.dba_free_space dfs left join sys.dba_data_files ddf

on      dfs.file_id = ddf.file_id

group by ddf.tablespace_name, ddf.file_name, ddf.bytes

order by ddf.tablespace_name, ddf.file_name;

