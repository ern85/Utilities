select * from (
  SELECT
  tbl.table_name,
  tbl.num_rows,
  (select COUNT(COLUMN_NAME) from dba_tab_columns where table_name = UPPER(tbl.table_name) ) total_colunas,
  (select COUNT(*) from dba_indexes idx where idx.table_name = tbl.table_name) as TOTAL_INDICES,
  (SELECT constraint_name FROM user_constraints WHERE UPPER(table_name) = UPPER(tbl.table_name) AND CONSTRAINT_TYPE = 'P') AS coluna_pk
  FROM
    user_tables tbl
  where
  (
    tbl.table_name like 'SBR%' or
    tbl.table_name like 'OCN%' or
    tbl.table_name like 'ESB%' or
    tbl.table_name like 'CRM%' or
    tbl.table_name like 'ECM%'
  )
  and tbl.num_rows is not null
  group by table_name,tbl.num_rows
)
where
TOTAL_INDICES = 0
--and num_rows > 1000
and coluna_pk is null
order by num_rows desc
;