DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
  cCommand VARCHAR2(500) := '';
BEGIN

  Dbms_Output.ENABLE(1000000);

  FOR TBL IN ( SELECT *
                 FROM DBA_TABLES TBL
                WHERE OWNER      = cSchema
                  AND NOT EXISTS ( SELECT 1
                                     FROM DBA_SYNONYMS
                                    WHERE OWNER       = 'PUBLIC'
                                      AND TABLE_OWNER = TBL.OWNER
                                      AND TABLE_NAME  = TBL.TABLE_NAME ) )
  LOOP
    cCommand := 'CREATE OR REPLACE PUBLIC SYNONYM ' || TBL.TABLE_NAME || ' FOR ' || TBL.OWNER || '.' || TBL.TABLE_NAME;

    Dbms_Output.PUT_LINE(cCommand);
    EXECUTE IMMEDIATE (cCommand);
  END LOOP;

END;
/


select *
  from OCEAN.sbr_cfop_sped

DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
  cCommand VARCHAR2(500) := '';
BEGIN

  Dbms_Output.ENABLE(1000000);

  FOR PROC IN ( SELECT *
                 FROM DBA_PROCEDURES PROC
                WHERE OWNER      = cSchema
                  AND OBJECT_TYPE IN ('FUNCTION','PROCEDURE')
                  AND NOT EXISTS ( SELECT 1
                                     FROM DBA_SYNONYMS
                                    WHERE OWNER       = 'PUBLIC'
                                      AND TABLE_OWNER = PROC.OWNER
                                      AND TABLE_NAME  = PROC.OBJECT_NAME ) )
  LOOP
    cCommand := 'CREATE OR REPLACE PUBLIC SYNONYM ' || PROC.OBJECT_NAME || ' FOR ' || PROC.OWNER || '.' || PROC.OBJECT_NAME;

    Dbms_Output.PUT_LINE(cCommand);
    EXECUTE IMMEDIATE (cCommand);
  END LOOP;

END;
/

DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
  cCommand VARCHAR2(500) := '';
BEGIN

  Dbms_Output.ENABLE(1000000);

  FOR SEQ IN ( SELECT *
                 FROM DBA_SEQUENCES SEQ
                WHERE SEQUENCE_OWNER = cSchema
                  AND NOT EXISTS     ( SELECT 'x'
                                         FROM DBA_SYNONYMS
                                        WHERE OWNER        = 'PUBLIC'
                                          AND TABLE_OWNER  = SEQ.SEQUENCE_OWNER
                                          AND SYNONYM_NAME = Upper(SEQ.SEQUENCE_NAME) ) )
  LOOP
    cCommand := 'CREATE OR REPLACE PUBLIC SYNONYM ' || SEQ.SEQUENCE_NAME || ' FOR ' || SEQ.SEQUENCE_OWNER || '.' || SEQ.SEQUENCE_NAME;

    Dbms_Output.PUT_LINE(cCommand);
    EXECUTE IMMEDIATE (cCommand);
  END LOOP;

END;
/

DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
  cCommand VARCHAR2(500) := '';
BEGIN

  Dbms_Output.ENABLE(1000000);

  FOR V IN ( SELECT *
               FROM DBA_VIEWS V
              WHERE OWNER = cSchema
                AND NOT EXISTS     ( SELECT 'x'
                                       FROM DBA_SYNONYMS
                                      WHERE OWNER        = 'PUBLIC'
                                        AND TABLE_OWNER  = V.OWNER
                                        AND SYNONYM_NAME = RTrim(Trim(V.VIEW_NAME),Chr(13) || Chr(10)) ) )
  LOOP
    cCommand := 'CREATE OR REPLACE PUBLIC SYNONYM ' || Trim(V.VIEW_NAME) || ' FOR ' || V.OWNER || '.' || Trim(V.VIEW_NAME);

    Dbms_Output.PUT_LINE(cCommand);
    EXECUTE IMMEDIATE (cCommand);
  END LOOP;

END;
/

DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
  cTablename VARCHAR2(30) := '';
BEGIN

  Dbms_Output.ENABLE(NULL);

  FOR tab IN ( SELECT *
                 FROM DBA_TABLES TAB
                WHERE OWNER      = cSchema
                  AND NOT EXISTS ( SELECT 'x'
                                     FROM DBA_TAB_PRIVS
                                    WHERE GRANTEE    = 'APLICATIVOS'
                                      AND OWNER      = TAB.OWNER
                                      AND TABLE_NAME = TAB.TABLE_NAME ) )

  LOOP
      cTablename := tab.TABLE_NAME;
      Dbms_Output.PUT_LINE('GRANT ALL ON ' || cSchema || '.' || tab.TABLE_NAME || ' TO APLICATIVOS');
      EXECUTE IMMEDIATE (  'GRANT ALL ON ' || cSchema || '.' || tab.TABLE_NAME || ' TO APLICATIVOS');
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    Dbms_Output.Put_Line('Erro Geral -> ' || SQLERRM || '(' || SQLCODE || ') - ' || cTablename);
END;
/

DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
BEGIN

  Dbms_Output.ENABLE(1000000);

  FOR PROC IN ( SELECT *
                 FROM DBA_PROCEDURES PROC
                WHERE OWNER      = cSchema
                  AND OBJECT_TYPE IN ('FUNCTION','PROCEDURE')
                  AND NOT EXISTS ( SELECT 'x'
                                     FROM DBA_TAB_PRIVS
                                    WHERE GRANTEE    = 'APLICATIVOS'
                                      AND OWNER      = PROC.OWNER
                                      AND TABLE_NAME = PROC.OBJECT_NAME ) )
  LOOP
    Dbms_Output.PUT_LINE('GRANT ALL ON ' || PROC.OBJECT_NAME || ' TO APLICATIVOS');
    EXECUTE IMMEDIATE (  'GRANT ALL ON ' || PROC.OBJECT_NAME || ' TO APLICATIVOS');
  END LOOP;

END;
/

DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
BEGIN

  Dbms_Output.ENABLE(NULL);

  FOR tab IN ( SELECT *
                 FROM DBA_SEQUENCES TAB
                WHERE SEQUENCE_OWNER = cSchema
                  AND NOT EXISTS     ( SELECT 'x'
                                     FROM DBA_TAB_PRIVS
                                    WHERE GRANTEE    = 'APLICATIVOS'
                                      AND OWNER      = TAB.SEQUENCE_OWNER
                                      AND TABLE_NAME = Upper(TAB.SEQUENCE_NAME) ) )

  LOOP

    Dbms_Output.PUT_LINE('GRANT ALL ON ' || tab.SEQUENCE_NAME || ' TO APLICATIVOS');
    EXECUTE IMMEDIATE (  'GRANT ALL ON ' || tab.SEQUENCE_NAME || ' TO APLICATIVOS');
   END LOOP;
END;
/

DECLARE
  cSchema  VARCHAR2(030) := 'OCEAN';
BEGIN

  Dbms_Output.ENABLE(NULL);

  FOR tab IN ( SELECT *
                 FROM DBA_VIEWS TAB
                WHERE OWNER = cSchema

                  AND NOT EXISTS ( SELECT 1
                                     FROM DBA_OBJECTS OBJ
                                    WHERE OBJ.OWNER = TAB.OWNER
                                      AND OBJ.OBJECT_NAME = TAB.VIEW_NAME
                                      AND OBJ.STATUS = 'INVALID' )
                  AND NOT EXISTS ( SELECT 'x'
                                     FROM DBA_TAB_PRIVS
                                    WHERE OWNER      = TAB.OWNER
                                      AND GRANTEE    = 'APLICATIVOS'
                                      AND TABLE_NAME = TAB.VIEW_NAME ) )

  LOOP

    Dbms_Output.PUT_LINE('GRANT ALL ON ' || tab.VIEW_NAME || ' TO APLICATIVOS');
    EXECUTE IMMEDIATE (  'GRANT ALL ON ' || tab.VIEW_NAME || ' TO APLICATIVOS');
   END LOOP;
END;
/



SELECT 'DROP PUBLIC SYNONYM ' || SYNONYM_NAME || ';'
  FROM DBA_SYNONYMS S
 WHERE OWNER = 'PUBLIC'
   AND TABLE_OWNER = 'SIGA'
   AND NOT EXISTS (SELECT * FROM DBA_OBJECTS T WHERE T.OWNER = S.TABLE_OWNER AND T.OBJECT_NAME = S.TABLE_NAME);


SELECT *
  FROM USER_ROLE_PRIVS
 WHERE USERNAME = 'CAIO';

SELECT *
  FROM DBA_SYNONYMS
 WHERE OWNER = 'PUBLIC'
   AND SYNONYM_NAME LIKE 'BI_LOG_CONSULTOR%';

SELECT *
  FROM DBA_TAB_PRIVS
 WHERE OWNER   = 'SIGA'
   AND GRANTEE = 'CAIO'
   AND TABLE_NAME LIKE 'CRM_VIS%';

SELECT *
  FROM DBA_ROLE_PRIVS
 WHERE GRANTED_ROLE = 'DBA';

--CREATE USER MARIANA IDENTIFIED BY alpharomeo DEFAULT TABLESPACE MSIGADATA
--GRANT FINANCEIRO TO MARIANA


SELECT *
  FROM DBA_ROLES;

--GRANT PCP TO EDIVAN
--REVOKE PCP FROM EDIVAN

SELECT *
  FROM ROLE_TAB_PRIVS
 WHERE ROLE = 'FINANCEIRO' AND TABLE_NAME = 'SE1010';

SELECT *
  FROM DBA_USERS
 ORDER BY USERNAME;

SELECT 'GRANT SELECT ON ' || TABLE_NAME || ' TO PCP;'
  FROM DBA_TABLES
 WHERE OWNER = 'SIGA'
   AND (    TABLE_NAME LIKE '%SB1%'
         OR TABLE_NAME LIKE '%SD3%'
         OR TABLE_NAME LIKE '%SD4%'
         OR TABLE_NAME LIKE '%SC2%'
         OR TABLE_NAME LIKE '%SG1%'
         OR TABLE_NAME LIKE '%SB2%'
         OR TABLE_NAME LIKE '%SB4%' )
 ORDER BY TABLE_NAME