 SELECT SID,
   USERNAME,
   ROUND(TOTAL_USER_MEM/1024,2) MEM_USED_IN_KB,
   ROUND(100           * TOTAL_USER_MEM/TOTAL_MEM,2) MEM_PERCENT
   FROM
   (SELECT B.SID SID,
      NVL(B.USERNAME,P.NAME) USERNAME,
      SUM(VALUE) TOTAL_USER_MEM
      FROM SYS.V_$STATNAME C,
      SYS.V_$SESSTAT A,
      SYS.V_$SESSION B,
      SYS.V_$BGPROCESS P
     WHERE A.STATISTIC#=C.STATISTIC#
   AND P.PADDR (+)     = B.PADDR
   AND B.SID           =A.SID
   AND C.NAME         IN ('session pga memory','session uga memory')
  GROUP BY B.SID,
      NVL(B.USERNAME,P.NAME)
   ),
   (SELECT SUM(VALUE) TOTAL_MEM
      FROM SYS.V_$STATNAME C,
      SYS.V_$SESSTAT A
     WHERE A.STATISTIC#=C.STATISTIC#
   AND C.NAME         IN ('session pga memory','session uga memory')
   )
ORDER BY 3 DESC;
