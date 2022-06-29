  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_USUARIO_SUBORDINADO" ("ID", "ID_USUARIO", "ID_SUBORDINADO") AS 
  SELECT DISTINCT "ID",
    "ID_USUARIO",
    "ID_SUBORDINADO"
  FROM
    (SELECT GCS.ID_USUARIO * GC.ID_USUARIO ID,
      GC.ID_USUARIO,
      GCS.ID_USUARIO ID_SUBORDINADO
    FROM OCEAN.CRM_VIEW_GRUPO_COLABORADOR GC,
      OCEAN.CRM_VIEW_GRUPO_COLABORADOR GCS,
      OCEAN.OCN_USUARIO U,
      OCEAN.OCN_USUARIO S
    WHERE (GCS.ID_GRUPO IN
      (SELECT DISTINCT ID
      FROM OCEAN.CRM_GRUPO G
        START WITH G.ID_GRUPO_SUPERIOR = GC.ID_GRUPO
        CONNECT BY PRIOR G.ID          = G.ID_GRUPO_SUPERIOR
      )
    OR GCS.ID_GRUPO    = GC.ID_GRUPO)
    AND GCS.ID_USUARIO = S.ID
    AND GC.ID_USUARIO  = U.ID
    AND U.ATIVO        = 1
    AND (U.CRM_DIRETOR = 1
    OR U.CRM_GERENTE   = 1
    OR U.GESTOR        = 1)
    AND S.ATIVO        = 1
    AND S.CRM_DIRETOR  = 0
    AND S.ID          <> U.ID
    AND EXISTS
      (SELECT 1
      FROM OCEAN.OCN_USUARIO_FILIAL UFU
      WHERE UFU.ID_USUARIO = U.ID
      AND UFU.ID_FILIAL   IN
        (SELECT UFS.ID_FILIAL
        FROM OCEAN.OCN_USUARIO_FILIAL UFS
        WHERE UFS.ID_USUARIO = S.ID
        )
      )
    )
 ;
"
 
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_RESERVA_FATURAMENTO" ("ID", "DATA_ATENDIMENTO", "DATA_VALIDADE", "EMISSAO", "LIBERA_PARCIAL", "ID_LOTE", "NUMERO_RESERVA", "PRIORIDADE", "QTD_ORIGINAL", "SALDO_RESERVADO", "STATUS", "ID_ARMAZEM", "ID_EMPRESA", "ID_FILIAL", "ID_PEDIDO", "ID_PEDIDO_ITEM", "ID_PRE_SEPARACAO", "ID_PRODUTO", "ID_FILIAL_FATURAMENTO", "SALDO_ARMAZEM") AS 
  SELECT RF.ID,
    RF.DATA_ATENDIMENTO,
    RF.DATA_VALIDADE,
    RF.EMISSAO,
    RF.LIBERA_PARCIAL,
    RF.ID_LOTE,
    RF.NUMERO_RESERVA,
    RF.PRIORIDADE,
    RF.QTD_ORIGINAL,
    RF.SALDO_RESERVADO,
    RF.STATUS,
    RF.ID_ARMAZEM,
    RF.ID_EMPRESA,
    RF.ID_FILIAL,
    RF.ID_PEDIDO,
    RF.ID_PEDIDO_ITEM,
    RF.ID_PRE_SEPARACAO,
    RF.ID_PRODUTO,
    RF.ID_FILIAL_FATURAMENTO,
    SA.SALDO AS SALDO_ARMAZEM
  FROM SBR_RESERVA_FATURAMENTO RF,
    SBR_PED_VENDA_ITEM PVI,
    SBR_SALDO_ARMAZEM SA
  WHERE PVI.SEQUENCIA     <> 4
  AND SA.ID_ARMAZEM        = RF.ID_ARMAZEM
  AND SA.ID_PRODUTO        = RF.ID_PRODUTO
  AND RF.STATUS            = 'APROVADA'
  AND RF.DATA_ATENDIMENTO IS NULL
  AND RF.ID_PRE_SEPARACAO IS NULL
  AND RF.SALDO_RESERVADO   <= SA.SALDO
  AND PVI.ID               = RF.ID_PEDIDO_ITEM
  AND SA.SALDO > 0
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_PESSOA_SEG_TRAT_AUTO" ("ID_PESSOA", "ID_SEGMENTO", "PERCENTUAL") AS 
  (SELECT ID_DESTINATARIO AS ID_PESSOA,
    ID_SEGMENTO_PRODUTO   AS ID_SEGMENTO,
    PERCENTUAL
  FROM
    (SELECT X.*,
      Y.QTD_PRODUTOS_GERAL,
      TRUNC((QTD_PRODUTOS * 100) / Y.QTD_PRODUTOS_GERAL) AS PERCENTUAL
    FROM
      (SELECT ID_DESTINATARIO,
        ID_SEGMENTO_PRODUTO,
        ID_SEGMENTO_SUPERIOR_PRODUTO,
        SUM(QTD_PRODUTOS) AS QTD_PRODUTOS
      FROM
        (SELECT VENDAS.*,
          SEGMENTO_PRODUTO.ID_SEGMENTO_PRODUTO,
          SEGMENTO_PRODUTO.ID_SEGMENTO_SUPERIOR_PRODUTO
        FROM
          (SELECT *
          FROM
            (SELECT NF.ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE,
              ROUND(COUNT(PB.ID),2) AS QTD_PRODUTOS
            FROM OCN_PRODUTO P
            INNER JOIN OCN_PRODUTO_BASE PB
            ON PB.ID             = P.ID_PRODUTO_BASE
            AND PB.TIPO_PRODUTO IN ('ME','PA','IP')
            INNER JOIN
              (SELECT NFI.*
              FROM SBR_NOTAFISCAL_ITEM NFI
              WHERE NFI.ID_NOTAFISCAL_ITEM_REF IS NULL
              OR NOT EXISTS
                (SELECT 'x'
                FROM SBR_NOTAFISCAL_ITEM NFI
                INNER JOIN SBR_NOTAFISCAL NF
                ON NF.ID         = NFI.ID_NOTAFISCAL
                WHERE NF.TIPO_NF = 'D'
                )
              )NFI ON NFI.ID_PRODUTO = P.ID
            INNER JOIN SBR_TIPO_MOV_FISCAL TMF
            ON TMF.ID         = NFI.ID_TIPO_MOV_FISCAL
            AND OPERA_ESTOQUE =1
            INNER JOIN SBR_NOTAFISCAL NF
            ON NF.ID            = NFI.ID_NOTAFISCAL
            AND NF.NOTA_PROPRIA = 1
            AND NF.TIPO_NF      = 'N'
            AND NF.TIPO_ES      = '1'
            INNER JOIN SBR_PESSOA PS
            ON PS.ID = NF.ID_DESTINATARIO
            LEFT JOIN SBR_PESSOA_SEGMENTO PG
            ON PG.ID_PESSOA  = PS.ID
            AND PG.PRINCIPAL = 1
            AND PG.FORMA     = 'A'
            LEFT JOIN OCN_SEGMENTO S
            ON S.ID                       = PG.ID_SEGMENTO
            WHERE NF.ID_DESTINATARIO NOT IN
              (SELECT DISTINCT ID_PESSOA FROM OCN_FILIAL
              )
            GROUP BY NF.ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE
            UNION ALL
            SELECT DISTINCT C.ID_PESSOA AS ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE,
              ROUND(COUNT(P.ID_PRODUTO_BASE),2) AS QTD_PRODUTOS
            FROM SBR_CLI_PRODUTO CP
            INNER JOIN OCN_PRODUTO P
            ON P.ID = CP.ID_PRODUTO
            INNER JOIN SBR_CLIENTE C
            ON C.ID = CP.ID_CLIENTE
            LEFT JOIN SBR_PESSOA_SEGMENTO PG
            ON PG.ID_PESSOA  = C.ID_PESSOA
            AND PG.PRINCIPAL = 1
            AND PG.FORMA     = 'A'
            LEFT JOIN OCN_SEGMENTO S
            ON S.ID = PG.ID_SEGMENTO
            GROUP BY C.ID_PESSOA,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE
            )
          ) VENDAS
        LEFT JOIN
          (SELECT X.*,
            S.ID_SUPERIOR AS ID_SEGMENTO_SUPERIOR_PRODUTO
          FROM
            (SELECT PB.ID     AS ID_PRODUTO_BASE,
              PBT.ID_SEGMENTO AS ID_SEGMENTO_PRODUTO
            FROM OCN_REF_SEGMENTO_PRODUTO PBT
            INNER JOIN OCN_PRODUTO_BASE PB
            ON PB.ID_SERIAL = PBT.ID_SERIAL_BASE
            WHERE PBT.TIPO  = 'TRATAMENTO'
            ) X
          INNER JOIN OCN_SEGMENTO S
          ON S.ID                                                = X.ID_SEGMENTO_PRODUTO
          ) SEGMENTO_PRODUTO ON SEGMENTO_PRODUTO.ID_PRODUTO_BASE = VENDAS.ID_PRODUTO_BASE
        )
      WHERE ID_SEGMENTO_PRODUTO IS NOT NULL
      GROUP BY ID_DESTINATARIO,
        ID_SEGMENTO_PRODUTO,
        ID_SEGMENTO_SUPERIOR_PRODUTO
      ORDER BY ID_DESTINATARIO
      ) X
    INNER JOIN
      (SELECT ID_DESTINATARIO,
        ID_SEGMENTO_SUPERIOR_PRODUTO,
        SUM(QTD_PRODUTOS) AS QTD_PRODUTOS_GERAL
      FROM
        (SELECT ID_DESTINATARIO,
          ID_SEGMENTO_PRODUTO,
          ID_SEGMENTO_SUPERIOR_PRODUTO,
          SUM(QTD_PRODUTOS) AS QTD_PRODUTOS
        FROM
          (SELECT VENDAS.*,
            SEGMENTO_PRODUTO.ID_SEGMENTO_PRODUTO,
            SEGMENTO_PRODUTO.ID_SEGMENTO_SUPERIOR_PRODUTO
          FROM
            (SELECT *
            FROM
              (SELECT NF.ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE,
                ROUND(COUNT(PB.ID),2) AS QTD_PRODUTOS
              FROM OCN_PRODUTO P
              INNER JOIN OCN_PRODUTO_BASE PB
              ON PB.ID             = P.ID_PRODUTO_BASE
              AND PB.TIPO_PRODUTO IN ('ME','PA','IP')
              INNER JOIN
                (SELECT NFI.*
                FROM SBR_NOTAFISCAL_ITEM NFI
                WHERE NFI.ID_NOTAFISCAL_ITEM_REF IS NULL
                OR NOT EXISTS
                  (SELECT 'x'
                  FROM SBR_NOTAFISCAL_ITEM NFI
                  INNER JOIN SBR_NOTAFISCAL NF
                  ON NF.ID         = NFI.ID_NOTAFISCAL
                  WHERE NF.TIPO_NF = 'D'
                  )
                )NFI ON NFI.ID_PRODUTO = P.ID
              INNER JOIN SBR_TIPO_MOV_FISCAL TMF
              ON TMF.ID         = NFI.ID_TIPO_MOV_FISCAL
              AND OPERA_ESTOQUE =1
              INNER JOIN SBR_NOTAFISCAL NF
              ON NF.ID            = NFI.ID_NOTAFISCAL
              AND NF.NOTA_PROPRIA = 1
              AND NF.TIPO_NF      = 'N'
              AND NF.TIPO_ES      = '1'
              INNER JOIN SBR_PESSOA PS
              ON PS.ID = NF.ID_DESTINATARIO
              LEFT JOIN SBR_PESSOA_SEGMENTO PG
              ON PG.ID_PESSOA  = PS.ID
              AND PG.PRINCIPAL = 1
              AND PG.FORMA     = 'A'
              LEFT JOIN OCN_SEGMENTO S
              ON S.ID                       = PG.ID_SEGMENTO
              WHERE NF.ID_DESTINATARIO NOT IN
                (SELECT DISTINCT ID_PESSOA FROM OCN_FILIAL
                )
              GROUP BY NF.ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE
              UNION ALL
              SELECT DISTINCT C.ID_PESSOA AS ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE,
                ROUND(COUNT(P.ID_PRODUTO_BASE),2) AS QTD_PRODUTOS
              FROM SBR_CLI_PRODUTO CP
              INNER JOIN OCN_PRODUTO P
              ON P.ID = CP.ID_PRODUTO
              INNER JOIN SBR_CLIENTE C
              ON C.ID = CP.ID_CLIENTE
              LEFT JOIN SBR_PESSOA_SEGMENTO PG
              ON PG.ID_PESSOA  = C.ID_PESSOA
              AND PG.PRINCIPAL = 1
              AND PG.FORMA     = 'A'
              LEFT JOIN OCN_SEGMENTO S
              ON S.ID = PG.ID_SEGMENTO
              GROUP BY C.ID_PESSOA,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE
              )
            ) VENDAS
          LEFT JOIN
            (SELECT X.*,
              S.ID_SUPERIOR AS ID_SEGMENTO_SUPERIOR_PRODUTO
            FROM
              (SELECT PB.ID     AS ID_PRODUTO_BASE,
                PBT.ID_SEGMENTO AS ID_SEGMENTO_PRODUTO
              FROM OCN_REF_SEGMENTO_PRODUTO PBT
              INNER JOIN OCN_PRODUTO_BASE PB
              ON PB.ID_SERIAL = PBT.ID_SERIAL_BASE
              WHERE PBT.TIPO  = 'TRATAMENTO'
              ) X
            INNER JOIN OCN_SEGMENTO S
            ON S.ID                                                = X.ID_SEGMENTO_PRODUTO
            ) SEGMENTO_PRODUTO ON SEGMENTO_PRODUTO.ID_PRODUTO_BASE = VENDAS.ID_PRODUTO_BASE
          )
        WHERE ID_SEGMENTO_PRODUTO IS NOT NULL
        GROUP BY ID_DESTINATARIO,
          ID_SEGMENTO_PRODUTO,
          ID_SEGMENTO_SUPERIOR_PRODUTO
        ORDER BY ID_DESTINATARIO
        )
      GROUP BY ID_DESTINATARIO,
        ID_SEGMENTO_SUPERIOR_PRODUTO
      ) Y ON Y.ID_DESTINATARIO         = X.ID_DESTINATARIO
    AND Y.ID_SEGMENTO_SUPERIOR_PRODUTO = X.ID_SEGMENTO_SUPERIOR_PRODUTO
    )
  )
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_PESSOA_SEG_ESP_AUTO" ("ID_PESSOA", "ID_SEGMENTO", "PERCENTUAL") AS 
  (SELECT ID_DESTINATARIO AS ID_PESSOA,
    ID_SEGMENTO_PRODUTO   AS ID_SEGMENTO,
    PERCENTUAL
  FROM
    (SELECT X.*,
      Y.QTD_PRODUTOS_GERAL,
      TRUNC((QTD_PRODUTOS * 100) / Y.QTD_PRODUTOS_GERAL) AS PERCENTUAL
    FROM
      (SELECT ID_DESTINATARIO,
        ID_SEGMENTO_PRODUTO,
        ID_SEGMENTO_SUPERIOR_PRODUTO,
        SUM(QTD_PRODUTOS) AS QTD_PRODUTOS
      FROM
        (SELECT VENDAS.*,
          SEGMENTO_PRODUTO.ID_SEGMENTO_PRODUTO,
          SEGMENTO_PRODUTO.ID_SEGMENTO_SUPERIOR_PRODUTO
        FROM
          (SELECT *
          FROM
            (SELECT NF.ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE,
              ROUND(COUNT(PB.ID),2) AS QTD_PRODUTOS
            FROM OCN_PRODUTO P
            INNER JOIN OCN_PRODUTO_BASE PB
            ON PB.ID             = P.ID_PRODUTO_BASE
            AND PB.TIPO_PRODUTO IN ('ME','PA','IP')
            INNER JOIN
              (SELECT NFI.*
              FROM SBR_NOTAFISCAL_ITEM NFI
              WHERE NFI.ID_NOTAFISCAL_ITEM_REF IS NULL
              OR NOT EXISTS
                (SELECT 'x'
                FROM SBR_NOTAFISCAL_ITEM NFI
                INNER JOIN SBR_NOTAFISCAL NF
                ON NF.ID         = NFI.ID_NOTAFISCAL
                WHERE NF.TIPO_NF = 'D'
                )
              )NFI ON NFI.ID_PRODUTO = P.ID
            INNER JOIN SBR_TIPO_MOV_FISCAL TMF
            ON TMF.ID         = NFI.ID_TIPO_MOV_FISCAL
            AND OPERA_ESTOQUE =1
            INNER JOIN SBR_NOTAFISCAL NF
            ON NF.ID            = NFI.ID_NOTAFISCAL
            AND NF.NOTA_PROPRIA = 1
            AND NF.TIPO_NF      = 'N'
            AND NF.TIPO_ES      = '1'
            INNER JOIN SBR_PESSOA PS
            ON PS.ID = NF.ID_DESTINATARIO
            LEFT JOIN SBR_PESSOA_SEGMENTO PG
            ON PG.ID_PESSOA  = PS.ID
            AND PG.PRINCIPAL = 1
            AND PG.FORMA     = 'A'
            LEFT JOIN OCN_SEGMENTO S
            ON S.ID                       = PG.ID_SEGMENTO
            WHERE NF.ID_DESTINATARIO NOT IN
              (SELECT DISTINCT ID_PESSOA FROM OCN_FILIAL
              )
            GROUP BY NF.ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE
            UNION ALL
            SELECT DISTINCT C.ID_PESSOA AS ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE,
              ROUND(COUNT(P.ID_PRODUTO_BASE),2) AS QTD_PRODUTOS
            FROM SBR_CLI_PRODUTO CP
            INNER JOIN OCN_PRODUTO P
            ON P.ID = CP.ID_PRODUTO
            INNER JOIN SBR_CLIENTE C
            ON C.ID = CP.ID_CLIENTE
            LEFT JOIN SBR_PESSOA_SEGMENTO PG
            ON PG.ID_PESSOA  = C.ID_PESSOA
            AND PG.PRINCIPAL = 1
            AND PG.FORMA     = 'A'
            LEFT JOIN OCN_SEGMENTO S
            ON S.ID = PG.ID_SEGMENTO
            GROUP BY C.ID_PESSOA,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE
            )
          ) VENDAS
        LEFT JOIN
          (SELECT X.*,
            S.ID_SUPERIOR AS ID_SEGMENTO_SUPERIOR_PRODUTO
          FROM
            ( SELECT DISTINCT *
            FROM
              (SELECT PB.ID              AS ID_PRODUTO_BASE,
                SP.ID_SEGMENTO_PRINCIPAL AS ID_SEGMENTO_PRODUTO
              FROM OCN_REF_SEGMENTO_PRODUTO PBT
              INNER JOIN OCN_PRODUTO_BASE PB
              ON PB.ID_SERIAL = PBT.ID_SERIAL_BASE
              INNER JOIN SBR_SEGMENTO S
              ON S.ID = PBT.ID_SEGMENTO
              INNER JOIN
                (SELECT ID_SUPERIOR AS ID_SEGMENTO_PRINCIPAL,
                  ID                AS ID_SEGMENTO,
                  DESCRICAO         AS SEGMENTO
                FROM SBR_SEGMENTO
                WHERE ID_SUPERIOR IN
                  (SELECT ID
                  FROM SBR_SEGMENTO
                  WHERE ID_SUPERIOR IN
                    ( SELECT ID FROM SBR_SEGMENTO WHERE ID_SUPERIOR IS NULL
                    )
                  )
                ) SP
              ON SP.ID_SEGMENTO = S.ID
              )
            ) X
          INNER JOIN OCN_SEGMENTO S
          ON S.ID                                                = X.ID_SEGMENTO_PRODUTO
          ) SEGMENTO_PRODUTO ON SEGMENTO_PRODUTO.ID_PRODUTO_BASE = VENDAS.ID_PRODUTO_BASE
        )
      WHERE ID_SEGMENTO_PRODUTO IS NOT NULL
      GROUP BY ID_DESTINATARIO,
        ID_SEGMENTO_PRODUTO,
        ID_SEGMENTO_SUPERIOR_PRODUTO
      ORDER BY ID_DESTINATARIO
      ) X
    INNER JOIN
      (SELECT ID_DESTINATARIO,
        ID_SEGMENTO_SUPERIOR_PRODUTO,
        SUM(QTD_PRODUTOS) AS QTD_PRODUTOS_GERAL
      FROM
        (SELECT ID_DESTINATARIO,
          ID_SEGMENTO_PRODUTO,
          ID_SEGMENTO_SUPERIOR_PRODUTO,
          SUM(QTD_PRODUTOS) AS QTD_PRODUTOS
        FROM
          (SELECT VENDAS.*,
            SEGMENTO_PRODUTO.ID_SEGMENTO_PRODUTO,
            SEGMENTO_PRODUTO.ID_SEGMENTO_SUPERIOR_PRODUTO
          FROM
            (SELECT *
            FROM
              (SELECT NF.ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE,
                ROUND(COUNT(PB.ID),2) AS QTD_PRODUTOS
              FROM OCN_PRODUTO P
              INNER JOIN OCN_PRODUTO_BASE PB
              ON PB.ID             = P.ID_PRODUTO_BASE
              AND PB.TIPO_PRODUTO IN ('ME','PA','IP')
              INNER JOIN
                (SELECT NFI.*
                FROM SBR_NOTAFISCAL_ITEM NFI
                WHERE NFI.ID_NOTAFISCAL_ITEM_REF IS NULL
                OR NOT EXISTS
                  (SELECT 'x'
                  FROM SBR_NOTAFISCAL_ITEM NFI
                  INNER JOIN SBR_NOTAFISCAL NF
                  ON NF.ID         = NFI.ID_NOTAFISCAL
                  WHERE NF.TIPO_NF = 'D'
                  )
                )NFI ON NFI.ID_PRODUTO = P.ID
              INNER JOIN SBR_TIPO_MOV_FISCAL TMF
              ON TMF.ID         = NFI.ID_TIPO_MOV_FISCAL
              AND OPERA_ESTOQUE =1
              INNER JOIN SBR_NOTAFISCAL NF
              ON NF.ID            = NFI.ID_NOTAFISCAL
              AND NF.NOTA_PROPRIA = 1
              AND NF.TIPO_NF      = 'N'
              AND NF.TIPO_ES      = '1'
              INNER JOIN SBR_PESSOA PS
              ON PS.ID = NF.ID_DESTINATARIO
              LEFT JOIN SBR_PESSOA_SEGMENTO PG
              ON PG.ID_PESSOA  = PS.ID
              AND PG.PRINCIPAL = 1
              AND PG.FORMA     = 'A'
              LEFT JOIN OCN_SEGMENTO S
              ON S.ID                       = PG.ID_SEGMENTO
              WHERE NF.ID_DESTINATARIO NOT IN
                (SELECT DISTINCT ID_PESSOA FROM OCN_FILIAL
                )
              GROUP BY NF.ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE
              UNION ALL
              SELECT DISTINCT C.ID_PESSOA AS ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE,
                ROUND(COUNT(P.ID_PRODUTO_BASE),2) AS QTD_PRODUTOS
              FROM SBR_CLI_PRODUTO CP
              INNER JOIN OCN_PRODUTO P
              ON P.ID = CP.ID_PRODUTO
              INNER JOIN SBR_CLIENTE C
              ON C.ID = CP.ID_CLIENTE
              LEFT JOIN SBR_PESSOA_SEGMENTO PG
              ON PG.ID_PESSOA  = C.ID_PESSOA
              AND PG.PRINCIPAL = 1
              AND PG.FORMA     = 'A'
              LEFT JOIN OCN_SEGMENTO S
              ON S.ID = PG.ID_SEGMENTO
              GROUP BY C.ID_PESSOA,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE
              )
            ) VENDAS
          LEFT JOIN
            (SELECT X.*,
              S.ID_SUPERIOR AS ID_SEGMENTO_SUPERIOR_PRODUTO
            FROM
              ( SELECT DISTINCT *
              FROM
                (SELECT PB.ID              AS ID_PRODUTO_BASE,
                  SP.ID_SEGMENTO_PRINCIPAL AS ID_SEGMENTO_PRODUTO
                FROM OCN_REF_SEGMENTO_PRODUTO PBT
                INNER JOIN OCN_PRODUTO_BASE PB
                ON PB.ID_SERIAL = PBT.ID_SERIAL_BASE
                INNER JOIN SBR_SEGMENTO S
                ON S.ID = PBT.ID_SEGMENTO
                INNER JOIN
                  (SELECT ID_SUPERIOR AS ID_SEGMENTO_PRINCIPAL,
                    ID                AS ID_SEGMENTO,
                    DESCRICAO         AS SEGMENTO
                  FROM SBR_SEGMENTO
                  WHERE ID_SUPERIOR IN
                    (SELECT ID
                    FROM SBR_SEGMENTO
                    WHERE ID_SUPERIOR IN
                      ( SELECT ID FROM SBR_SEGMENTO WHERE ID_SUPERIOR IS NULL
                      )
                    )
                  ) SP
                ON SP.ID_SEGMENTO = S.ID
                )
              ) X
            INNER JOIN OCN_SEGMENTO S
            ON S.ID                                                = X.ID_SEGMENTO_PRODUTO
            ) SEGMENTO_PRODUTO ON SEGMENTO_PRODUTO.ID_PRODUTO_BASE = VENDAS.ID_PRODUTO_BASE
          )
        WHERE ID_SEGMENTO_PRODUTO IS NOT NULL
        GROUP BY ID_DESTINATARIO,
          ID_SEGMENTO_PRODUTO,
          ID_SEGMENTO_SUPERIOR_PRODUTO
        ORDER BY ID_DESTINATARIO
        )
      GROUP BY ID_DESTINATARIO,
        ID_SEGMENTO_SUPERIOR_PRODUTO
      ) Y ON Y.ID_DESTINATARIO         = X.ID_DESTINATARIO
    AND Y.ID_SEGMENTO_SUPERIOR_PRODUTO = X.ID_SEGMENTO_SUPERIOR_PRODUTO
    )
  )
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_PESSOA_SEGMENTO_AUTO" ("ID_PESSOA", "ID_SEGMENTO", "PERCENTUAL") AS 
  (SELECT ID_DESTINATARIO AS ID_PESSOA,
    ID_SEGMENTO_PRODUTO   AS ID_SEGMENTO,
    PERCENTUAL
  FROM
    (SELECT X.*,
      Y.QTD_PRODUTOS_GERAL,
      TRUNC((QTD_PRODUTOS * 100) / Y.QTD_PRODUTOS_GERAL) AS PERCENTUAL
    FROM
      (SELECT ID_DESTINATARIO,
        ID_SEGMENTO,
        ID_SEGMENTO_PRODUTO,
        SUM(QTD_PRODUTOS) AS QTD_PRODUTOS
      FROM
        (SELECT VENDAS.*,
          SEGMENTO_PRODUTO.ID_SEGMENTO_PRODUTO
        FROM
          (SELECT *
          FROM
            (SELECT NF.ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE,
              ROUND(COUNT(PB.ID),2) AS QTD_PRODUTOS
            FROM OCN_PRODUTO P
            INNER JOIN OCN_PRODUTO_BASE PB
            ON PB.ID             = P.ID_PRODUTO_BASE
            AND PB.TIPO_PRODUTO IN ('ME','PA','IP')
            INNER JOIN
              (SELECT NFI.*
              FROM SBR_NOTAFISCAL_ITEM NFI
              WHERE NFI.ID_NOTAFISCAL_ITEM_REF IS NULL
              OR NOT EXISTS
                (SELECT 'x'
                FROM SBR_NOTAFISCAL_ITEM NFI
                INNER JOIN SBR_NOTAFISCAL NF
                ON NF.ID         = NFI.ID_NOTAFISCAL
                WHERE NF.TIPO_NF = 'D'
                )
              )NFI ON NFI.ID_PRODUTO = P.ID
            INNER JOIN SBR_TIPO_MOV_FISCAL TMF
            ON TMF.ID         = NFI.ID_TIPO_MOV_FISCAL
            AND OPERA_ESTOQUE =1
            INNER JOIN SBR_NOTAFISCAL NF
            ON NF.ID            = NFI.ID_NOTAFISCAL
            AND NF.NOTA_PROPRIA = 1
            AND NF.TIPO_NF      = 'N'
            AND NF.TIPO_ES      = '1'
            INNER JOIN SBR_PESSOA PS
            ON PS.ID = NF.ID_DESTINATARIO
            LEFT JOIN SBR_PESSOA_SEGMENTO PG
            ON PG.ID_PESSOA  = PS.ID
            AND PG.PRINCIPAL = 1
            AND PG.FORMA     = 'A'
            LEFT JOIN OCN_SEGMENTO S
            ON S.ID                       = PG.ID_SEGMENTO
            WHERE NF.ID_DESTINATARIO NOT IN
              (SELECT DISTINCT ID_PESSOA FROM OCN_FILIAL
              )
            GROUP BY NF.ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE
            UNION ALL
            SELECT DISTINCT C.ID_PESSOA AS ID_DESTINATARIO,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE,
              ROUND(COUNT(P.ID_PRODUTO_BASE),2) AS QTD_PRODUTOS
            FROM SBR_CLI_PRODUTO CP
            INNER JOIN OCN_PRODUTO P
            ON P.ID = CP.ID_PRODUTO
            INNER JOIN SBR_CLIENTE C
            ON C.ID = CP.ID_CLIENTE
            LEFT JOIN SBR_PESSOA_SEGMENTO PG
            ON PG.ID_PESSOA  = C.ID_PESSOA
            AND PG.PRINCIPAL = 1
            AND PG.FORMA     = 'A'
            LEFT JOIN OCN_SEGMENTO S
            ON S.ID = PG.ID_SEGMENTO
            GROUP BY C.ID_PESSOA,
              PG.ID_SEGMENTO,
              P.ID_PRODUTO_BASE
            )
          ) VENDAS
        LEFT JOIN
          ( SELECT DISTINCT *
          FROM
            (SELECT PB.ID AS ID_PRODUTO_BASE,
              S.ID        AS ID_SEGMENTO_PRODUTO
            FROM OCN_PRODUTO_BASE PB
            INNER JOIN OCN_SEGMENTO S
            ON S.ID                         = PB.ID_SEGMENTO_PRINCIPAL
            WHERE PB.ID_SEGMENTO_PRINCIPAL IS NOT NULL
            )
          UNION ALL
          SELECT DISTINCT *
          FROM
            (SELECT PB.ID              AS ID_PRODUTO_BASE,
              SP.ID_SEGMENTO_PRINCIPAL AS ID_SEGMENT0
            FROM OCN_REF_SEGMENTO_PRODUTO PBT
            INNER JOIN OCN_PRODUTO_BASE PB
            ON PB.ID_SERIAL = PBT.ID_SERIAL_BASE
            INNER JOIN SBR_SEGMENTO S
            ON S.ID = PBT.ID_SEGMENTO
            INNER JOIN
              (SELECT S.ID   AS ID_SEGMENTO,
                S.DESCRICAO  AS SEGMENTO,
                SP.ID        AS ID_SEGMENTO_PRINCIPAL,
                SP.DESCRICAO AS SEGMENTO_PRINCIPAL
              FROM SBR_SEGMENTO S,
                SBR_SEGMENTO SP
              WHERE S.ID_SUPERIOR IS NOT NULL
              AND SP.ID           IN
                (SELECT ID
                FROM SBR_SEGMENTO
                WHERE ID_SUPERIOR IS NULL
                  START WITH ID    = S.ID
                  CONNECT BY ID    = PRIOR ID_SUPERIOR
                )
              AND SP.ID_SUPERIOR IS NULL
              ) SP
            ON SP.ID_SEGMENTO               = S.ID
            WHERE PB.ID_SEGMENTO_PRINCIPAL IS NULL
            ORDER BY PB.ID
            )
          ) SEGMENTO_PRODUTO ON SEGMENTO_PRODUTO.ID_PRODUTO_BASE = VENDAS.ID_PRODUTO_BASE
        )
      WHERE ID_SEGMENTO_PRODUTO IS NOT NULL
      GROUP BY ID_DESTINATARIO,
        ID_SEGMENTO,
        ID_SEGMENTO_PRODUTO
      ORDER BY ID_DESTINATARIO
      ) X
    INNER JOIN
      (SELECT ID_DESTINATARIO,
        SUM(QTD_PRODUTOS) AS QTD_PRODUTOS_GERAL
      FROM
        (SELECT ID_DESTINATARIO,
          ID_SEGMENTO,
          ID_SEGMENTO_PRODUTO,
          SUM(QTD_PRODUTOS) AS QTD_PRODUTOS
        FROM
          (SELECT VENDAS.*,
            SEGMENTO_PRODUTO.ID_SEGMENTO_PRODUTO
          FROM
            (SELECT *
            FROM
              (SELECT NF.ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE,
                ROUND(COUNT(PB.ID),2) AS QTD_PRODUTOS
              FROM OCN_PRODUTO P
              INNER JOIN OCN_PRODUTO_BASE PB
              ON PB.ID             = P.ID_PRODUTO_BASE
              AND PB.TIPO_PRODUTO IN ('ME','PA','IP')
              INNER JOIN
                (SELECT NFI.*
                FROM SBR_NOTAFISCAL_ITEM NFI
                WHERE NFI.ID_NOTAFISCAL_ITEM_REF IS NULL
                OR NOT EXISTS
                  (SELECT 'x'
                  FROM SBR_NOTAFISCAL_ITEM NFI
                  INNER JOIN SBR_NOTAFISCAL NF
                  ON NF.ID         = NFI.ID_NOTAFISCAL
                  WHERE NF.TIPO_NF = 'D'
                  )
                )NFI ON NFI.ID_PRODUTO = P.ID
              INNER JOIN SBR_TIPO_MOV_FISCAL TMF
              ON TMF.ID         = NFI.ID_TIPO_MOV_FISCAL
              AND OPERA_ESTOQUE =1
              INNER JOIN SBR_NOTAFISCAL NF
              ON NF.ID            = NFI.ID_NOTAFISCAL
              AND NF.NOTA_PROPRIA = 1
              AND NF.TIPO_NF      = 'N'
              AND NF.TIPO_ES      = '1'
              INNER JOIN SBR_PESSOA PS
              ON PS.ID = NF.ID_DESTINATARIO
              LEFT JOIN SBR_PESSOA_SEGMENTO PG
              ON PG.ID_PESSOA  = PS.ID
              AND PG.PRINCIPAL = 1
              AND PG.FORMA     = 'A'
              LEFT JOIN OCN_SEGMENTO S
              ON S.ID                       = PG.ID_SEGMENTO
              WHERE NF.ID_DESTINATARIO NOT IN
                (SELECT DISTINCT ID_PESSOA FROM OCN_FILIAL
                )
              GROUP BY NF.ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE
              UNION ALL
              SELECT DISTINCT C.ID_PESSOA AS ID_DESTINATARIO,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE,
                ROUND(COUNT(P.ID_PRODUTO_BASE),2) AS QTD_PRODUTOS
              FROM SBR_CLI_PRODUTO CP
              INNER JOIN OCN_PRODUTO P
              ON P.ID = CP.ID_PRODUTO
              INNER JOIN SBR_CLIENTE C
              ON C.ID = CP.ID_CLIENTE
              LEFT JOIN SBR_PESSOA_SEGMENTO PG
              ON PG.ID_PESSOA  = C.ID_PESSOA
              AND PG.PRINCIPAL = 1
              AND PG.FORMA     = 'A'
              LEFT JOIN OCN_SEGMENTO S
              ON S.ID = PG.ID_SEGMENTO
              GROUP BY C.ID_PESSOA,
                PG.ID_SEGMENTO,
                P.ID_PRODUTO_BASE
              )
            ) VENDAS
          LEFT JOIN
            ( SELECT DISTINCT *
            FROM
              (SELECT PB.ID AS ID_PRODUTO_BASE,
                S.ID        AS ID_SEGMENTO_PRODUTO
              FROM OCN_PRODUTO_BASE PB
              INNER JOIN OCN_SEGMENTO S
              ON S.ID                         = PB.ID_SEGMENTO_PRINCIPAL
              WHERE PB.ID_SEGMENTO_PRINCIPAL IS NOT NULL
              )
            UNION ALL
            SELECT DISTINCT *
            FROM
              (SELECT PB.ID              AS ID_PRODUTO_BASE,
                SP.ID_SEGMENTO_PRINCIPAL AS ID_SEGMENT0
              FROM OCN_REF_SEGMENTO_PRODUTO PBT
              INNER JOIN OCN_PRODUTO_BASE PB
              ON PB.ID_SERIAL = PBT.ID_SERIAL_BASE
              INNER JOIN SBR_SEGMENTO S
              ON S.ID = PBT.ID_SEGMENTO
              INNER JOIN
                (SELECT S.ID   AS ID_SEGMENTO,
                  S.DESCRICAO  AS SEGMENTO,
                  SP.ID        AS ID_SEGMENTO_PRINCIPAL,
                  SP.DESCRICAO AS SEGMENTO_PRINCIPAL
                FROM SBR_SEGMENTO S,
                  SBR_SEGMENTO SP
                WHERE S.ID_SUPERIOR IS NOT NULL
                AND SP.ID           IN
                  (SELECT ID
                  FROM SBR_SEGMENTO
                  WHERE ID_SUPERIOR IS NULL
                    START WITH ID    = S.ID
                    CONNECT BY ID    = PRIOR ID_SUPERIOR
                  )
                AND SP.ID_SUPERIOR IS NULL
                ) SP
              ON SP.ID_SEGMENTO               = S.ID
              WHERE PB.ID_SEGMENTO_PRINCIPAL IS NULL
              ORDER BY PB.ID
              )
            ) SEGMENTO_PRODUTO ON SEGMENTO_PRODUTO.ID_PRODUTO_BASE = VENDAS.ID_PRODUTO_BASE
          )
        WHERE ID_SEGMENTO_PRODUTO IS NOT NULL
        GROUP BY ID_DESTINATARIO,
          ID_SEGMENTO,
          ID_SEGMENTO_PRODUTO
        ORDER BY ID_DESTINATARIO
        )
      GROUP BY ID_DESTINATARIO
      ) Y ON Y.ID_DESTINATARIO = X.ID_DESTINATARIO
    )
  )
 "
"
 
 "
"
 
 "
"
 
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_FEEDBACK_METRICA" ("ID", "CLASSE", "DESCRICAO", "TIPO", "OBSERVACAO", "ID_USUARIO", "ID_PROCESSO", "DH_TAREFA", "ID_ENTIDADE", "CLASSE_ENTIDADE", "ICONE", "AJUDA") AS 
  SELECT "ID",
    "CLASSE",
    "DESCRICAO",
    "TIPO",
    "OBSERVACAO",
    "ID_USUARIO",
    "ID_PROCESSO",
    "DH_TAREFA",
    "ID_ENTIDADE",
    "CLASSE_ENTIDADE",
    "ICONE",
    "AJUDA"
  FROM
    (SELECT A.ID_USUARIO ID,
      A.CLASS_ENTIDADE_ACESSO CLASSE,
      A.OBSERVACAO DESCRICAO,
      A.TIPO_AGENDA TIPO,
      A.OBSERVACAO,
      U.ID ID_USUARIO,
      NULL ID_PROCESSO,
      A.DATA_AGENDA DH_TAREFA,
      A.ID_ENTIDADE_ACESSO ID_ENTIDADE,
      A.CLASS_ENTIDADE_ACESSO CLASSE_ENTIDADE,
      NULL ICONE,
      NULL AJUDA
    FROM
      (SELECT COUNT(*) QUANTIDADE,
        TIPO_AGENDA,
        OBSERVACAO,
        DATA_AGENDA,
        TITULO,
        ULTIMA_DATA,
        BLOQUEAR,
        DIAS_PARA_BLOQUEIO,
        ID_USUARIO,
        CLASS_ENTIDADE_ACESSO,
        ID_ENTIDADE_ACESSO,
        EXPRESSION,
        1 ABRE_ANALYTICS
      FROM
        (SELECT 'REGISTRAR_FEEDBACK' TIPO_AGENDA,
          'Feedback para a Métrica ['
          ||U.NOME
          ||']' OBSERVACAO,
          CASE
            WHEN (ULTIMO_FEEDBACK IS NULL)
            THEN
              CASE
                WHEN (FC.DIA_SEMANA_BD                       IS NOT NULL)
                AND ( FC.DIA_SEMANA_BD - TO_CHAR(SYSDATE,'D') > 0)
                THEN TRUNC(SYSDATE     + (FC.DIA_SEMANA_BD- TO_CHAR(SYSDATE,'D')),'DD')
                WHEN FC.DIA_SEMANA_BD IS NOT NULL
                THEN TRUNC(SYSDATE,'DD')
                ELSE TRUNC(SYSDATE,'DD')
              END
            ELSE
              CASE
                WHEN FC.DIA_SEMANA_BD IS NULL
                THEN TRUNC(SYSDATE,'DD')
                WHEN (FC.DIA_SEMANA_BD                                         IS NOT NULL)
                AND (TRUNC(NEXT_DAY(FD.ULTIMO_FEEDBACK, FC.DIA_SEMANA_BD),'DD') < TRUNC(SYSDATE,'DD'))
                THEN TRUNC(SYSDATE,'DD')
                ELSE TRUNC(NEXT_DAY(NEXT_DAY(ULTIMO_FEEDBACK, 1), FC.DIA_SEMANA_BD),'DD')
              END
          END AS DATA_AGENDA,
          'Registrar Feedback' TITULO,
          ULTIMO_FEEDBACK ULTIMA_DATA,
          CASE
            WHEN (ULTIMO_FEEDBACK IS NULL)
            THEN 1
            WHEN (ULTIMO_FEEDBACK                                   IS NOT NULL)
            AND (FC.DIA_SEMANA_BD                                   IS NULL )
            AND ((TRUNC(SYSDATE,'DD') - TRUNC(ULTIMO_FEEDBACK,'DD')) > 7)
            THEN 1
            WHEN (ULTIMO_FEEDBACK                                                    IS NOT NULL)
            AND (FC.DIA_SEMANA_BD                                                    IS NOT NULL )
            AND (TRUNC(NEXT_DAY(NEXT_DAY(ULTIMO_FEEDBACK, 1), FC.DIA_SEMANA_BD),'DD') > TRUNC(SYSDATE,'DD'))
            THEN 1
            ELSE 0
          END AS BLOQUEAR,
          CASE
            WHEN (ULTIMO_FEEDBACK IS NULL)
            THEN
              CASE
                WHEN FC.DIA_SEMANA_BD IS NOT NULL
                THEN FC.DIA_SEMANA_BD - TO_CHAR(SYSDATE,'D')
                ELSE 0
              END
            ELSE
              CASE
                WHEN FC.DIA_SEMANA_BD IS NULL
                THEN TRUNC(ULTIMO_FEEDBACK                                                +7,'DD') - TRUNC(SYSDATE,'DD')
                ELSE TRUNC(NEXT_DAY(NEXT_DAY(ULTIMO_FEEDBACK, 1), FC.DIA_SEMANA_BD),'DD') - TRUNC(sysdate,'DD')
              END
          END AS DIAS_PARA_BLOQUEIO,
          U.ID ID_USUARIO,
          M.CLASS_ENTIDADE_ACESSO,
          M.ID_ENTIDADE_ACESSO,
          NULL AS EXPRESSION
        FROM SBR_METRICA_DESAFIO MD
        INNER JOIN SBR_METRICA_OBJETIVO_VALOR MOV
        ON MOV.ID = MD.ID_OBJETIVO_VALOR
        INNER JOIN SBR_METRICA_OBJETIVO MO
        ON MOV.ID_METRICA_OBJETIVO = MO.ID
        INNER JOIN SBR_METRICA M
        ON M.ID = MO.ID_METRICA
        INNER JOIN OCN_USUARIO U
        ON U.ID       = MD.ID_USUARIO
        AND U.ATIVO   = 1
        AND U.NUMCAD IS NOT NULL
        AND M.VISAO   = U.METRICA_VISAO
        LEFT JOIN
          (SELECT TRUNC(MAX(F.DATA_REGISTRO),'DD') ULTIMO_FEEDBACK,
            ID_USUARIO_REF,
            F.ID_METRICA
          FROM SBR_FEEDBACK F
          GROUP BY ID_USUARIO_REF,
            F.ID_METRICA
          ) FD
        ON FD.ID_USUARIO_REF = MD.ID_USUARIO
        AND FD.ID_METRICA    = M.ID
        LEFT JOIN SBR_FEEDBACK_CRONOGRAMA FC
        ON FC.ID_USUARIO = U.ID
        AND FC.DATA_BASE BETWEEN MD.DATA_INICIAL AND MD.DATA_FINAL
        WHERE ( SYSDATE BETWEEN MD.DATA_INICIAL AND MD.DATA_FINAL)
        )
      GROUP BY TIPO_AGENDA,
        OBSERVACAO,
        DATA_AGENDA,
        TITULO,
        ULTIMA_DATA,
        BLOQUEAR,
        DIAS_PARA_BLOQUEIO,
        ID_USUARIO,
        CLASS_ENTIDADE_ACESSO,
        ID_ENTIDADE_ACESSO,
        EXPRESSION
      ) A,
      OCN_USUARIO U
    WHERE A.ID_USUARIO IN
      (SELECT SU.ID_SUBORDINADO
      FROM SBR_VIEW_USUARIO_SUBORDINADO SU
      WHERE SU.ID_USUARIO = U.ID
      )
    OR A.ID_USUARIO = u.id
    )
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_COMUNICACAO_FEEDBACK" ("ID", "CLASSE", "DESCRICAO", "TIPO", "OBSERVACAO", "ID_USUARIO", "ID_PROCESSO", "DH_TAREFA", "ID_ENTIDADE", "CLASSE_ENTIDADE", "ICONE", "AJUDA") AS 
  SELECT "ID","CLASSE","DESCRICAO","TIPO","OBSERVACAO","ID_USUARIO","ID_PROCESSO","DH_TAREFA","ID_ENTIDADE","CLASSE_ENTIDADE","ICONE","AJUDA"
  FROM
    (SELECT A.ID_ENTIDADE_ACESSO ID,
    A.CLASS_ENTIDADE_ACESSO CLASSE,
    A.OBSERVACAO DESCRICAO,
    A.TIPO_AGENDA TIPO,
    A.OBSERVACAO,
    U.ID ID_USUARIO,
    NULL ID_PROCESSO,
    A.DATA_AGENDA DH_TAREFA,
    A.ID_ENTIDADE_ACESSO ID_ENTIDADE,
    A.CLASS_ENTIDADE_ACESSO CLASSE_ENTIDADE,
    NULL ICONE,
    NULL AJUDA
    FROM
      (SELECT COUNT(*) QUANTIDADE,
        TIPO_AGENDA,
        OBSERVACAO,
        DATA_AGENDA,
        TITULO,
        ULTIMA_DATA,
        BLOQUEAR,
        DIAS_PARA_BLOQUEIO,
        ID_USUARIO,
        CLASS_ENTIDADE_ACESSO,
        ID_ENTIDADE_ACESSO,
        EXPRESSION,
        1 ABRE_ANALYTICS
      FROM
        (SELECT 'REGISTRAR_FEEDBACK' TIPO_AGENDA,
          'Feedback para a Métrica ['
          ||U.NOME
          ||']' OBSERVACAO,
          CASE
            WHEN (ULTIMO_FEEDBACK IS NULL)
            THEN
              CASE
                WHEN (FC.DIA_SEMANA_BD                       IS NOT NULL)
                AND ( FC.DIA_SEMANA_BD - TO_CHAR(SYSDATE,'D') > 0)
                THEN TRUNC(SYSDATE     + (FC.DIA_SEMANA_BD- TO_CHAR(SYSDATE,'D')),'DD')
                WHEN FC.DIA_SEMANA_BD IS NOT NULL
                THEN TRUNC(SYSDATE,'DD')
                ELSE TRUNC(SYSDATE,'DD')
              END
            ELSE
              CASE
                WHEN FC.DIA_SEMANA_BD IS NULL
                THEN TRUNC(SYSDATE,'DD')
                WHEN (FC.DIA_SEMANA_BD                                         IS NOT NULL)
                AND (TRUNC(NEXT_DAY(FD.ULTIMO_FEEDBACK, FC.DIA_SEMANA_BD),'DD') < TRUNC(SYSDATE,'DD'))
                THEN TRUNC(SYSDATE,'DD')
                ELSE TRUNC(NEXT_DAY(NEXT_DAY(ULTIMO_FEEDBACK, 1), FC.DIA_SEMANA_BD),'DD')
              END
          END AS DATA_AGENDA,
          'Registrar Feedback' TITULO,
          ULTIMO_FEEDBACK ULTIMA_DATA,
          CASE
            WHEN (ULTIMO_FEEDBACK IS NULL)
            THEN 1
            WHEN (ULTIMO_FEEDBACK                                   IS NOT NULL)
            AND (FC.DIA_SEMANA_BD                                   IS NULL )
            AND ((TRUNC(SYSDATE,'DD') - TRUNC(ULTIMO_FEEDBACK,'DD')) > 7)
            THEN 1
            WHEN (ULTIMO_FEEDBACK                                                    IS NOT NULL)
            AND (FC.DIA_SEMANA_BD                                                    IS NOT NULL )
            AND (TRUNC(NEXT_DAY(NEXT_DAY(ULTIMO_FEEDBACK, 1), FC.DIA_SEMANA_BD),'DD') > TRUNC(SYSDATE,'DD'))
            THEN 1
            ELSE 0
          END AS BLOQUEAR,
          CASE
            WHEN (ULTIMO_FEEDBACK IS NULL)
            THEN
              CASE
                WHEN FC.DIA_SEMANA_BD IS NOT NULL
                THEN FC.DIA_SEMANA_BD - TO_CHAR(SYSDATE,'D')
                ELSE 0
              END
            ELSE
              CASE
                WHEN FC.DIA_SEMANA_BD IS NULL
                THEN TRUNC(ULTIMO_FEEDBACK                                                +7,'DD') - TRUNC(SYSDATE,'DD')
                ELSE TRUNC(NEXT_DAY(NEXT_DAY(ULTIMO_FEEDBACK, 1), FC.DIA_SEMANA_BD),'DD') - TRUNC(sysdate,'DD')
              END
          END AS DIAS_PARA_BLOQUEIO,
          U.ID ID_USUARIO,
          M.CLASS_ENTIDADE_ACESSO,
          M.ID_ENTIDADE_ACESSO,
          NULL AS EXPRESSION
        FROM SBR_METRICA_DESAFIO MD
        INNER JOIN SBR_METRICA_OBJETIVO_VALOR MOV
        ON MOV.ID = MD.ID_OBJETIVO_VALOR
        INNER JOIN SBR_METRICA_OBJETIVO MO
        ON MOV.ID_METRICA_OBJETIVO = MO.ID
        INNER JOIN SBR_METRICA M
        ON M.ID = MO.ID_METRICA
        INNER JOIN OCN_USUARIO U
        ON U.ID       = MD.ID_USUARIO
        AND U.ATIVO   = 1
        AND U.NUMCAD IS NOT NULL
        AND M.VISAO   = U.METRICA_VISAO
        LEFT JOIN
          (SELECT TRUNC(MAX(F.DATA_REGISTRO),'DD') ULTIMO_FEEDBACK,
            ID_USUARIO_REF,
            F.ID_METRICA
          FROM SBR_FEEDBACK F
          GROUP BY ID_USUARIO_REF,
            F.ID_METRICA
          ) FD
        ON FD.ID_USUARIO_REF = MD.ID_USUARIO
        AND FD.ID_METRICA    = M.ID
        LEFT JOIN SBR_FEEDBACK_CRONOGRAMA FC
        ON FC.ID_USUARIO = U.ID
        AND FC.DATA_BASE BETWEEN MD.DATA_INICIAL AND MD.DATA_FINAL
        WHERE ( SYSDATE BETWEEN MD.DATA_INICIAL AND MD.DATA_FINAL)
        )
      GROUP BY TIPO_AGENDA,
        OBSERVACAO,
        DATA_AGENDA,
        TITULO,
        ULTIMA_DATA,
        BLOQUEAR,
        DIAS_PARA_BLOQUEIO,
        ID_USUARIO,
        CLASS_ENTIDADE_ACESSO,
        ID_ENTIDADE_ACESSO,
        EXPRESSION
      ) A,
      OCN_USUARIO U
    WHERE A.ID_USUARIO IN
      (SELECT SU.ID_SUBORDINADO
      FROM SBR_VIEW_USUARIO_SUBORDINADO SU
      WHERE SU.ID_USUARIO = U.ID
      )
    )
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_VIEW_COMPROMISSO" ("ID", "CLASSE", "DESCRICAO", "TIPO", "OBSERVACAO", "ID_USUARIO", "ID_PROCESSO", "DH_TAREFA", "ID_ENTIDADE", "CLASSE_ENTIDADE", "ICONE", "AJUDA", "USUARIO_LOGIN", "USUARIO_NOME") AS 
  SELECT Q."ID",
    Q."CLASSE",
    Q."DESCRICAO",
    Q."TIPO",
    Q."OBSERVACAO",
    Q."ID_USUARIO",
    Q."ID_PROCESSO",
    Q."DH_TAREFA",
    Q."ID_ENTIDADE",
    Q."CLASSE_ENTIDADE",
    Q."ICONE",
    Q."AJUDA",
    U.LOGIN USUARIO_LOGIN,
    U.NOME USUARIO_NOME
  FROM
    ( SELECT * FROM SBR_VIEW_FEEDBACK_METRICA
    UNION ALL
    SELECT Q.IDAGENDAMENTO id,
      'Agendamento' CLASSE,
      p.nome DESCRICAO,
      'AGENDAMENTO' TIPO,
      Q."OBSERVACAO",
      Q.ID_USUARIO,
      NULL ID_PROCESSO,
      Q.DHFIM DH_TAREFA,
      P.ID ID_ENTIDADE,
      'Pessoa' CLASSE_ENTIDADE,
      'circle orange' ICONE,
      NULL AJUDA
    FROM CRM_AGENDAMENTO Q,
      SBR_PESSOA P
    WHERE P.ID   = Q.ID_PESSOA
    AND Q.STATUS = 'A'
    UNION ALL
    SELECT C.ID,
      'Comunicacao' CLASSE,
      P.NOME DESCRICAO,
      TP.DESCRICAO TIPO,
      C.MOTIVO OBSERVACAO,
      C.ID_USUARIO,
      NULL ID_PROCESSO,
      C.DATA DH_TAREFA,
      P.ID ID_ENTIDADE,
      'Pessoa' CLASSE_ENTIDADE,
      CASE
        WHEN RO.ICONE IS NOT NULL
        THEN RO.ICONE
        WHEN E.ICONE IS NOT NULL
        THEN E.ICONE
        ELSE TP.ICONE
      END ICONE,
      CASE
        WHEN RO.AJUDA IS NOT NULL
        THEN RO.AJUDA
        ELSE TP.DESCRICAO
      END AJUDA
    FROM SBR_COMUNICACAO C,
      SBR_OPORTUNIDADE O,
      OCN_TAREFA T,
      OCN_TAREFA_PARAMETRO TP,
      (SELECT RO.ID_OPORTUNIDADE,
        'circle l-circle ui-ped-'
        || LOWER(S.SIGLA) ICONE,
        PV.ID
        || ' - '
        || S.DESCRICAO AJUDA
      FROM SBR_OPORTUNIDADE_REFERENCIA RO,
        (SELECT ID,ID_STATUS FROM SBR_PED_VENDA
        ) PV,
        (SELECT ID,SIGLA,DESCRICAO FROM SBR_PED_VENDA_STATUS
        ) S
      WHERE RO.ENTIDADE = 'PedidoVenda'
      AND PV.ID         = RO.ID_REF
      AND PV.ID_STATUS  = S.ID
      ) RO,
      SBR_PESSOA P,
      SBR_COMUNICACAO_EVENTO E
    WHERE C.ATIVO         = 1
    AND P.ID              = C.ID_PESSOA
    AND C.ID_OPORTUNIDADE = O.ID
    AND O.ID_TAREFA       = T.ID
    AND T.ID_PARAMETRO    = TP.ID
    AND C.ID_OPORTUNIDADE = RO.ID_OPORTUNIDADE(+)
    AND C.EVENTO          = E.TIPO(+)
    AND 1                 = 1
    UNION ALL
    SELECT ROWNUM ID,
      NULL CLASSE,
      T.DESCRICAO DESCRICAO,
      TP.DESCRICAO TIPO,
      TC.FILIAL OBSERVACAO,
      CASE
        WHEN TC.ID_USUARIO IS NULL
        THEN T.ID_RESPONSAVEL
        ELSE TC.ID_USUARIO
      END ID_USUARIO,
      T.ID_PROCESSO,
      CASE
        WHEN TC.DATA_REFERENCIA IS NULL
        THEN T.DATA_PRAZO
        ELSE TC.DATA_REFERENCIA
      END DH_TAREFA,
      t.ID ID_ENTIDADE,
      'Tarefa' CLASSE_ENTIDADE,
      TP.ICONE ICONE,
      T.DESCRICAO AJUDA
    FROM OCN_TAREFA T
    INNER JOIN OCN_TAREFA_PARAMETRO TP
    ON (TP.ID = T.ID_PARAMETRO)
    LEFT JOIN
      (SELECT
        CASE
          WHEN F.NOME IS NULL
          THEN ''
          ELSE F.CODIGO
            || ' - '
            || F.NOME
        END FILIAL,
        TC.*
      FROM OCN_TAREFA_CHECKLIST TC,
        OCN_FILIAL F
      WHERE TC.ID_FILIAL = F.ID(+)
      ) TC
    ON (TC.ID_TAREFA       = T.ID
    AND TC.DATA_CONCLUSAO IS NULL)
    WHERE T.DATA_SOLUCAO  IS NULL
    AND T.ATIVO            = 1
    UNION ALL
    SELECT SP.ID,
      'StatusProcesso' CLASSE,
      D.DESCRICAO DESCRICAO,
      REPLACE(SP.STATUS,'_',' ')
      || ' - '
      || P.DESCRICAO TIPO,
      SP.MENSAGEM OBSERVACAO,
      SP.ID_USUARIO_EDITOR ID_USUARIO,
      SP.ID_PROCESSO,
      SP.DATA_REGISTRO,
      SP.ID_ENTIDADE,
      SP.ENTIDADE,
      'world orange' ICONE,
      SP.STATUS AJUDA
    FROM OCN_STATUS_PROCESSO SP
    LEFT JOIN
      (SELECT ID,
        CODIGO
        || ' - '
        || DESCRICAO DESCRICAO,
        'ProdutoBase' CLASSE
      FROM OCN_PRODUTO_BASE
      UNION ALL
      SELECT ID,
        CODIGO
        || ' - '
        || NOME DESCRICAO,
        'Fornecedor' CLASSE
      FROM OCN_FORNECEDOR
      UNION ALL
      SELECT ID,DESCRICAO,'Tarefa' CLASSE FROM OCN_TAREFA
      UNION ALL
      SELECT ID,NOME,'Pessoa' CLASSE FROM SBR_PESSOA
      ) D
    ON (D.ID     = SP.ID_ENTIDADE
    AND D.CLASSE = SP.ENTIDADE)
    LEFT JOIN OCN_PROCESSO P
    ON P.ID            = SP.ID_PROCESSO
    WHERE 1            = 1
    AND SP.DELETADO    = 0
    AND SP.STATUS NOT IN ('CORRETO','SUBSTITUIDO')
    UNION ALL
    SELECT TI.ID,
      'TituloInteracao'         AS CLASSE,
      P.NOME                    AS DESCRICAO,
      'Agenda Título Interação' AS TIPO,
      NULL                      AS OBSERVACAO,
      TI.ID_USUARIO,
      NULL                AS ID_PROCESSO,
      TI.DATA_AGENDAMENTO AS DH_TAREFA,
      ID_PESSOA           AS ID_ENTIDADE,
      'Pessoa'            AS ENTIDADE,
      'tomato'            AS ICONE,
      NULL                AS AJUDA
    FROM SBR_TITULO_INTERACAO TI
    INNER JOIN SBR_PESSOA P
    ON P.ID         = TI.ID_PESSOA
    WHERE TI.STATUS = 'ABERTO'
    ) Q,
    OCN_USUARIO U
  WHERE Q.ID_USUARIO = U.ID
 "
"
  
 "
"
 
 "
"
 
 "
"
 
 "
"
 
 "
"

 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_PRODUTO_ARK_STATUS" ("B1_COD", "STATUS") AS 
  SELECT B1_COD, CASE WHEN B1_STATUS = '1' THEN 'Norm.'
    WHEN B1_STATUS = '2' THEN 'Ate Fim Est.'
    WHEN B1_STATUS = '3' THEN 'Sob Enc.'
    WHEN B1_STATUS = '4' THEN 'Sem Prev.'
    WHEN B1_STATUS = '5' THEN 'Sob Cons.'
    ELSE 'No Status' END STATUS
 FROM SB1040 
WHERE B1_MSBLQL = '2'
  AND B1_TIPO = 'PA'
  AND D_E_L_E_T_ = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_ORDEM_PRODUCAO" ("ID", "ID_FILIAL", "NUMERO", "ITEM", "SEQUENCIA", "ID_SALDO_ARMAZEM", "QUANTIDADE", "DATA_PREVISTA_INICIO", "DATA_PREVISTA_ENTREGA", "DATA_EMISSAO", "QUANTIDADE_ATENDIDA", "DESTINO", "TIPO", "ROTEIRO", "SEQUENCIA_PAI", "STATUS", "FILIAL", "COD_PRODUTO", "ARMAZEM", "HORA_INICIO_OP") AS 
  SELECT OP.R_E_C_N_O_ ID,
       F.ID ID_FILIAL,
       OP.C2_NUM NUMERO,
       OP.C2_ITEM ITEM,
       OP.C2_SEQUEN SEQUENCIA,
       SA.ID ID_SALDO_ARMAZEM,
       OP.C2_QUANT QUANTIDADE,
       To_Date(Trim(OP.C2_DATPRI), 'YYYYMMDD') DATA_PREVISTA_INICIO,
       To_Date(Trim(OP.C2_DATPRF), 'YYYYMMDD') DATA_PREVISTA_ENTREGA,
       To_Date(Trim(OP.C2_EMISSAO), 'YYYYMMDD') DATA_EMISSAO,
       OP.C2_QUJE QUANTIDADE_ATENDIDA,
       OP.C2_DESTINA DESTINO,
       OP.C2_TPOP TIPO,
       OP.C2_ROTEIRO ROTEIRO,
       OP.C2_SEQPAI SEQUENCIA_PAI,
       OP.C2_STATUS STATUS,
       OP.C2_FILIAL,
       OP.C2_PRODUTO,
       OP.C2_LOCAL,
       OP.C2_HORAINI
  FROM SC2040 OP
  INNER JOIN SB1040 B1 ON B1.B1_FILIAL  = C2_FILIAL
                      AND B1.B1_COD     = C2_PRODUTO
                      AND B1.D_E_L_E_T_ = ' '
  INNER JOIN SB2040 B2 ON B2.B2_FILIAL = C2_FILIAL
                      AND B2.B2_COD    = C2_PRODUTO
                      AND B2.B2_LOCAL  = C2_LOCAL
                      AND B2.D_E_L_E_T_ = ' '
  INNER JOIN OCN_EMPRESA E ON E.CODIGO = To_Number('04')
  INNER JOIN OCN_FILIAL  F ON F.ID_EMPRESA = E.ID
                          AND F.CODIGO     = C2_FILIAL
  INNER JOIN OCN_REF_PRODUTO P ON P.CODIGO = Trim(C2_PRODUTO)
  INNER JOIN SBR_ARMAZEM A ON A.ID_FILIAL = F.ID
                          AND A.CODIGO    = B2_LOCAL
  INNER JOIN SBR_SALDO_ARMAZEM SA ON SA.ID_ARMAZEM = A.ID
                                 AND SA.ID_PRODUTO = P.ID
 WHERE OP.C2_FILIAL  = '01'
   AND OP.D_E_L_E_T_ = ' '
   AND (OP.C2_QUJE + OP.C2_PERDA) < OP.C2_QUANT
   AND OP.C2_DATRF    = ' '
 "
"
 
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_OPERACAO_PRODUCAO" ("ID", "CODIGO", "PRODUTO", "OPERACAO", "RECURSO", "DESCRICAO", "MAO_OBRA", "TEMPO_SETUP", "LOTE_PADRAO", "TEMPO_PADRAO", "HORA_TEMPO_PADRAO", "MINUTO_TEMPO_PADRAO", "HORA_TEMPO_SETUP", "MINUTO_TEMPO_SETUP") AS 
  SELECT R_E_C_N_O_,
       G2_CODIGO,
       G2_PRODUTO,
       G2_OPERAC,
       G2_RECURSO,
       G2_DESCRI,
       G2_MAOOBRA,
       G2_SETUP,
       G2_LOTEPAD,
       G2_TEMPAD,
       Trunc(G2_TEMPAD) HORA_TEMPO_PADRAO,
       100 * Mod(G2_TEMPAD,1) MINUTO_TEMPO_PADRAO,
       Trunc(G2_SETUP) HORA_TEMPO_SETUP,
       100 * Mod(G2_SETUP,1) MINUTO_TEMPO_SETUP
  FROM SG2040
 WHERE G2_FILIAL  = '01'
   AND D_E_L_E_T_ = ' '

 "
"
 
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_NECESSIDADE_COMPRAS_BLQ" ("ID", "SUBSTITUIDO", "ID_PRODUTO_BASE", "CODIGO_BASE", "ID_PRODUTO", "CODIGO", "DESCRICAO_FISCAL_COMPLETA", "ID_FORNECEDOR", "NOME", "PONTO_PEDIDO_CD", "PONTO_PEDIDO_FL", "SALDO_01_CD", "SALDO_01_CD_SUB", "SALDO_01_FL", "SALDO_01_FL_SUB", "RESERVA_01_CD", "RESERVA_01_FL", "RESERVA_01_CD_SUB", "EMPENHO_PRODUCAO", "PENDENCIAS_FILIAIS", "SOLICITACAO_COMPRA", "SOLICITACAO_COMPRA_SUB", "PEDIDO_COMPRA", "PEDIDO_COMPRA_SUB", "PRE_NOTA", "PRE_NOTA_SUB", "TRANSFERENCIA", "TRANSFERENCIA_SUB", "TRANSITO", "TRANSITO_SUB", "SALDO_FUTURO") AS 
  SELECT 
       ROWNUM AS ID,
       PB.SUBSTITUIDO,
       PB.ID AS ID_PRODUTO_BASE, 
       PB.CODIGO AS CODIGO_BASE, 
       P.ID AS ID_PRODUTO, 
       P.CODIGO, 
       P.DESCRICAO_FISCAL_COMPLETA, 
       PBF.ID_FORNECEDOR,
       PBF.NOME,
       COALESCE(IP.PONTO_PEDIDO,0) AS PONTO_PEDIDO_CD, 
       COALESCE(PFF.PONTO_PEDIDO_FL,0) AS PONTO_PEDIDO_FL, 
       COALESCE(SA.SALDO,0) AS SALDO_01_CD, 
       COALESCE(SAS.SALDO,0) AS SALDO_01_CD_SUB, 
       COALESCE(SF.SALDO,0) AS SALDO_01_FL, 
       COALESCE(SFS.SALDO,0) AS SALDO_01_FL_SUB, 
       COALESCE(RF.SALDO_RESERVADO,0) AS RESERVA_01_CD,
       COALESCE(RFFL.SALDO_RESERVADO,0) AS RESERVA_01_FL,
       COALESCE(RFS.SALDO_RESERVADO,0) AS RESERVA_01_CD_SUB,
       COALESCE(EP.EMPENHO_PRODUCAO,0) AS EMPENHO_PRODUCAO,
       COALESCE(PNDFL.PENDENCIAS_FILIAIS,0) AS PENDENCIAS_FILIAIS,       
       COALESCE(SP.QUANTIDADE,0) AS SOLICITACAO_COMPRA, COALESCE(SPS.QUANTIDADE,0) AS SOLICITACAO_COMPRA_SUB,
       COALESCE(PP.QUANTIDADE,0) AS PEDIDO_COMPRA, COALESCE(PPS.QUANTIDADE,0) AS PEDIDO_COMPRA_SUB,
       COALESCE(PN.QUANTIDADE,0) AS PRE_NOTA, COALESCE(PNS.QUANTIDADE,0) AS PRE_NOTA_SUB,
       COALESCE(PT.QUANTIDADE,0) AS TRANSFERENCIA, COALESCE(PTS.QUANTIDADE,0) AS TRANSFERENCIA_SUB, 
       COALESCE(NT.QUANTIDADE,0) AS TRANSITO, COALESCE(NTS.QUANTIDADE,0) AS TRANSITO_SUB,       
       COALESCE(SP.QUANTIDADE,0) + COALESCE(SPS.QUANTIDADE,0) + 
       COALESCE(PP.QUANTIDADE,0) + COALESCE(PPS.QUANTIDADE,0) + 
       COALESCE(PN.QUANTIDADE,0) + COALESCE(PNS.QUANTIDADE,0) + 
       COALESCE(PT.QUANTIDADE,0) + COALESCE(PTS.QUANTIDADE,0) + 
       COALESCE(NT.QUANTIDADE,0) + COALESCE(NTS.QUANTIDADE,0) AS SALDO_FUTURO
 FROM OCN_INFO_PRODUTO IP
INNER JOIN (SELECT ID_INFO_PRODUTO, ID_FILIAL, ID_PRODUTO FROM OCN_REF_PRODUTO_FILIAL WHERE ID_FILIAL = 1) PF ON PF.ID_INFO_PRODUTO = IP.ID 
INNER JOIN (SELECT ID, ID_PRODUTO_BASE, CODIGO, DESCRICAO_FISCAL_COMPLETA FROM OCN_REF_PRODUTO) P ON P.ID = PF.ID_PRODUTO
INNER JOIN (SELECT ID, CODIGO, SUBSTITUIDO, STATUS_GERAL, NOVO, ID_EMPRESA, TIPO_PRODUTO FROM OCN_PRODUTO_BASE) PB ON PB.ID = P.ID_PRODUTO_BASE
/* FORNECEDOR */
LEFT JOIN (SELECT PBF.ID_PRODUTO_BASE, PBF.ID_FORNECEDOR, FO.NOME AS NOME 
             FROM OCN_PRODUTO_BASE_FORNECEDOR PBF
            INNER JOIN (SELECT ID, NOME, ATIVO FROM OCN_FORNECEDOR) FO ON FO.ID = PBF.ID_FORNECEDOR 
            WHERE PBF.PRINCIPAL = 1 AND FO.ATIVO = 1 
          ) PBF ON PBF.ID_PRODUTO_BASE = P.ID_PRODUTO_BASE
/* PONTO PEDIDO FILIAIS */
LEFT JOIN (SELECT PFF.ID_PRODUTO, SUM(IPF.PONTO_PEDIDO) AS PONTO_PEDIDO_FL
             FROM OCN_REF_PRODUTO_FILIAL PFF 
            INNER JOIN (SELECT ID, PONTO_PEDIDO FROM OCN_REF_INFO_PRODUTO) IPF ON IPF.ID = PFF.ID_INFO_PRODUTO            
            WHERE PFF.ID_FILIAL NOT IN (1,2)
            GROUP BY PFF.ID_PRODUTO
          ) PFF ON PFF.ID_PRODUTO = P.ID
/* SALDO EM ARMAZEM CD (01) */
LEFT JOIN (SELECT SA.ID_PRODUTO, SUM(SA.SALDO) AS SALDO
             FROM SBR_SALDO_ARMAZEM SA 
            INNER JOIN (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = SA.ID_ARMAZEM 
            WHERE AR.ID_FILIAL IN (1,2) AND AR.CODIGO = '01'
            GROUP BY SA.ID_PRODUTO
           ) SA ON SA.ID_PRODUTO = P.ID
/* SALDO EM ARMAZEM CD SUBSTITUICOES (01) */
LEFT JOIN (SELECT PN.ID, SUM(SA.SALDO) AS SALDO FROM SBR_SALDO_ARMAZEM SA 
            INNER JOIN (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = SA.ID_ARMAZEM 
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = SA.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO
            WHERE PS.TIPO = 'P' AND AR.ID_FILIAL IN (1,2) AND AR.CODIGO = '01'
            GROUP BY PN.ID
          ) SAS ON SAS.ID = P.ID
/* SALDO EM ARMAZEM FILIAL (01) */
LEFT JOIN (SELECT SF.ID_PRODUTO, SUM(SF.SALDO) AS SALDO
             FROM SBR_SALDO_ARMAZEM SF 
            INNER JOIN (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = SF.ID_ARMAZEM 
            WHERE AR.ID_FILIAL NOT IN (1,2) AND AR.CODIGO = '01'
            GROUP BY SF.ID_PRODUTO
           ) SF ON SF.ID_PRODUTO = P.ID 
/* SALDO EM ARMAZEM FILIAL SUBSTITUICOES (01) */
LEFT JOIN (SELECT PN.ID, SUM(SA.SALDO) AS SALDO FROM SBR_SALDO_ARMAZEM SA 
            INNER JOIN (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = SA.ID_ARMAZEM 
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = SA.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO
            WHERE PS.TIPO = 'P' AND AR.ID_FILIAL NOT IN (1,2) AND AR.CODIGO = '01'
            GROUP BY PN.ID
          ) SFS ON SFS.ID = P.ID           
/* RESERVAS CD (01) */
LEFT JOIN (SELECT RF.ID_PRODUTO, SUM(RF.SALDO_RESERVADO) AS SALDO_RESERVADO
             FROM SBR_RESERVA_FATURAMENTO RF 
            INNER JOIN (SELECT ID, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = RF.ID_ARMAZEM
            WHERE AR.CODIGO = '01' AND RF.ID_FILIAL_FATURAMENTO IN (1,2) AND RF.STATUS = 'APROVADA' AND RF.SALDO_RESERVADO > 0 AND RF.EMISSAO <= CURRENT_DATE
            GROUP BY RF.ID_PRODUTO
          ) RF ON RF.ID_PRODUTO = P.ID 
/* RESERVAS SUBSTITUICOES CD (01) */           
LEFT JOIN (SELECT PN.ID, SUM(RF.SALDO_RESERVADO) AS SALDO_RESERVADO
             FROM SBR_RESERVA_FATURAMENTO RF 
            INNER JOIN (SELECT ID, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = RF.ID_ARMAZEM 
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = RF.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO            
            WHERE AR.CODIGO = '01' AND RF.ID_FILIAL_FATURAMENTO IN (1,2) AND PS.TIPO = 'P' AND RF.STATUS = 'APROVADA' AND RF.SALDO_RESERVADO > 0 AND RF.EMISSAO <= CURRENT_DATE
            GROUP BY PN.ID
          ) RFS ON RFS.ID = P.ID
/* RESERVAS FILIAIS (01) */
LEFT JOIN (SELECT RF.ID_PRODUTO, SUM(RF.SALDO_RESERVADO) AS SALDO_RESERVADO
             FROM SBR_RESERVA_FATURAMENTO RF 
            INNER JOIN (SELECT ID, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = RF.ID_ARMAZEM
            WHERE AR.CODIGO = '01' AND RF.ID_FILIAL_FATURAMENTO NOT IN (1,2) AND RF.STATUS = 'APROVADA' AND RF.SALDO_RESERVADO > 0 AND RF.EMISSAO <= CURRENT_DATE
            GROUP BY RF.ID_PRODUTO
          ) RFFL ON RFFL.ID_PRODUTO = P.ID 
/* EMPENHOS DE PRODUÇÃO (01) */
LEFT JOIN (SELECT P.ID, COALESCE(Sum(D4.D4_QUANT),0) AS EMPENHO_PRODUCAO 
             FROM SD4040 D4 
            INNER JOIN SB1040 B1 ON B1_COD =  D4.D4_COD 
            INNER JOIN OCN_REF_PRODUTO P ON TRIM(P.CODIGO) = TRIM(D4.D4_COD)
            INNER JOIN OCN_REF_PRODUTO_BASE PB ON PB.ID = P.ID_PRODUTO_BASE AND PB.SUBSTITUIDO = 0 AND PB.ID_EMPRESA = 2
            WHERE D4.D4_FILIAL  = '01' 
              AND D4.D_E_L_E_T_ = ' ' 
              GROUP BY P.ID
          ) EP ON EP.ID = P.ID
/* PENDENCIAS_FILIAIS OUTROS ARMAZENS */     
LEFT JOIN (SELECT SA.ID_PRODUTO, SUM(RF.SALDO_RESERVADO) AS PENDENCIAS_FILIAIS 
             FROM SBR_SALDO_ARMAZEM SA
            INNER JOIN (SELECT ID, CODIGO FROM SBR_ARMAZEM) AR ON AR.ID = SA.ID_ARMAZEM
            INNER JOIN (SELECT SALDO_RESERVADO, STATUS, EMISSAO, ID_ARMAZEM, ID_PRODUTO, ID_FILIAL, ID_FILIAL_FATURAMENTO FROM SBR_RESERVA_FATURAMENTO) RF ON RF.ID_PRODUTO = SA.ID_PRODUTO AND RF.ID_ARMAZEM = SA.ID_ARMAZEM
            WHERE RF.STATUS = 'APROVADA' AND RF.SALDO_RESERVADO > 0 AND RF.EMISSAO <= CURRENT_DATE AND AR.CODIGO != '01'
           HAVING SUM(DISTINCT SA.SALDO) < SUM(RF.SALDO_RESERVADO)
            GROUP BY SA.ID_PRODUTO
          ) PNDFL ON PNDFL.ID_PRODUTO = P.ID           
/* SOLICITAÇÕES DE COMPRA */
LEFT JOIN (SELECT SP.ID_PRODUTO, SUM(SP.QUANTIDADE_SOLICITACAO - (SP.QUANTIDADE_ATENDIDA + SP.QUANTIDADE_RESIDUO)) AS QUANTIDADE
             FROM SBR_SOLICITACAO_COMPRA_PRODUTO SP
            INNER JOIN (SELECT ID, STATUS FROM SBR_SOLICITACAO_COMPRA) SC ON SC.ID = SP.ID_SOLICITACAO 
            WHERE SC.STATUS = 'SOLICITACAO_EM_ABERTO' AND SP.QUANTIDADE_SOLICITACAO > (SP.QUANTIDADE_ATENDIDA + SP.QUANTIDADE_RESIDUO)
            GROUP BY SP.ID_PRODUTO
          ) SP ON SP.ID_PRODUTO = P.ID
/* SOLICITAÇÕES DE COMPRA SUBSTITUICOES */
LEFT JOIN (SELECT PN.ID, SUM(SP.QUANTIDADE_SOLICITACAO - (SP.QUANTIDADE_ATENDIDA + SP.QUANTIDADE_RESIDUO)) AS QUANTIDADE
             FROM SBR_SOLICITACAO_COMPRA_PRODUTO SP
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = SP.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO                         
            INNER JOIN (SELECT ID, STATUS FROM SBR_SOLICITACAO_COMPRA) SC ON SC.ID = SP.ID_SOLICITACAO 
            WHERE PS.TIPO = 'P' AND SC.STATUS = 'SOLICITACAO_EM_ABERTO' AND SP.QUANTIDADE_SOLICITACAO > (SP.QUANTIDADE_ATENDIDA + SP.QUANTIDADE_RESIDUO)
            GROUP BY PN.ID
          ) SPS ON SPS.ID = P.ID          
/* PEDIDOS DE COMPRA */
LEFT JOIN (SELECT PP.ID_PRODUTO, SUM(PP.QUANTIDADE - PP.QUANTIDADE_ATENDIDA) AS QUANTIDADE
             FROM SBR_PEDIDO_COMPRA_PRODUTO PP
            INNER JOIN (SELECT ID, STATUS, ID_FILIAL FROM SBR_PEDIDO_COMPRA) PC ON PC.ID = PP.ID_PEDIDO
            WHERE PC.STATUS = 'PEDIDO_EM_ABERTO' AND PP.ELIMINADO_RESIDUO = 0 AND PP.QUANTIDADE > PP.QUANTIDADE_ATENDIDA 
            GROUP BY PP.ID_PRODUTO
          ) PP ON PP.ID_PRODUTO = P.ID
/* PEDIDOS DE COMPRA SUBSTITUICOES */
LEFT JOIN (SELECT PN.ID, SUM(PP.QUANTIDADE - PP.QUANTIDADE_ATENDIDA) AS QUANTIDADE
             FROM SBR_PEDIDO_COMPRA_PRODUTO PP
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = PP.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO                                      
            INNER JOIN (SELECT ID, STATUS, ID_FILIAL FROM SBR_PEDIDO_COMPRA) PC ON PC.ID = PP.ID_PEDIDO
            WHERE PS.TIPO = 'P' AND PC.STATUS = 'PEDIDO_EM_ABERTO' AND PP.ELIMINADO_RESIDUO = 0 AND PP.QUANTIDADE > PP.QUANTIDADE_ATENDIDA 
            GROUP BY PN.ID
          ) PPS ON PPS.ID = P.ID
/* PRE NOTAS DE ENTRADA */
LEFT JOIN (SELECT NI.ID_PRODUTO, SUM(NI.QUANTIDADE) AS QUANTIDADE 
             FROM SBR_NOTAFISCAL_ITEM NI 
            INNER JOIN (SELECT ID, ID_FILIAL, ID_EMITENTE 
                          FROM SBR_PRE_NOTAFISCAL 
                         WHERE PRE_NF = 1 AND STATUS_PRE_NOTA = '0' AND TIPO_ES = '0' AND TIPO_NF = 'N') PN ON PN.ID = NI.ID_PRE_NOTAFISCAL
            INNER JOIN (SELECT ID_PESSOA, CNPJ FROM SBR_PESSOA_JURIDICA WHERE CNPJ NOT LIKE '01447737%' AND CNPJ NOT LIKE '01417367%') PJ ON PJ.ID_PESSOA = PN.ID_EMITENTE
            WHERE NI.ID_NOTAFISCAL IS NULL
            GROUP BY NI.ID_PRODUTO
           ) PN ON PN.ID_PRODUTO = P.ID
/* PRE NOTAS DE ENTRADA SUBSTITUICOES */
LEFT JOIN (SELECT PN.ID, SUM(NI.QUANTIDADE) AS QUANTIDADE 
             FROM SBR_NOTAFISCAL_ITEM NI 
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = NI.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO                                                   
            INNER JOIN (SELECT ID, ID_FILIAL, ID_EMITENTE 
                          FROM SBR_PRE_NOTAFISCAL 
                         WHERE PRE_NF = 1 AND STATUS_PRE_NOTA = '0' AND TIPO_ES = '0' AND TIPO_NF = 'N') PNT ON PNT.ID = NI.ID_PRE_NOTAFISCAL
            INNER JOIN (SELECT ID_PESSOA, CNPJ FROM SBR_PESSOA_JURIDICA WHERE CNPJ NOT LIKE '01447737%' AND CNPJ NOT LIKE '01417367%') PJ ON PJ.ID_PESSOA = PNT.ID_EMITENTE
            WHERE NI.ID_NOTAFISCAL IS NULL
            GROUP BY PN.ID
           ) PNS ON PNS.ID = P.ID
/* PEDIDOS DE TRANSFERENCIA  */
LEFT JOIN (SELECT PI.ID_PRODUTO, SUM(PI.QUANTIDADE) AS QUANTIDADE
             FROM SBR_PED_VENDA_ITEM PI
            INNER JOIN (SELECT ID, ID_STATUS 
                          FROM SBR_PED_VENDA 
                         WHERE ID_STATUS IN (17,21,24) AND ID_TIPO_PEDIDO = 6) PV ON PV.ID = PI.ID_PEDIDO
            WHERE 
              NOT EXISTS (
                  SELECT 'x' FROM SBR_NOTAFISCAL_ITEM NI 
                   WHERE NI.ID_PED_VENDA_ITEM = PI.ID AND PI.ELIMINADO_RESIDUO = 0 AND PI.QUANTIDADE > PI.QUANTIDADE_FATURADA
              )
            GROUP BY PI.ID_PRODUTO                 
          ) PT ON PT.ID_PRODUTO = P.ID 
/* PEDIDOS DE TRANSFERENCIA SUBSTITUICOES */
LEFT JOIN (SELECT PN.ID, SUM(PI.QUANTIDADE) AS QUANTIDADE
             FROM SBR_PED_VENDA_ITEM PI
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = PI.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO                                                                
            INNER JOIN (SELECT ID, ID_STATUS 
                          FROM SBR_PED_VENDA 
                         WHERE ID_STATUS IN (17,21,24) AND ID_TIPO_PEDIDO = 6) PV ON PV.ID = PI.ID_PEDIDO
            WHERE 
              NOT EXISTS (
                  SELECT 'x' FROM SBR_NOTAFISCAL_ITEM NI 
                   WHERE NI.ID_PED_VENDA_ITEM = PI.ID AND PI.ELIMINADO_RESIDUO = 0 AND PI.QUANTIDADE > PI.QUANTIDADE_FATURADA
              )
            GROUP BY PN.ID
          ) PTS ON PTS.ID = P.ID           
/* NOTAS EM TRANSITO */          
LEFT JOIN (SELECT NI.ID_PRODUTO, SUM(NI.QUANTIDADE) AS QUANTIDADE 
             FROM SBR_NOTAFISCAL_ITEM NI
            INNER JOIN (SELECT ID, ID_DESTINATARIO, ID_EMITENTE, SERIE, NFNUMERO FROM SBR_NOTAFISCAL
                         WHERE NOTA_PROPRIA = 1 AND TIPO_NF = 'N' AND STATUS_NFE = 'AU' AND TIPO_ES = '1' AND SITUACAO = '00'
                           AND ID_CFOP IN ('6150','6151','6152','6153','6155','6156','5150','5151','5152','5153','5155','5156')) NF ON NF.ID = NI.ID_NOTAFISCAL
            WHERE 
              (
                NOT EXISTS (
                    SELECT 'x' FROM SBR_PRE_NOTAFISCAL PF 
                     WHERE PF.TIPO_ES = '0' AND PF.NFNUMERO = NF.NFNUMERO AND PF.SERIE = NF.SERIE 
                       AND PF.ID_EMITENTE = NF.ID_EMITENTE AND PF.ID_DESTINATARIO = NF.ID_DESTINATARIO
                ) AND NOT EXISTS (
                    SELECT 'x' FROM SBR_NOTAFISCAL NFX 
                     WHERE NFX.TIPO_ES = '0' AND NFX.NFNUMERO = NF.NFNUMERO AND NFX.SERIE = NF.SERIE 
                       AND NFX.ID_EMITENTE = NF.ID_EMITENTE AND NFX.ID_DESTINATARIO = NF.ID_DESTINATARIO
                )
              )
              GROUP BY NI.ID_PRODUTO
) NT ON NT.ID_PRODUTO = P.ID 
/* NOTAS EM TRANSITO SUBSTITUICOES */          
LEFT JOIN (SELECT PN.ID, SUM(NI.QUANTIDADE) AS QUANTIDADE 
             FROM SBR_NOTAFISCAL_ITEM NI
            INNER JOIN OCN_REF_PRODUTO PA ON PA.ID = NI.ID_PRODUTO
            INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS ON PS.ID_PRODUTO_ANTIGO = PA.ID
            INNER JOIN OCN_REF_PRODUTO PN ON PN.ID = PS.ID_PRODUTO_NOVO                                                                
            INNER JOIN (SELECT ID, ID_DESTINATARIO, ID_EMITENTE, SERIE, NFNUMERO FROM SBR_NOTAFISCAL
                         WHERE NOTA_PROPRIA = 1 AND TIPO_NF = 'N' AND STATUS_NFE = 'AU' AND TIPO_ES = '1' AND SITUACAO = '00'
                           AND ID_CFOP IN ('6150','6151','6152','6153','6155','6156','5150','5151','5152','5153','5155','5156')) NF ON NF.ID = NI.ID_NOTAFISCAL
            WHERE 
              (
                NOT EXISTS (
                    SELECT 'x' FROM SBR_PRE_NOTAFISCAL PF 
                     WHERE PF.TIPO_ES = '0' AND PF.NFNUMERO = NF.NFNUMERO AND PF.SERIE = NF.SERIE 
                       AND PF.ID_EMITENTE = NF.ID_EMITENTE AND PF.ID_DESTINATARIO = NF.ID_DESTINATARIO
                ) AND NOT EXISTS (
                    SELECT 'x' FROM SBR_NOTAFISCAL NFX 
                     WHERE NFX.TIPO_ES = '0' AND NFX.NFNUMERO = NF.NFNUMERO AND NFX.SERIE = NF.SERIE 
                       AND NFX.ID_EMITENTE = NF.ID_EMITENTE AND NFX.ID_DESTINATARIO = NF.ID_DESTINATARIO
                )
              )
              GROUP BY PN.ID 
) NTS ON NTS.ID = P.ID 
WHERE (IP.STATUS = 'ATE_FIM_ESTOQUE' OR IP.BLOQUEADO = 1) AND PB.SUBSTITUIDO = 0 AND PB.STATUS_GERAL != 'CADASTRO' AND PB.TIPO_PRODUTO IN ('PA','PI','ME','IP','MP') AND (
  (
    ((COALESCE(SA.SALDO,0) + COALESCE(SAS.SALDO,0)) < (COALESCE(RF.SALDO_RESERVADO,0) + COALESCE(RFS.SALDO_RESERVADO,0) + COALESCE(EP.EMPENHO_PRODUCAO,0)))
  ) OR COALESCE(PNDFL.PENDENCIAS_FILIAIS,0) > 0)
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_NECESSIDADE_COMPRAS_01" ("ID", "SUBSTITUIDO", "ID_PRODUTO_BASE", "CODIGO_BASE", "ID_PRODUTO", "CODIGO", "DESCRICAO_FISCAL_COMPLETA", "ID_FORNECEDOR", "NOME", "PONTO_PEDIDO_CD", "PONTO_PEDIDO_FL", "SALDO_01_CD", "SALDO_01_CD_SUB", "SALDO_01_FL", "SALDO_01_FL_SUB", "RESERVA_01_CD", "RESERVA_01_FL", "RESERVA_01_CD_SUB", "EMPENHO_PRODUCAO", "PENDENCIAS_FILIAIS", "SOLICITACAO_COMPRA", "SOLICITACAO_COMPRA_SUB", "PEDIDO_COMPRA", "PEDIDO_COMPRA_SUB", "PRE_NOTA", "PRE_NOTA_SUB", "TRANSFERENCIA", "TRANSFERENCIA_SUB", "TRANSITO", "TRANSITO_SUB", "SALDO_FUTURO") AS 
  SELECT "ID","SUBSTITUIDO","ID_PRODUTO_BASE","CODIGO_BASE","ID_PRODUTO","CODIGO","DESCRICAO_FISCAL_COMPLETA","ID_FORNECEDOR","NOME","PONTO_PEDIDO_CD","PONTO_PEDIDO_FL","SALDO_01_CD","SALDO_01_CD_SUB","SALDO_01_FL","SALDO_01_FL_SUB","RESERVA_01_CD","RESERVA_01_FL","RESERVA_01_CD_SUB","EMPENHO_PRODUCAO","PENDENCIAS_FILIAIS","SOLICITACAO_COMPRA","SOLICITACAO_COMPRA_SUB","PEDIDO_COMPRA","PEDIDO_COMPRA_SUB","PRE_NOTA","PRE_NOTA_SUB","TRANSFERENCIA","TRANSFERENCIA_SUB","TRANSITO","TRANSITO_SUB","SALDO_FUTURO"        
      FROM SBR_INFO_COMPRAS_PRODUTO
     WHERE 
        (
          ((SALDO_01_CD + SALDO_01_CD_SUB) < (RESERVA_01_CD + EMPENHO_PRODUCAO)) OR
          (PONTO_PEDIDO_CD > ((SALDO_01_CD + SALDO_01_CD_SUB) - (RESERVA_01_CD  + EMPENHO_PRODUCAO)))
        ) OR PENDENCIAS_FILIAIS > 0
 "
"

 

 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_INFO_PRODUTOS_BLOQUEADOS" ("DATA_PREV_FATURAMENTO", "VALOR_A_FATURAR", "QTD_PRODUTOS_A_FATURAR", "QTD_ITENS_A_FATURAR", "VLR_TOTAL_ITENS_BLOQ", "QTD_PRODUTOS_BLOQUEADOS", "QTD_ITENS_BLOQUEADOS", "ID_FORNECEDOR", "ID_PRODUTO", "QTD_PEDIDOS", "VLR_TOTAL_ITENS_BLOQ_FORN", "QTD_PRODUTOS_BLOQUEADOS_FORN", "QTD_ITENS_BLOQUEADOS_FORN", "CODIGO", "DESCRICAO_FISCAL_COMPLETA", "TIPO_PRODUTO", "STATUS_PRODUTO", "SALDO_ATUAL", "RESERVAS", "PED_COMPRA", "PRE_NOTA", "SOLICITACAO_COMPRA", "PREV_FATURAMENTO_PC", "PREV_ENTREGA_PC", "QUANTIDADE_PC", "NOME_CARTEIRA", "IDCARTEIRA", "USR_RESPONSAVEL") AS 
  ( SELECT DISTINCT IV.DATA_PREV_FATURAMENTO,
    IV.VALOR_A_FATURAR,
    IV.QTD_PRODUTOS_A_FATURAR,
    IV.QTD_ITENS_A_FATURAR,
    IV.VLR_TOTAL_ITENS_BLOQ,
    IV.QTD_PRODUTOS_BLOQUEADOS,
    IV.QTD_ITENS_BLOQUEADOS,
    IV.ID_FORNECEDOR,
    IV.ID_PRODUTO,
    IV.QTD_PEDIDOS,
    IV.VLR_TOTAL_ITENS_BLOQ_FORN,
    IV.QTD_PRODUTOS_BLOQUEADOS_FORN,
    IV.QTD_ITENS_BLOQUEADOS_FORN,
    IC.CODIGO,
    IC.DESCRICAO_FISCAL_COMPLETA,
    IC.TIPO_PRODUTO,
    IC.STATUS_PRODUTO,
    IC.SALDO_ATUAL,
    IC.RESERVAS,
    IC.PED_COMPRA,
    IC.PRE_NOTA,
    IC.SOLICITACAO_COMPRA,
    IPC.PREV_FATURAMENTO AS PREV_FATURAMENTO_PC,
    IPC.PREV_ENTREGA     AS PREV_ENTREGA_PC,
    IPC.QUANTIDADE       AS QUANTIDADE_PC,
    CR.DESCRICAO AS NOME_CARTEIRA,
    CR.ID AS IDCARTEIRA,
    CR.ID_USUARIO_RESPONSAVEL AS USR_RESPONSAVEL
  FROM
    (SELECT IV.ID_PRODUTO,
      IV.ID_FORNECEDOR,
      COUNT(DISTINCT IV.PEDIDO)         AS QTD_PEDIDOS,
      MIN(IV.DATA_PREV_FATURAMENTO)     AS DATA_PREV_FATURAMENTO,
      SUM(IV.VALOR_A_FATURAR)           AS VALOR_A_FATURAR,
      SUM(IV.QTD_PRODUTOS_A_FATURAR)    AS QTD_PRODUTOS_A_FATURAR,
      SUM(IV.QTD_ITENS_A_FATURAR)       AS QTD_ITENS_A_FATURAR,
      SUM(IV.VLR_TOTAL_ITENS_BLOQ)      AS VLR_TOTAL_ITENS_BLOQ,
      SUM(IV.QTD_PRODUTOS_BLOQUEADOS)   AS QTD_PRODUTOS_BLOQUEADOS,
      SUM(IV.QTD_ITENS_BLOQUEADOS)      AS QTD_ITENS_BLOQUEADOS,
      SUM(IV.VLR_TOTAL_ITENS_BLOQ_FORN) AS VLR_TOTAL_ITENS_BLOQ_FORN,
      COUNT(DISTINCT IV.ID_PRODUTO)     AS QTD_PRODUTOS_BLOQUEADOS_FORN,
      SUM(IV.QTD_ITENS_BLOQUEADOS_FORN) AS QTD_ITENS_BLOQUEADOS_FORN
    FROM
      ( SELECT DISTINCT PV.ID
        || ' - '
        || 1 PEDIDO,
        PV.ID AS IDENTIDADE,
        PVI_TOT.SEQUENCIA,
        EMP.NOME_REDUZIDO
        || ' / '
        || FIL.CODIGO
        || ' - '
        || FIL.FILIAL_ABREV FILIAL,
        PES.ID
        || ' - '
        || PES.NOME CLIENTE,
        PV.DHPAGAMENTO DATA_PAGTO,
        PROXIMO_DIA_UTIL(PV.DHPAGAMENTO,NVL(PVF.DIA_FATURAMENTO,1)) DATA_PREV_FATURAMENTO,
        PROXIMO_DIA_UTIL(PVI_TOT.DATA_ENTREGA,EXTRACT(DAY FROM PV.DHPAGAMENTO -PV.DHFINALIZACAO)) DATA_PREV_ENTREGA,
        PV.VLR_LIQUIDO VLR_LIQUIDO,
        PVI_TOTAL.PRODUTO_TOTAL AS QTD_TOTAL_PRODUTOS,
        PVI_TOTAL.ITENS_TOTAL   AS QTD_TOTAL_ITENS,
        PVI_TOT.VALOR_A_FATURAR,
        PVI_TOT.QTD_PRD_A_FATURAR AS QTD_PRODUTOS_A_FATURAR,
        PVI_TOT.QTD_A_FATURAR     AS QTD_ITENS_A_FATURAR,
        PVI_TOT.VLR_TOTAL_ITENS_BLOQ,
        PVI_TOT.QTD_TOTAL_PRD_BLOQ   AS QTD_PRODUTOS_BLOQUEADOS,
        PVI_TOT.QTD_TOTAL_ITENS_BLOQ AS QTD_ITENS_BLOQUEADOS,
        PVI_TOT_FORN.ID_FORNECEDOR,
        PVI_TOT_FORN.ID_PRODUTO,
        PVI_TOT_FORN.VLR_TOTAL_ITENS_BLOQ AS VLR_TOTAL_ITENS_BLOQ_FORN,
        PVI_TOT_FORN.QTD_TOTAL_PRD_BLOQ   AS QTD_PRODUTOS_BLOQUEADOS_FORN,
        PVI_TOT_FORN.QTD_TOTAL_ITENS_BLOQ AS QTD_ITENS_BLOQUEADOS_FORN
      FROM SBR_PED_VENDA PV
      INNER JOIN OCN_FILIAL FIL
      ON FIL.ID = PV.ID_FILIAL
      INNER JOIN OCN_EMPRESA EMP
      ON FIL.ID_EMPRESA = EMP.ID
      INNER JOIN SBR_PESSOA PES
      ON PES.ID = PV.ID_PESSOA
      LEFT JOIN
        ( SELECT DISTINCT ID_PEDIDO,
          DIA_FATURAMENTO
        FROM SBR_PED_VENDA_FRETE PVF1
        WHERE DATA_ENTREGA =
          (SELECT MIN(PVF2.DATA_ENTREGA)
          FROM SBR_PED_VENDA_FRETE PVF2
          WHERE PVF2.ID_PEDIDO = PVF1.ID_PEDIDO
          )
        ) PVF
      ON PVF.ID_PEDIDO = PV.ID
      INNER JOIN
        (SELECT PVI.ID_PEDIDO,
          MIN(DATA_ENTREGA) DATA_ENTREGA,
          MIN(SEQUENCIA) SEQUENCIA,
          COUNT(PVI.ID) AS ,
          SUM(PVI2.QUANTIDADE_FATURADA) QTD_TOTAL_FATURADA,
          ROUND(SUM(
          CASE
            WHEN PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA > 0
            AND ELIMINADO_RESIDUO                         = 0
            THEN (VLR_UNITARIO * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_FRETE / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) - (PVI2.VLR_DESCONTO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_ACRESCIMO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA))
            ELSE 0
          END),2) VALOR_A_FATURAR,
          (SUM(PVI2.QUANTIDADE) - SUM(PVI2.QUANTIDADE_FATURADA)) QTD_A_FATURAR,
          COUNT(PVI2.ID_PRODUTO) QTD_PRD_A_FATURAR,
          SUM(
          CASE
            WHEN (GREATEST(NVL(SALDO_ARMAZEM,0),0) - SALDO_EMPENHADO_TOTAL) < (SALDO_RESERVADO - SALDO_EMPENHADO)
            THEN 1
            ELSE 0
          END ) QTD_TOTAL_PRD_BLOQ,
          SUM(
          CASE
            WHEN (NVL(SALDO_ARMAZEM,0) - SALDO_EMPENHADO_TOTAL) < (SALDO_RESERVADO - SALDO_EMPENHADO)
            THEN (PVI.QUANTIDADE       - PVI.QUANTIDADE_FATURADA) - (GREATEST(NVL(SALDO_ARMAZEM,0),0) - SALDO_EMPENHADO_TOTAL)
            ELSE 0
          END ) QTD_TOTAL_ITENS_BLOQ,
          SUM(
          CASE
            WHEN (GREATEST(NVL(SALDO_ARMAZEM,0),0) - SALDO_EMPENHADO_TOTAL) < (SALDO_RESERVADO - SALDO_EMPENHADO)
            THEN ((PVI.VLR_UNITARIO                *(PVI2.QUANTIDADE - PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_FRETE / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) - (PVI2.VLR_DESCONTO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_ACRESCIMO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) )
            ELSE 0
          END ) VLR_TOTAL_ITENS_BLOQ
        FROM
          (SELECT MAX(PVIALL.ID) ID,
            PVIALL.ID_PEDIDO,
            PVIALL.ID_PRODUTO,
            PVIALL.ITEM,
            SUM(PVIALL.VLR_FRETE) VLR_FRETE,
            SUM(PVIALL.VLR_DESCONTO) VLR_DESCONTO,
            SUM(PVIALL.VLR_ACRESCIMO) VLR_ACRESCIMO,
            SUM(PVIALL.QUANTIDADE) QUANTIDADE,
            SUM(PVIALL.QUANTIDADE_FATURADA) QUANTIDADE_FATURADA
          FROM SBR_RESERVA_FATURAMENTO RFALL
          INNER JOIN SBR_PED_VENDA_ITEM PVIALL
          ON PVIALL.ID                 = RFALL.ID_PEDIDO_ITEM
          WHERE PVIALL.SEQUENCIA      <> 4
          AND PVIALL.ELIMINADO_RESIDUO = 0
          AND RFALL.STATUS             = 'APROVADA'
          AND SALDO_RESERVADO          > 0
          GROUP BY PVIALL.ID_PEDIDO,
            PVIALL.ID_PRODUTO,
            PVIALL.ITEM
          ) PVI2
        INNER JOIN OCEAN.SBR_PED_VENDA_ITEM PVI
        ON PVI.ID = PVI2.ID
        INNER JOIN
          (SELECT ID_PEDIDO,
            ID_PRODUTO,
            SUM(SALDO_RESERVADO) SALDO_RESERVADO,
            SUM(QTD_EMPENHO) SALDO_EMPENHADO
          FROM SBR_RESERVA_FATURAMENTO
          WHERE STATUS        = 'APROVADA'
          AND SALDO_RESERVADO > 0
          AND (ID_PRIORIDADE IN
            (SELECT ID
            FROM SBR_PED_VENDA_PRIORIDADE
            WHERE CONSTANTES IN ('NORMAL', 'TRANSFERENCIA')
            )
          OR ID_PRIORIDADE IS NULL )
          GROUP BY ID_PEDIDO,
            ID_PRODUTO
          ) RF
        ON RF.ID_PEDIDO    = PVI.ID_PEDIDO
        AND PVI.ID_PRODUTO = RF.ID_PRODUTO
        LEFT JOIN
          (SELECT ID_PRODUTO,
            SUM(SALDO) SALDO_ARMAZEM
          FROM SBR_SALDO_ARMAZEM SA
          INNER JOIN SBR_ARMAZEM AR
          ON SA.ID_ARMAZEM         = AR.ID
          WHERE AR.ATIVO           = 1
          AND AR.BLOQUEADO_ENTRADA =0
          AND AR.BLOQUEADO_SAIDA   =0
          AND AR.TIPO              = 'CD'
          AND AR.PADRAO_SAIDA      = 1
          GROUP BY ID_PRODUTO
          ) SLD_ARM ON SLD_ARM.ID_PRODUTO = PVI.ID_PRODUTO
        LEFT JOIN
          (SELECT ID_PRODUTO,
            SUM(QTD_EMPENHO) SALDO_EMPENHADO_TOTAL
          FROM SBR_RESERVA_FATURAMENTO
          WHERE STATUS        = 'APROVADA'
          AND SALDO_RESERVADO > 0
          GROUP BY ID_PRODUTO
          ) RF_EMP
        ON RF_EMP.ID_PRODUTO  = PVI.ID_PRODUTO
        WHERE SEQUENCIA      <> 4
        AND ELIMINADO_RESIDUO = 0
        GROUP BY PVI.ID_PEDIDO
        ) PVI_TOT ON PVI_TOT.ID_PEDIDO = PV.ID
      AND PVI_TOT.VALOR_A_FATURAR      > 0
      AND PVI_TOT.QTD_TOTAL_ITENS_BLOQ > 0
      INNER JOIN
        (SELECT PVI.ID_PEDIDO,
          PVI.ID_PRODUTO,
          PBF.ID_FORNECEDOR,
          MIN(DATA_ENTREGA) DATA_ENTREGA,
          MIN(SEQUENCIA) SEQUENCIA,
          COUNT(PVI.ID) AS ,
          SUM(PVI2.QUANTIDADE_FATURADA) QTD_TOTAL_FATURADA,
          ROUND(SUM(
          CASE
            WHEN PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA > 0
            AND ELIMINADO_RESIDUO                         = 0
            THEN (VLR_UNITARIO * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_FRETE / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) - (PVI2.VLR_DESCONTO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_ACRESCIMO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA))
            ELSE 0
          END),2) VALOR_A_FATURAR,
          (SUM(PVI2.QUANTIDADE) - SUM(PVI2.QUANTIDADE_FATURADA)) QTD_A_FATURAR,
          COUNT(PVI2.ID_PRODUTO) QTD_PRD_A_FATURAR,
          SUM(
          CASE
            WHEN (GREATEST(NVL(SALDO_ARMAZEM,0),0) - SALDO_EMPENHADO_TOTAL) < (SALDO_RESERVADO - SALDO_EMPENHADO)
            THEN 1
            ELSE 0
          END ) QTD_TOTAL_PRD_BLOQ,
          SUM(
          CASE
            WHEN (NVL(SALDO_ARMAZEM,0) - SALDO_EMPENHADO_TOTAL) < (SALDO_RESERVADO - SALDO_EMPENHADO)
            THEN (PVI.QUANTIDADE       - PVI.QUANTIDADE_FATURADA) - (GREATEST(NVL(SALDO_ARMAZEM,0),0) - SALDO_EMPENHADO_TOTAL)
            ELSE 0
          END ) QTD_TOTAL_ITENS_BLOQ,
          SUM(
          CASE
            WHEN (GREATEST(NVL(SALDO_ARMAZEM,0),0) - SALDO_EMPENHADO_TOTAL) < (SALDO_RESERVADO - SALDO_EMPENHADO)
            THEN ((PVI.VLR_UNITARIO                *(PVI2.QUANTIDADE - PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_FRETE / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) - (PVI2.VLR_DESCONTO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) + (PVI2.VLR_ACRESCIMO / PVI2.QUANTIDADE * (PVI2.QUANTIDADE-PVI2.QUANTIDADE_FATURADA)) )
            ELSE 0
          END ) VLR_TOTAL_ITENS_BLOQ
        FROM
          (SELECT MAX(PVIALL.ID) ID,
            PVIALL.ID_PEDIDO,
            PVIALL.ID_PRODUTO,
            PVIALL.ITEM,
            SUM(PVIALL.VLR_FRETE) VLR_FRETE,
            SUM(PVIALL.VLR_DESCONTO) VLR_DESCONTO,
            SUM(PVIALL.VLR_ACRESCIMO) VLR_ACRESCIMO,
            SUM(PVIALL.QUANTIDADE) QUANTIDADE,
            SUM(PVIALL.QUANTIDADE_FATURADA) QUANTIDADE_FATURADA
          FROM SBR_RESERVA_FATURAMENTO RFALL
          INNER JOIN SBR_PED_VENDA_ITEM PVIALL
          ON PVIALL.ID                 = RFALL.ID_PEDIDO_ITEM
          WHERE PVIALL.SEQUENCIA      <> 4
          AND PVIALL.ELIMINADO_RESIDUO = 0
          AND RFALL.STATUS             = 'APROVADA'
          AND SALDO_RESERVADO          > 0
          GROUP BY PVIALL.ID_PEDIDO,
            PVIALL.ID_PRODUTO,
            PVIALL.ITEM
          ) PVI2
        INNER JOIN OCEAN.SBR_PED_VENDA_ITEM PVI
        ON PVI.ID = PVI2.ID
        INNER JOIN OCN_INFO_PRODUTO_FORNECEDOR IOF
        ON IOF.ID_PRODUTO = PVI.ID_PRODUTO
        INNER JOIN OCN_PRODUTO_BASE_FORNECEDOR PBF
        ON PBF.ID         = IOF.ID_PRODUTO_BASE_FORNECEDOR
        AND PBF.PRINCIPAL = 1
        INNER JOIN
          (SELECT ID_PEDIDO,
            ID_PRODUTO,
            SUM(SALDO_RESERVADO) SALDO_RESERVADO,
            SUM(QTD_EMPENHO) SALDO_EMPENHADO
          FROM SBR_RESERVA_FATURAMENTO
          WHERE STATUS        = 'APROVADA'
          AND SALDO_RESERVADO > 0
          AND (ID_PRIORIDADE IN
            (SELECT ID
            FROM SBR_PED_VENDA_PRIORIDADE
            WHERE CONSTANTES IN ('NORMAL', 'TRANSFERENCIA')
            )
          OR ID_PRIORIDADE IS NULL )
          GROUP BY ID_PEDIDO,
            ID_PRODUTO
          ) RF
        ON RF.ID_PEDIDO    = PVI.ID_PEDIDO
        AND PVI.ID_PRODUTO = RF.ID_PRODUTO
        LEFT JOIN
          (SELECT ID_PRODUTO,
            SUM(SALDO) SALDO_ARMAZEM
          FROM SBR_SALDO_ARMAZEM SA
          INNER JOIN SBR_ARMAZEM AR
          ON SA.ID_ARMAZEM         = AR.ID
          WHERE AR.ATIVO           = 1
          AND AR.BLOQUEADO_ENTRADA =0
          AND AR.BLOQUEADO_SAIDA   =0
          AND AR.TIPO              = 'CD'
          AND AR.PADRAO_SAIDA      = 1
          GROUP BY ID_PRODUTO
          ) SLD_ARM ON SLD_ARM.ID_PRODUTO = PVI.ID_PRODUTO
        LEFT JOIN
          (SELECT ID_PRODUTO,
            SUM(QTD_EMPENHO) SALDO_EMPENHADO_TOTAL
          FROM SBR_RESERVA_FATURAMENTO
          WHERE STATUS        = 'APROVADA'
          AND SALDO_RESERVADO > 0
          GROUP BY ID_PRODUTO
          ) RF_EMP
        ON RF_EMP.ID_PRODUTO  = PVI.ID_PRODUTO
        WHERE SEQUENCIA      <> 4
        AND ELIMINADO_RESIDUO = 0
        GROUP BY PVI.ID_PEDIDO,
          PVI.ID_PRODUTO,
          PBF.ID_FORNECEDOR
        ) PVI_TOT_FORN ON PVI_TOT_FORN.ID_PEDIDO = PV.ID
      AND PVI_TOT_FORN.VALOR_A_FATURAR           > 0
      AND PVI_TOT_FORN.QTD_TOTAL_ITENS_BLOQ      > 0
      INNER JOIN
        (SELECT PV.ID          AS ID_PEDIDO,
          SUM(PVI.QUANTIDADE)  AS ITENS_TOTAL,
          COUNT(PVI.ID_PRODUTO)AS PRODUTO_TOTAL
        FROM SBR_PED_VENDA PV
        INNER JOIN SBR_PED_VENDA_ITEM PVI
        ON PVI.ID_PEDIDO = PV.ID
        GROUP BY PV.ID
        ) PVI_TOTAL ON PVI_TOTAL.ID_PEDIDO = PV.ID
      INNER JOIN SBR_PED_VENDA_ITEM PVI
      ON PVI.ID_PEDIDO    = PV.ID
      WHERE PV.ID_STATUS <> 22
      AND NOT EXISTS
        (SELECT 'X' FROM OCN_FILIAL F WHERE F.ID_PESSOA = PV.ID_PESSOA
        )
      ) IV
    GROUP BY IV.ID_PRODUTO,
      IV.ID_FORNECEDOR
    ) IV
  INNER JOIN
    (SELECT NC.ID_PRODUTO,
      NC.CODIGO,
      NC.DESCRICAO_FISCAL_COMPLETA,
      PB.TIPO_PRODUTO,
      OIP.STATUS                                                               AS STATUS_PRODUTO,
      SUM(COALESCE(SALDO_01_CD,0)        + COALESCE(SALDO_01_CD_SUB,0))        AS SALDO_ATUAL,
      SUM(COALESCE(RESERVA_01_CD,0)      + COALESCE(RESERVA_01_CD_SUB,0))      AS RESERVAS,
      SUM(COALESCE(PEDIDO_COMPRA,0)      + COALESCE(PEDIDO_COMPRA_SUB,0))      AS PED_COMPRA,
      SUM(COALESCE(PRE_NOTA,0)           + COALESCE(PRE_NOTA_SUB,0))           AS PRE_NOTA,
      SUM(COALESCE(SOLICITACAO_COMPRA,0) + COALESCE(SOLICITACAO_COMPRA_SUB,0)) AS SOLICITACAO_COMPRA
    FROM SBR_NECESSIDADE_COMPRAS_01 NC
    INNER JOIN OCN_PRODUTO_BASE PB
    ON PB.ID = NC.ID_PRODUTO_BASE
    LEFT JOIN OCN_PRODUTO_FILIAL OPF
    ON OPF.ID_PRODUTO = NC.ID_PRODUTO
    AND OPF.ID_FILIAL = 1
    LEFT JOIN OCN_INFO_PRODUTO OIP
    ON OIP.ID = OPF.ID_INFO_PRODUTO
    GROUP BY NC.ID_PRODUTO,
      NC.CODIGO,
      NC.DESCRICAO_FISCAL_COMPLETA,
      PB.TIPO_PRODUTO,
      OIP.STATUS
    ) IC ON IC.ID_PRODUTO = IV.ID_PRODUTO
  LEFT JOIN
    (SELECT PC.ID_FORNECEDOR,
      PCP.ID_PRODUTO,
      MAX(PC.FATURAMENTO_FORNECEDOR)                AS PREV_FATURAMENTO,
      MAX(PC.DATA_PREVISAO_ENTREGA)                 AS PREV_ENTREGA,
      SUM(PCP.QUANTIDADE - PCP.QUANTIDADE_ATENDIDA) AS QUANTIDADE
    FROM SBR_PEDIDO_COMPRA PC
    INNER JOIN SBR_PEDIDO_COMPRA_PRODUTO PCP
    ON PCP.ID_PEDIDO = PC.ID
    WHERE PC.STATUS  = 'PEDIDO_EM_ABERTO'
    AND PC.ID        =
      (SELECT MAX(PCA.ID)
      FROM SBR_PEDIDO_COMPRA PCA
      INNER JOIN SBR_PEDIDO_COMPRA_PRODUTO PCPA
      ON PCPA.ID_PEDIDO     = PCA.ID
      WHERE PCA.STATUS      = 'PEDIDO_EM_ABERTO'
      AND PCA.ID_FORNECEDOR = PC.ID_FORNECEDOR
      AND PCPA.ID_PRODUTO   = PCP.ID_PRODUTO
      )
    GROUP BY PC.ID_FORNECEDOR,
      PCP.ID_PRODUTO
    ) IPC ON IPC.ID_PRODUTO = IV.ID_PRODUTO
  AND IPC.ID_FORNECEDOR     = IV.ID_FORNECEDOR
  LEFT JOIN OCN_CARTEIRA_FORNECEDOR CF
  ON CF.ID_FORNECEDOR = IV.ID_FORNECEDOR
  LEFT JOIN OCN_CARTEIRA_COMPRA CR
  ON CR.ID = CF.ID_CARTEIRA
  )
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_INFO_COMPRAS_PRODUTO" ("ID", "SUBSTITUIDO", "ID_PRODUTO_BASE", "CODIGO_BASE", "ID_PRODUTO", "CODIGO", "DESCRICAO_FISCAL_COMPLETA", "ID_FORNECEDOR", "NOME", "PONTO_PEDIDO_CD", "PONTO_PEDIDO_FL", "SALDO_01_CD", "SALDO_01_CD_SUB", "SALDO_01_FL", "SALDO_01_FL_SUB", "RESERVA_01_CD", "RESERVA_01_FL", "RESERVA_01_CD_SUB", "EMPENHO_PRODUCAO", "PENDENCIAS_FILIAIS", "SOLICITACAO_COMPRA", "SOLICITACAO_COMPRA_SUB", "PEDIDO_COMPRA", "PEDIDO_COMPRA_SUB", "PRE_NOTA", "PRE_NOTA_SUB", "TRANSFERENCIA", "TRANSFERENCIA_SUB", "TRANSITO", "TRANSITO_SUB", "SALDO_FUTURO") AS 
  SELECT ROWNUM AS ID,
    PB.SUBSTITUIDO,
    PB.ID     AS ID_PRODUTO_BASE,
    PB.CODIGO AS CODIGO_BASE,
    P.ID      AS ID_PRODUTO,
    P.CODIGO,
    P.DESCRICAO_FISCAL_COMPLETA,
    PBF.ID_FORNECEDOR,
    PBF.NOME,
    COALESCE(IP.PONTO_PEDIDO,0)                                                                                                               AS PONTO_PEDIDO_CD,
    COALESCE(PFF.PONTO_PEDIDO_FL,0)                                                                                                           AS PONTO_PEDIDO_FL,
    (COALESCE(SA.SALDO,0) + COALESCE(SA_99.SALDO,0))                                                                                          AS SALDO_01_CD,
    COALESCE(SAS.SALDO,0)                                                                                                                     AS SALDO_01_CD_SUB,
    COALESCE(SF.SALDO,0)                                                                                                                      AS SALDO_01_FL,
    COALESCE(SFS.SALDO,0)                                                                                                                     AS SALDO_01_FL_SUB,
    COALESCE(RF.SALDO_RESERVADO,0)                                                                                                            AS RESERVA_01_CD,
    COALESCE(RFFL.SALDO_RESERVADO,0)                                                                                                          AS RESERVA_01_FL,
    0                                                                                                                                         AS RESERVA_01_CD_SUB,
    COALESCE(EP.EMPENHO_PRODUCAO,0)                                                                                                           AS EMPENHO_PRODUCAO,
    COALESCE(PNDFL.PENDENCIAS_FILIAIS,0)                                                                                                      AS PENDENCIAS_FILIAIS,
    COALESCE(SP.QUANTIDADE,0)                                                                                                                 AS SOLICITACAO_COMPRA,
    0                                                                                                                                         AS SOLICITACAO_COMPRA_SUB,
    COALESCE(PP.QUANTIDADE,0)                                                                                                                 AS PEDIDO_COMPRA,
    0                                                                                                                                         AS PEDIDO_COMPRA_SUB,
    COALESCE(PN.QUANTIDADE,0)                                                                                                                 AS PRE_NOTA,
    0                                                                                                                                         AS PRE_NOTA_SUB,
    COALESCE(PT.QUANTIDADE,0)                                                                                                                 AS TRANSFERENCIA,
    0                                                                                                                                         AS TRANSFERENCIA_SUB,
    COALESCE(NT.QUANTIDADE,0)                                                                                                                 AS TRANSITO,
    0                                                                                                                                         AS TRANSITO_SUB,
    COALESCE(SP.QUANTIDADE,0) + COALESCE(PP.QUANTIDADE,0) + COALESCE(PN.QUANTIDADE,0) + COALESCE(PT.QUANTIDADE,0) + COALESCE(NT.QUANTIDADE,0) AS SALDO_FUTURO
  FROM OCN_INFO_PRODUTO IP
  INNER JOIN
    (SELECT ID_INFO_PRODUTO,
      ID_FILIAL,
      ID_PRODUTO
    FROM OCN_REF_PRODUTO_FILIAL
    WHERE ID_FILIAL = 1
    ) PF
  ON PF.ID_INFO_PRODUTO = IP.ID
  INNER JOIN
    (SELECT ID,
      ID_PRODUTO_BASE,
      CODIGO,
      DESCRICAO_FISCAL_COMPLETA
    FROM OCN_REF_PRODUTO
    ) P
  ON P.ID = PF.ID_PRODUTO
  INNER JOIN
    (SELECT ID,
      CODIGO,
      SUBSTITUIDO,
      STATUS_GERAL,
      NOVO,
      TIPO_PRODUTO
    FROM OCN_PRODUTO_BASE
    ) PB
  ON PB.ID = P.ID_PRODUTO_BASE
    /* FORNECEDOR */
  LEFT JOIN
    (SELECT PBF.ID_PRODUTO_BASE,
      PBF.ID_FORNECEDOR,
      FO.NOME AS NOME
    FROM OCN_PRODUTO_BASE_FORNECEDOR PBF
    INNER JOIN
      (SELECT ID, NOME, ATIVO FROM OCN_FORNECEDOR
      ) FO
    ON FO.ID                     = PBF.ID_FORNECEDOR
    WHERE PBF.PRINCIPAL          = 1
    AND FO.ATIVO                 = 1
    ) PBF ON PBF.ID_PRODUTO_BASE = P.ID_PRODUTO_BASE
    /* PONTO PEDIDO FILIAIS */
  LEFT JOIN
    (SELECT PFF.ID_PRODUTO,
      SUM(IPF.PONTO_PEDIDO) AS PONTO_PEDIDO_FL
    FROM OCN_REF_PRODUTO_FILIAL PFF
    INNER JOIN
      (SELECT ID, PONTO_PEDIDO FROM OCN_REF_INFO_PRODUTO
      ) IPF
    ON IPF.ID = PFF.ID_INFO_PRODUTO
    INNER JOIN OCN_FILIAL F
    ON F.ID                  = PFF.ID_FILIAL
    AND F.ATIVO              = 1
    WHERE PFF.ID_FILIAL NOT IN (1,2)
    GROUP BY PFF.ID_PRODUTO
    ) PFF ON PFF.ID_PRODUTO = P.ID
    /* SALDO EM ARMAZEM CD (01) */
  LEFT JOIN
    (SELECT SA.ID_PRODUTO,
      SUM(SA.SALDO) AS SALDO
    FROM SBR_SALDO_ARMAZEM SA
    INNER JOIN
      (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID            = SA.ID_ARMAZEM
    WHERE AR.ID_FILIAL IN (1,2)
    AND AR.CODIGO       = '01'
    GROUP BY SA.ID_PRODUTO
    ) SA ON SA.ID_PRODUTO = P.ID
    /* SALDO EM ARMAZEM CD SUBSTITUICOES (01) */
  LEFT JOIN
    (SELECT PN.ID,
      SUM(SA.SALDO) AS SALDO
    FROM SBR_SALDO_ARMAZEM SA
    INNER JOIN
      (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID = SA.ID_ARMAZEM
    INNER JOIN OCN_REF_PRODUTO PA
    ON PA.ID = SA.ID_PRODUTO
    INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS
    ON PS.ID_PRODUTO_ANTIGO = PA.ID
    INNER JOIN OCN_REF_PRODUTO PN
    ON PN.ID          = PS.ID_PRODUTO_NOVO
    WHERE PS.TIPO     = 'P'
    AND AR.ID_FILIAL IN (1,2)
    AND AR.CODIGO     = '01'
    GROUP BY PN.ID
    ) SAS ON SAS.ID = P.ID
    /* SALDO EM ARMAZEM FILIAL (01) */
  LEFT JOIN
    (SELECT SF.ID_PRODUTO,
      SUM(SF.SALDO) AS SALDO
    FROM SBR_SALDO_ARMAZEM SF
    INNER JOIN
      (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID                = SF.ID_ARMAZEM
    WHERE AR.ID_FILIAL NOT IN (1,2)
    AND AR.CODIGO           = '01'
    GROUP BY SF.ID_PRODUTO
    ) SF ON SF.ID_PRODUTO = P.ID
    /* SALDO EM ARMAZEM FILIAL SUBSTITUICOES (01) */
  LEFT JOIN
    (SELECT PN.ID,
      SUM(SA.SALDO) AS SALDO
    FROM SBR_SALDO_ARMAZEM SA
    INNER JOIN
      (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID = SA.ID_ARMAZEM
    INNER JOIN OCN_REF_PRODUTO PA
    ON PA.ID = SA.ID_PRODUTO
    INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS
    ON PS.ID_PRODUTO_ANTIGO = PA.ID
    INNER JOIN OCN_REF_PRODUTO PN
    ON PN.ID              = PS.ID_PRODUTO_NOVO
    WHERE PS.TIPO         = 'P'
    AND AR.ID_FILIAL NOT IN (1,2)
    AND AR.CODIGO         = '01'
    GROUP BY PN.ID
    ) SFS ON SFS.ID = P.ID
    /* SALDO EM ARMAZEM 99 (MP) */
  LEFT JOIN
    (SELECT SA.ID_PRODUTO,
      SUM(SA.SALDO) AS SALDO
    FROM SBR_SALDO_ARMAZEM SA
    INNER JOIN
      (SELECT ID, ID_FILIAL, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID            = SA.ID_ARMAZEM
    WHERE AR.ID_FILIAL IN (1)
    AND AR.CODIGO       = '99'
    GROUP BY SA.ID_PRODUTO
    ) SA_99 ON SA_99.ID_PRODUTO = P.ID
    /* RESERVAS CD (01) */
  LEFT JOIN
    (SELECT RF.ID_PRODUTO,
      SUM(RF.SALDO_RESERVADO) AS SALDO_RESERVADO
    FROM SBR_RESERVA_FATURAMENTO RF
    INNER JOIN
      (SELECT ID, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID                      = RF.ID_ARMAZEM
    WHERE AR.CODIGO               = '01'
    AND RF.ID_FILIAL_FATURAMENTO IN (1,2)
    AND RF.STATUS                 = 'APROVADA'
    AND RF.SALDO_RESERVADO        > 0
    AND RF.EMISSAO               <= CURRENT_DATE
    GROUP BY RF.ID_PRODUTO
    ) RF ON RF.ID_PRODUTO = P.ID
    /* RESERVAS SUBSTITUICOES CD (01) */
  LEFT JOIN
    (SELECT PN.ID,
      SUM(RF.SALDO_RESERVADO) AS SALDO_RESERVADO
    FROM SBR_RESERVA_FATURAMENTO RF
    INNER JOIN
      (SELECT ID, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID = RF.ID_ARMAZEM
    INNER JOIN OCN_REF_PRODUTO PA
    ON PA.ID = RF.ID_PRODUTO
    INNER JOIN OCN_PRODUTO_SUBSTITUICAO PS
    ON PS.ID_PRODUTO_ANTIGO = PA.ID
    INNER JOIN OCN_REF_PRODUTO PN
    ON PN.ID                      = PS.ID_PRODUTO_NOVO
    WHERE AR.CODIGO               = '01'
    AND RF.ID_FILIAL_FATURAMENTO IN (1,2)
    AND PS.TIPO                   = 'P'
    AND RF.STATUS                 = 'APROVADA'
    AND RF.SALDO_RESERVADO        > 0
    AND RF.EMISSAO               <= CURRENT_DATE
    GROUP BY PN.ID
    ) RFS ON RFS.ID = P.ID
    /* RESERVAS FILIAIS (01) */
  LEFT JOIN
    (SELECT RF.ID_PRODUTO,
      SUM(RF.SALDO_RESERVADO) AS SALDO_RESERVADO
    FROM SBR_RESERVA_FATURAMENTO RF
    INNER JOIN
      (SELECT ID, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID                          = RF.ID_ARMAZEM
    WHERE AR.CODIGO                   = '01'
    AND RF.ID_FILIAL_FATURAMENTO NOT IN (1,2)
    AND RF.STATUS                     = 'APROVADA'
    AND RF.SALDO_RESERVADO            > 0
    AND RF.EMISSAO                   <= CURRENT_DATE
    GROUP BY RF.ID_PRODUTO
    ) RFFL ON RFFL.ID_PRODUTO = P.ID
    /* EMPENHOS DE PRODUÇÃO (01) */
  LEFT JOIN
    (SELECT P.ID,
      COALESCE(SUM(D4.D4_QUANT),0) AS EMPENHO_PRODUCAO
    FROM SD4040 D4
    INNER JOIN SB1040 B1
    ON B1_COD = D4.D4_COD
    INNER JOIN OCN_REF_PRODUTO P
    ON TRIM(P.CODIGO) = TRIM(D4.D4_COD)
    INNER JOIN OCN_REF_PRODUTO_BASE PB
    ON PB.ID           = P.ID_PRODUTO_BASE
    AND PB.SUBSTITUIDO = 0
    AND PB.ID_EMPRESA  = 2
    WHERE D4.D4_FILIAL = '01'
    AND B1.B1_TIPO     = 'MP'
    AND D4.D_E_L_E_T_  = ' '
    GROUP BY P.ID
    ) EP ON EP.ID = P.ID
    /* PENDENCIAS_FILIAIS OUTROS ARMAZENS */
  LEFT JOIN
    (SELECT SA.ID_PRODUTO,
      SUM(RF.SALDO_RESERVADO) AS PENDENCIAS_FILIAIS
    FROM SBR_SALDO_ARMAZEM SA
    INNER JOIN
      (SELECT ID, CODIGO FROM SBR_ARMAZEM
      ) AR
    ON AR.ID = SA.ID_ARMAZEM
    INNER JOIN
      (SELECT SALDO_RESERVADO,
        STATUS,
        EMISSAO,
        ID_ARMAZEM,
        ID_PRODUTO,
        ID_FILIAL,
        ID_FILIAL_FATURAMENTO
      FROM SBR_RESERVA_FATURAMENTO
      ) RF
    ON RF.ID_PRODUTO              = SA.ID_PRODUTO
    AND RF.ID_ARMAZEM             = SA.ID_ARMAZEM
    WHERE RF.STATUS               = 'APROVADA'
    AND RF.SALDO_RESERVADO        > 0
    AND RF.EMISSAO               <= CURRENT_DATE
    AND AR.CODIGO                != '01'
    HAVING SUM(DISTINCT SA.SALDO) < SUM(RF.SALDO_RESERVADO)
    GROUP BY SA.ID_PRODUTO
    ) PNDFL ON PNDFL.ID_PRODUTO = P.ID
    /* SOLICITAÇÕES DE COMPRA */
  LEFT JOIN
    (SELECT SP.ID_PRODUTO,
      SUM(SP.QUANTIDADE_SOLICITACAO - (SP.QUANTIDADE_ATENDIDA + SP.QUANTIDADE_RESIDUO)) AS QUANTIDADE
    FROM sbr_solicitacao_compra_produto sp
    INNER JOIN
      (SELECT ID, STATUS, TIPO FROM SBR_SOLICITACAO_COMPRA
      ) SC
    ON SC.ID                      = SP.ID_SOLICITACAO
    WHERE SC.STATUS               = 'SOLICITACAO_EM_ABERTO'
    AND SC.TIPO                                            IN ('PONTO_PEDIDO','SOLICITACAO_MANUAL')
    AND SP.QUANTIDADE_SOLICITACAO > (SP.QUANTIDADE_ATENDIDA + SP.QUANTIDADE_RESIDUO)
    GROUP BY SP.ID_PRODUTO
    ) SP ON SP.ID_PRODUTO = P.ID
    /* PEDIDOS DE COMPRA */
  LEFT JOIN
    (SELECT PP.ID_PRODUTO,
      SUM(PP.QUANTIDADE - PP.QUANTIDADE_ATENDIDA) AS QUANTIDADE
    FROM SBR_PEDIDO_COMPRA_PRODUTO PP
    INNER JOIN
      (SELECT ID, STATUS, ID_FILIAL FROM SBR_PEDIDO_COMPRA
      ) PC
    ON PC.ID                 = PP.ID_PEDIDO
    WHERE PC.STATUS          = 'PEDIDO_EM_ABERTO'
    AND PP.ELIMINADO_RESIDUO = 0
    AND PP.QUANTIDADE        > PP.QUANTIDADE_ATENDIDA
    GROUP BY PP.ID_PRODUTO
    ) PP ON PP.ID_PRODUTO = P.ID
    /* PRE NOTAS DE ENTRADA */
  LEFT JOIN
    (SELECT NI.ID_PRODUTO,
      SUM(NI.QUANTIDADE) AS QUANTIDADE
    FROM SBR_NOTAFISCAL_ITEM NI
    INNER JOIN
      (SELECT ID,
        ID_FILIAL,
        ID_EMITENTE
      FROM SBR_PRE_NOTAFISCAL
      WHERE PRE_NF        = 1
      AND STATUS_PRE_NOTA = '0'
      AND TIPO_ES         = '0'
      AND TIPO_NF         = 'N'
      ) PN
    ON PN.ID = NI.ID_PRE_NOTAFISCAL
    INNER JOIN
      (SELECT ID_PESSOA,
        CNPJ
      FROM SBR_PESSOA_JURIDICA
      WHERE CNPJ NOT LIKE '01447737%'
      AND CNPJ NOT LIKE '01417367%'
      ) PJ
    ON PJ.ID_PESSOA         = PN.ID_EMITENTE
    WHERE NI.ID_NOTAFISCAL IS NULL
    GROUP BY NI.ID_PRODUTO
    ) PN ON PN.ID_PRODUTO = P.ID
    /* PEDIDOS DE TRANSFERENCIA  */
  LEFT JOIN
    (SELECT PI.ID_PRODUTO,
      SUM(PI.QUANTIDADE) AS QUANTIDADE
    FROM SBR_PED_VENDA_ITEM PI
    INNER JOIN
      (SELECT ID,
        ID_STATUS
      FROM SBR_PED_VENDA
      WHERE ID_STATUS   IN (17,21,24)
      AND ID_TIPO_PEDIDO = 6
      ) PV
    ON PV.ID = PI.ID_PEDIDO
    WHERE NOT EXISTS
      (SELECT 'x'
      FROM SBR_NOTAFISCAL_ITEM NI
      WHERE NI.ID_PED_VENDA_ITEM = PI.ID
      AND PI.ELIMINADO_RESIDUO   = 0
      AND PI.QUANTIDADE          > PI.QUANTIDADE_FATURADA
      )
    GROUP BY PI.ID_PRODUTO
    ) PT ON PT.ID_PRODUTO = P.ID
    /* NOTAS EM TRANSITO */
  LEFT JOIN
    (SELECT NI.ID_PRODUTO,
      SUM(NI.QUANTIDADE) AS QUANTIDADE
    FROM SBR_NOTAFISCAL_ITEM NI
    INNER JOIN
      (SELECT NF.ID,
        NF.ID_DESTINATARIO,
        NF.ID_EMITENTE,
        NF.SERIE,
        NF.NFNUMERO
      FROM SBR_NOTAFISCAL NF 
     INNER JOIN SBR_NOTAFISCAL_ITEM NFI ON NFI.ID_NOTAFISCAL = NF.ID AND NFI.ID_PED_VENDA_ITEM IS NOT NULL
      WHERE NF.NOTA_PROPRIA = 1
      AND NF.TIPO_NF        = 'N'
      AND NF.STATUS_NFE     = 'AU'
      AND NF.TIPO_ES        = '1'
      AND NF.SITUACAO       = '00'
      AND NF.ID_CFOP       IN ('6150','6151','6152','6153','6155','6156','5150','5151','5152','5153','5155','5156')
      ) NF
    ON NF.ID = NI.ID_NOTAFISCAL
    WHERE ( NOT EXISTS
      (SELECT 'x'
      FROM SBR_PRE_NOTAFISCAL PF
      WHERE PF.TIPO_ES       = '0'
      AND PF.NFNUMERO        = NF.NFNUMERO
      AND PF.SERIE           = NF.SERIE
      AND PF.ID_EMITENTE     = NF.ID_EMITENTE
      AND PF.ID_DESTINATARIO = NF.ID_DESTINATARIO
      )
    AND NOT EXISTS
      (SELECT 'x'
      FROM SBR_NOTAFISCAL NFX
      WHERE NFX.TIPO_ES       = '0'
      AND NFX.NFNUMERO        = NF.NFNUMERO
      AND NFX.SERIE           = NF.SERIE
      AND NFX.ID_EMITENTE     = NF.ID_EMITENTE
      AND NFX.ID_DESTINATARIO = NF.ID_DESTINATARIO
      ) )
    GROUP BY NI.ID_PRODUTO
    ) NT ON NT.ID_PRODUTO = P.ID
  WHERE IP.STATUS        != 'ATE_FIM_ESTOQUE'
  AND IP.BLOQUEADO        = 0
  AND PB.SUBSTITUIDO      = 0
  AND PB.STATUS_GERAL    != 'CADASTRO'
  AND PB.TIPO_PRODUTO    IN ('PA','PI','ME','IP','MP','MS','MI')
 "
"

 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_BI_ESTOQUE_ARK_PA_OLD" ("B1_COD", "SALDO", "LE", "ES", "OPRODUCAO", "PEDVEND", "ARM14") AS 
  SELECT B1_COD,
    COALESCE(SB2.B2_QATU, 0) SALDO,
    COALESCE(LOTE_ECONOMICO, 0) LE,
    COALESCE(PONTO_PEDIDO, 0) ES,
    COALESCE(SUM(tt_op), 0) OPRODUCAO,
    COALESCE(SUM(SC9CLI.PEDVEN), 0) PEDVEND,
    COALESCE(SUM(SB214.B2_QATU), 0) ARM14
  FROM SB1040 SB1
  LEFT JOIN
    (SELECT CODIGO,
      IP.LOTE_ECONOMICO LOTE_ECONOMICO,
      IP.PONTO_PEDIDO PONTO_PEDIDO
    FROM OCN_REF_PRODUTO P
    INNER JOIN OCN_REF_PRODUTO_FILIAL PF
    ON P.ID          = PF.ID_PRODUTO
    AND PF.ID_FILIAL = 1
    INNER JOIN OCN_REF_INFO_PRODUTO IP
    ON PF.ID_INFO_PRODUTO      = IP.ID
    ) INFO ON TRIM(SB1.B1_COD) = TRIM(INFO.CODIGO)
  LEFT JOIN
    (SELECT *
    FROM SB2040
    WHERE B2_FILIAL = '01'
    AND D_E_L_E_T_ <> '*'
    AND B2_LOCAL    = '01'
    ) SB2
  ON SB1.B1_COD = SB2.B2_COD
  LEFT JOIN
    (SELECT *
    FROM SB2040
    WHERE B2_FILIAL = '01'
    AND D_E_L_E_T_ <> '*'
    AND B2_LOCAL    = '14'
    ) SB214
  ON SB1.B1_COD = SB214.B2_COD
  LEFT JOIN
    (SELECT C9_PRODUTO,
      SUM(C9_QTDLIB) PEDVEN
    FROM SC9040
    WHERE C9_FILIAL IN ('01', '02', '03', '04', '05', '06', '08', '09')
    AND C9_NFISCAL   = ' '
    AND D_E_L_E_T_  <> '*'
    AND C9_BLEST     = '02'
    AND C9_CLIENTE  <> '000001'
    GROUP BY C9_PRODUTO
    ) SC9CLI
  ON SB1.B1_COD = SC9CLI.C9_PRODUTO
  LEFT JOIN
    (SELECT c2_produto,
      SUM(c2_quant-c2_quje) tt_op
    FROM sc2040
    WHERE c2_filial        = '01'
    AND c2_quant - c2_quje > 0 --Desconsiderado apontamentos com ganho de produção
    AND d_e_l_e_t_         = ' '
    GROUP BY c2_produto
    )
  ON c2_produto       = b1_cod
  WHERE SB1.B1_FILIAL = '01'
  AND SB1.D_E_L_E_T_ <> '*'
  AND SB1.B1_TIPO    IN ('PA', 'PI')
  AND SB1.B1_MSBLQL   = '2'
  GROUP BY B1_COD,
    SB2.B2_QATU,
    SB2.B2_RESERVA,
    LOTE_ECONOMICO,
    PONTO_PEDIDO
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."SBR_BI_ESTOQUE_ARK_PA" ("B1_COD", "SALDO", "LE", "ES", "OPRODUCAO", "PEDVEND", "ARM14") AS 
  SELECT B1_COD,
    COALESCE(SALDO_01.SALDO, 0) SALDO,
    COALESCE(LOTE_ECONOMICO, 0) LE,
    COALESCE(PONTO_PEDIDO, 0) ES,
    COALESCE(SUM(tt_op), 0) OPRODUCAO,
    COALESCE(SUM(SC9CLI.PEDVEN), 0) PEDVEND,
    COALESCE(SUM(SALDO_14.SALDO), 0) ARM14
  FROM SB1040 SB1
  LEFT JOIN (SELECT CODIGO, IP.LOTE_ECONOMICO LOTE_ECONOMICO, IP.PONTO_PEDIDO PONTO_PEDIDO
               FROM OCN_REF_PRODUTO P
             INNER JOIN OCN_REF_PRODUTO_FILIAL PF ON P.ID          = PF.ID_PRODUTO AND PF.ID_FILIAL = 1
             INNER JOIN OCN_REF_INFO_PRODUTO IP ON PF.ID_INFO_PRODUTO      = IP.ID
    ) INFO ON TRIM(SB1.B1_COD) = TRIM(INFO.CODIGO)
    
  LEFT JOIN (SELECT CODIGO, SUM(SALDO) SALDO
               FROM OCN_REF_PRODUTO P
             INNER JOIN SBR_SALDO_ARMAZEM ARM ON ARM.ID_PRODUTO = P.ID AND ARM.ID_ARMAZEM = 185 
             GROUP BY CODIGO) SALDO_14 ON TRIM(SB1.B1_COD) = TRIM(SALDO_14.CODIGO)
    
  LEFT JOIN
    (SELECT *
    FROM SB2040
    WHERE B2_FILIAL = '01'
    AND D_E_L_E_T_ <> '*'
    AND B2_LOCAL    = '01'
    ) SB2
  ON SB1.B1_COD = SB2.B2_COD
  
  LEFT JOIN (SELECT CODIGO, SUM(SALDO) SALDO
               FROM OCN_REF_PRODUTO P
             INNER JOIN SBR_SALDO_ARMAZEM ARM ON ARM.ID_PRODUTO = P.ID AND ARM.ID_ARMAZEM = 174 
             GROUP BY CODIGO) SALDO_01 ON TRIM(SB1.B1_COD) = TRIM(SALDO_01.CODIGO)
  
  LEFT JOIN
    (SELECT C9_PRODUTO,
      SUM(C9_QTDLIB) PEDVEN
    FROM SC9040
    WHERE C9_FILIAL IN ('01', '02', '03', '04', '05', '06', '08', '09')
    AND C9_NFISCAL   = ' '
    AND D_E_L_E_T_  <> '*'
    AND C9_BLEST     = '02'
    AND C9_CLIENTE  <> '000001'
    GROUP BY C9_PRODUTO
    ) SC9CLI
  ON SB1.B1_COD = SC9CLI.C9_PRODUTO
  LEFT JOIN
    (SELECT c2_produto,
      SUM(c2_quant-c2_quje) tt_op
    FROM sc2040
    WHERE c2_filial        = '01'
    AND c2_quant - c2_quje > 0 --Desconsiderado apontamentos com ganho de produção
    AND d_e_l_e_t_         = ' '
    GROUP BY c2_produto
    )
  ON c2_produto       = b1_cod
  WHERE SB1.B1_FILIAL = '01'
  AND SB1.D_E_L_E_T_ <> '*'
  AND SB1.B1_TIPO    IN ('PA', 'PI')
  AND SB1.B1_MSBLQL   = '2'
  GROUP BY B1_COD,
    SALDO_01.SALDO,
    SALDO_14.SALDO,
    LOTE_ECONOMICO,
    PONTO_PEDIDO
;

______________________________



"
 
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_TIPO_PRODUTO" ("CODIGO", "DESCRICAO") AS 
  SELECT DISTINCT TRIM(X5_CHAVE),
    TRIM(X5_DESCRI)
  FROM SX5010
  WHERE X5_TABELA = '02'
  AND X5_FILIAL   = '01'
  AND D_E_L_E_T_ <> '*'
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_TES" ("ID", "CODIGO", "TIPO", "ESTOQUE", "DUPLICATA") AS 
  SELECT 
  r_e_c_n_o_ as id,
  trim(f4_codigo) AS codigo,
  trim(f4_tipo)        AS tipo,
  trim(f4_estoque)     AS estoque,
  trim(f4_duplic)      AS duplicata
FROM sf4010
WHERE d_e_l_e_t_ <> '*'
 "
"

 "
"
 
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_SALDO_INICIAL" ("ID", "FILIAL", "CODIGO_PRODUTO", "ARMAZEM", "CUSTO_STANDARD", "DATA_SALDO", "QUANTIDADE_INICIAL", "VALOR_INICIAL", "ID_EMPRESA") AS 
  SELECT R_E_C_N_O_ AS ID,
    TRIM(B9_FILIAL) AS FILIAL,
    TRIM(B9_COD)    AS CODIGO_PRODUTO,
    TRIM(B9_LOCAL)  AS ARMAZEM,
    B9_CUSTD  AS CUSTO_STANDARD,
    B9_DATA         AS DATA_SALDO,
    TRIM(B9_QINI)   AS QUANTIDADE_INICIAL,
    B9_VINI1        AS VALOR_INICIAL,
    1               AS ID_EMPRESA
  FROM SB9010
  WHERE D_E_L_E_T_ = ' '
  AND b9_data     <> ' '
  UNION ALL
  SELECT (R_E_C_N_O_ + 10000000) AS ID,
    TRIM(B9_FILIAL)              AS FILIAL,
    TRIM(B9_COD)                 AS CODIGO_PRODUTO,
    TRIM(B9_LOCAL)               AS ARMAZEM,
    B9_CUSTD               AS CUSTO_STANDARD,
    B9_DATA                      AS DATA_SALDO,
    TRIM(B9_QINI)                AS QUANTIDADE_INICIAL,
    B9_VINI1                     AS VALOR_INICIAL,
    2                            AS ID_EMPRESA
  FROM SB9040
  WHERE D_E_L_E_T_ = ' '
  AND b9_data     <> ' '
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_PEDIDO_VENDA_ITEM" ("ID", "PRODUTO", "PEDIDO", "ID_EMPRESA") AS 
  SELECT 
   ROWNUM AS ID,
    "PRODUTO",
    "PEDIDO",
    "ID_EMPRESA"
  FROM (
    (SELECT TRIM(C6.C6_PRODUTO) AS PRODUTO,
      TRIM(C6.C6_NUM)           AS PEDIDO,
      1                         AS ID_EMPRESA
    FROM SC6010 C6
    WHERE C6.D_E_L_E_T_ = ' '
    )
  UNION ALL
    (SELECT C6.C6_PRODUTO AS PRODUTO,
      C6.C6_NUM           AS PEDIDO,
      4                   AS ID_EMPRESA
    FROM SC6040 C6
    WHERE C6.D_E_L_E_T_ = ' '
    )) ITEM_PEDIDO
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_PEDIDO_VENDA_FILIAL" ("PROSPEC", "CLIENTE", "LOJA", "CLIENTE_NOME", "GRUPO_TRIBUTARIO", "CODIGO_VENDEDOR", "GRUPO_VENDEDOR", "FILFAT", "PEDIDO", "DATA_LIB_CREDITO", "TIPO_FRETE", "TRANSPORTADORA", "CODIGO_CIDADE", "TIPO_ENVIO", "ID_EMPRESA") AS 
  SELECT 'F'   AS PROSPEC,
  A1_COD     AS CLIENTE,
  A1_LOJA    AS LOJA,
  A1_NOME    AS CLIENTE_NOME,
  A1_GRPTRIB AS GRUPO_TRIBUTARIO,
  A3_COD     AS CODIGO_VENDEDOR,
  A3_GRUPO   AS GRUPO_VENDEDOR,
  C5_FILIAL  AS FILFAT,
  C5_NUM     AS PEDIDO,
  C5_EMISSAO AS DATA_LIB_CREDITO,
  C5_TPFRETE AS TIPO_FRETE,
  C5_TRANSP  AS TRANSPORTADORA,
  A1_CODCID  AS CODIGO_CIDADE,
  A4_TIPENV  AS TIPO_ENVIO,
  4          AS ID_EMPRESA
FROM SC5010
INNER JOIN
  ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4010 WHERE D_E_L_E_T_ = ' '
  ) SA4
ON A4_FILIAL = ' '
AND A4_COD   = C5_TRANSP
INNER JOIN
  (SELECT A1_FILIAL,
    A1_COD,
    A1_LOJA,
    Trim(A1_NOME) AS A1_NOME,
    A1_CGC,
    A1_CODCID,
    A1_GRPTRIB
  FROM SA1010
  WHERE EXISTS
    (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
    )
  AND D_E_L_E_T_ = ' '
  ) SA1
ON A1_FILIAL = ' '
AND A1_COD   = C5_CLIENT
AND A1_LOJA  = C5_LOJACLI
INNER JOIN
  (SELECT A3_FILIAL,
    A3_COD,
    A3_NREDUZ,
    A3_GRUPO
  FROM SA3010
  WHERE D_E_L_E_T_ = ' '
  ) SA3
ON A3_FILIAL     = ' '
AND A3_COD       = C5_VEND1
WHERE C5_FILIAL                              IN ('01','11')
AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
AND C5_TIPO      = 'N'
AND C5_NOTA      = ' '
AND C5_SERIE     = ' '
AND C5_BLQ      <> 'R'
AND D_E_L_E_T_   = ' '
UNION ALL
SELECT 'F'   AS PROSPEC,
  A1_COD     AS CLIENTE,
  A1_LOJA    AS LOJA,
  A1_NOME    AS CLIENTE_NOME,
  A1_GRPTRIB AS GRUPO_TRIBUTARIO,
  A3_COD     AS CODIGO_VENDEDOR,
  A3_GRUPO   AS GRUPO_VENDEDOR,
  C5_FILIAL  AS FILFAT,
  C5_NUM     AS PEDIDO,
  C5_EMISSAO AS DATA_LIB_CREDITO,
  C5_TPFRETE AS TIPO_FRETE,
  C5_TRANSP  AS TRANSPORTADORA,
  A1_CODCID  AS CODIGO_CIDADE,
  A4_TIPENV  AS TIPO_ENVIO,
  4          AS ID_EMPRESA
FROM SC5040
INNER JOIN
  ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4040 WHERE D_E_L_E_T_ = ' '
  ) SA4
ON A4_FILIAL = ' '
AND A4_COD   = C5_TRANSP
INNER JOIN
  (SELECT A1_FILIAL,
    A1_COD,
    A1_LOJA,
    Trim(A1_NOME) AS A1_NOME,
    A1_CGC,
    A1_CODCID,
    A1_GRPTRIB
  FROM SA1040
  WHERE EXISTS
    (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
    )
  AND D_E_L_E_T_ = ' '
  ) SA1
ON A1_FILIAL = ' '
AND A1_COD   = C5_CLIENT
AND A1_LOJA  = C5_LOJACLI
INNER JOIN
  (SELECT A3_FILIAL,
    A3_COD,
    A3_NREDUZ,
    A3_GRUPO
  FROM SA3040
  WHERE D_E_L_E_T_ = ' '
  ) SA3
ON A3_FILIAL     = ' '
AND A3_COD       = C5_VEND1
WHERE C5_FILIAL                              IN ('01','11')
AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
AND C5_TIPO      = 'N'
AND C5_NOTA      = ' '
AND C5_SERIE     = ' '
AND C5_BLQ      <> 'R'
AND D_E_L_E_T_   = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_PEDIDO_VENDA_CLIENTE" ("PROSPEC", "CLIENTE", "LOJA", "CLIENTE_NOME", "GRUPO_TRIBUTARIO", "CODIGO_VENDEDOR", "GRUPO_VENDEDOR", "FILFAT", "PEDIDO", "DATA_LIB_CREDITO", "TIPO_FRETE", "TRANSPORTADORA", "CODIGO_CIDADE", "TIPO_ENVIO", "ID_EMPRESA") AS 
  SELECT 'F'   AS PROSPEC,
  A1_COD     AS CLIENTE,
  A1_LOJA    AS LOJA,
  A1_NOME    AS CLIENTE_NOME,
  A1_GRPTRIB AS GRUPO_TRIBUTARIO,
  A3_COD     AS CODIGO_VENDEDOR,
  A3_GRUPO   AS GRUPO_VENDEDOR,
  C5_FILIAL  AS FILFAT,
  C5_NUM     AS PEDIDO,
  C5_EMISSAO AS DATA_LIB_CREDITO,
  C5_TPFRETE AS TIPO_FRETE,
  C5_TRANSP  AS TRANSPORTADORA,
  A1_CODCID  AS CODIGO_CIDADE,
  A4_TIPENV  AS TIPO_ENVIO,
  4          AS ID_EMPRESA
FROM SC5010
INNER JOIN
  ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4010 WHERE D_E_L_E_T_ = ' '
  ) SA4
ON A4_FILIAL = ' '
AND A4_COD   = C5_TRANSP
INNER JOIN
  (SELECT A1_FILIAL,
    A1_COD,
    A1_LOJA,
    Trim(A1_NOME) AS A1_NOME,
    A1_CGC,
    A1_CODCID,
    A1_GRPTRIB
  FROM SA1010
  WHERE NOT EXISTS
    (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
    )
  AND D_E_L_E_T_ = ' '
  ) SA1
ON A1_FILIAL = ' '
AND A1_COD   = C5_CLIENT
AND A1_LOJA  = C5_LOJACLI
INNER JOIN
  (SELECT A3_FILIAL,
    A3_COD,
    A3_NREDUZ,
    A3_GRUPO
  FROM SA3010
  WHERE D_E_L_E_T_ = ' '
  ) SA3
ON A3_FILIAL     = ' '
AND A3_COD       = C5_VEND1
WHERE C5_FILIAL                              IN ('01','11')
AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
AND C5_TIPO      = 'N'
AND C5_NOTA      = ' '
AND C5_SERIE     = ' '
AND C5_BLQ      <> 'R'
AND D_E_L_E_T_   = ' '
UNION ALL
SELECT 'F'   AS PROSPEC,
  A1_COD     AS CLIENTE,
  A1_LOJA    AS LOJA,
  A1_NOME    AS CLIENTE_NOME,
  A1_GRPTRIB AS GRUPO_TRIBUTARIO,
  A3_COD     AS CODIGO_VENDEDOR,
  A3_GRUPO   AS GRUPO_VENDEDOR,
  C5_FILIAL  AS FILFAT,
  C5_NUM     AS PEDIDO,
  C5_EMISSAO AS DATA_LIB_CREDITO,
  C5_TPFRETE AS TIPO_FRETE,
  C5_TRANSP  AS TRANSPORTADORA,
  A1_CODCID  AS CODIGO_CIDADE,
  A4_TIPENV  AS TIPO_ENVIO,
  4          AS ID_EMPRESA
FROM SC5040
INNER JOIN
  ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4040 WHERE D_E_L_E_T_ = ' '
  ) SA4
ON A4_FILIAL = ' '
AND A4_COD   = C5_TRANSP
INNER JOIN
  (SELECT A1_FILIAL,
    A1_COD,
    A1_LOJA,
    Trim(A1_NOME) AS A1_NOME,
    A1_CGC,
    A1_CODCID,
    A1_GRPTRIB
  FROM SA1040
  WHERE NOT EXISTS
    (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
    )
  AND D_E_L_E_T_ = ' '
  ) SA1
ON A1_FILIAL = ' '
AND A1_COD   = C5_CLIENT
AND A1_LOJA  = C5_LOJACLI
INNER JOIN
  (SELECT A3_FILIAL,
    A3_COD,
    A3_NREDUZ,
    A3_GRUPO
  FROM SA3040
  WHERE D_E_L_E_T_ = ' '
  ) SA3
ON A3_FILIAL     = ' '
AND A3_COD       = C5_VEND1
WHERE C5_FILIAL                              IN ('01','11')
AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
AND C5_TIPO      = 'N'
AND C5_NOTA      = ' '
AND C5_SERIE     = ' '
AND C5_BLQ      <> 'R'
AND D_E_L_E_T_   = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_PEDIDO_VENDA_BLOQUEIO" ("FILIAL", "PEDIDO", "DATA_EMISSAO", "CLIENTE", "LOJA", "ID_EMPRESA", "APTO_FATURAR") AS 
  SELECT C5_FILIAL AS FILIAL,
    C5_NUM         AS PEDIDO,
    C5_EMISSAO     AS DATA_EMISSAO,
    C5_CLIENTE     AS CLIENTE,
    C5_LOJACLI     AS LOJA,
    1              AS id_empresa,
    CASE
      WHEN ( NVL(QTD_SC9_LIB,0) = 0 )
      THEN 'Pedido Estornado, Se Necessario, liberar'
      WHEN ( (ENT_SC6                     +EMP_SC6) > NVL(QTD_SC9,0)
      OR QTD_SC6                > ENT_SC6 + NVL(QTD_SC9_LIB,0) )
      THEN 'Sim, Parcial'
      WHEN ( (ENT_SC6+EMP_SC6) = NVL(QTD_SC9,0)
      AND QTD_SC6              = NVL(QTD_SC9,0) )
      THEN 'Nao, Bloqueio de Estoque'
        --'Sim, Total'
      WHEN ( (ENT_SC6+EMP_SC6) < NVL(QTD_SC9,0) )
      THEN 'SC9 com problemas, necessario estorno e liberacao para corrigir'
      WHEN ( NVL(QTD_BLQ_EST,0) > 0
      AND QTD_SC6               > ENT_SC6 + NVL(QTD_SC9,0) )
      THEN 'Nao, Parcial + Bloqueio de Estoque'
      WHEN ( NVL(QTD_BLQ_EST,0) > 0
      AND QTD_SC6               = ENT_SC6 + NVL(QTD_SC9,0) )
      THEN 'Sim, Total'
        --'Nao, Bloqueio de Estoque'
      ELSE 'Problema no pedido, Contate suporte MicroOCEAN'
    END AS APTO_FATURAR
  FROM SC5010 SC5
  LEFT JOIN
    (SELECT C6_FILIAL,
      C6_NUM,
      C6_CLI,
      C6_LOJA,
      MAX(C6_ENTREG) C6_ENTREG,
      SUM(C6_QTDENT) ENT_SC6,
      SUM(C6_QTDEMP) EMP_SC6,
      SUM(C6_QTDVEN) QTD_SC6,
      SUM(C6_VALOR) VALOR_PRODUTOS
    FROM SC6010 C61
    WHERE C6_BLQ  <> 'R'
    AND D_E_L_E_T_ = ' '
    GROUP BY C6_FILIAL,
      C6_NUM,
      C6_CLI,
      C6_LOJA
    ) SC6
  ON C6_FILIAL = C5_FILIAL
  AND C6_NUM   = C5_NUM
  AND C6_CLI   = C5_CLIENTE
  AND C6_LOJA  = C5_LOJACLI
  LEFT JOIN
    (SELECT C9_FILIAL,
      C9_PEDIDO,
      C9_CLIENTE,
      C9_LOJA,
      SUM(C9_QTDLIB) QTD_SC9,
      SUM(
      CASE
        WHEN C9_NFISCAL = ' '
        THEN C9_QTDLIB
        ELSE 0
      END) QTD_SC9_LIB,
      SUM(
      CASE
        WHEN C9_BLCRED
          || C9_BLFIN NOT IN ('    ','10  ')
        THEN C9_QTDLIB
        ELSE 0
      END) QTD_BLQ_FIN,
      ROUND(SUM(
      CASE
        WHEN C9_BLCRED
          || C9_BLFIN NOT IN ('    ','10  ')
        THEN C9_QTDLIB     * C9_PRCVEN
        ELSE 0
      END),2) VALOR_BLQ_FIN,
      SUM(
      CASE
        WHEN C9_BLEST = '02'
        THEN C9_QTDLIB
        ELSE 0
      END) QTD_BLQ_EST,
      ROUND(SUM(
      CASE
        WHEN C9_BLEST = '02'
        THEN C9_QTDLIB * C9_PRCVEN
        ELSE 0
      END),2) VALOR_BLQ_EST,
      ROUND(SUM(
      CASE
        WHEN C9_NFISCAL = ' '
        THEN C9_QTDLIB * C9_PRCVEN
        ELSE 0
      END),2) VLR_FALTA_FATURAR
    FROM SC9010
    WHERE D_E_L_E_T_ = ' '
    GROUP BY C9_FILIAL,
      C9_PEDIDO,
      C9_CLIENTE,
      C9_LOJA
    ) SC9
  ON C9_FILIAL                               = C5_FILIAL
  AND C9_PEDIDO                              = C5_NUM
  AND C9_CLIENTE                             = C5_CLIENTE
  AND C9_LOJA                                = C5_LOJACLI
  WHERE QTD_BLQ_FIN                          = 0
  AND ( SC9.QTD_BLQ_EST                     IS NULL
  OR SC9.QTD_BLQ_EST                         > 0
  OR (ENT_SC6                      +EMP_SC6) > NVL(QTD_SC9,0)
  OR QTD_SC6                                 > ENT_SC6 + NVL(QTD_SC9_LIB,0)
  OR (ENT_SC6                      +EMP_SC6) < NVL(QTD_SC9,0)
  OR ( NVL(QTD_BLQ_EST,0)                    > 0
  AND QTD_SC6                                > ENT_SC6 + NVL(QTD_SC9,0) )
  OR ( NVL(QTD_BLQ_EST,0)                    > 0
  AND QTD_SC6                                = ENT_SC6 + NVL(QTD_SC9,0) ) )
  AND D_E_L_E_T_                             = ' '
  UNION ALL
  SELECT C5_FILIAL AS FILIAL,
    C5_NUM         AS PEDIDO,
    C5_EMISSAO     AS DATA_EMISSAO,
    C5_CLIENTE     AS CLIENTE,
    C5_LOJACLI     AS LOJA,
    2              AS id_empresa,
    CASE
      WHEN ( NVL(QTD_SC9_LIB,0) = 0 )
      THEN 'Pedido Estornado, Se Necessario, liberar'
      WHEN ( (ENT_SC6                     +EMP_SC6) > NVL(QTD_SC9,0)
      OR QTD_SC6                > ENT_SC6 + NVL(QTD_SC9_LIB,0) )
      THEN 'Sim, Parcial'
      WHEN ( (ENT_SC6+EMP_SC6) = NVL(QTD_SC9,0)
      AND QTD_SC6              = NVL(QTD_SC9,0) )
      THEN 'Nao, Bloqueio de Estoque'
        --'Sim, Total'
      WHEN ( (ENT_SC6+EMP_SC6) < NVL(QTD_SC9,0) )
      THEN 'SC9 com problemas, necessario estorno e liberacao para corrigir'
      WHEN ( NVL(QTD_BLQ_EST,0) > 0
      AND QTD_SC6               > ENT_SC6 + NVL(QTD_SC9,0) )
      THEN 'Nao, Parcial + Bloqueio de Estoque'
      WHEN ( NVL(QTD_BLQ_EST,0) > 0
      AND QTD_SC6               = ENT_SC6 + NVL(QTD_SC9,0) )
      THEN 'Sim, Total'
        --'Nao, Bloqueio de Estoque'
      ELSE 'Problema no pedido, Contate suporte MicroOCEAN'
    END AS APTO_FATURAR
  FROM SC5040 SC5
  LEFT JOIN
    (SELECT C6_FILIAL,
      C6_NUM,
      C6_CLI,
      C6_LOJA,
      MAX(C6_ENTREG) C6_ENTREG,
      SUM(C6_QTDENT) ENT_SC6,
      SUM(C6_QTDEMP) EMP_SC6,
      SUM(C6_QTDVEN) QTD_SC6,
      SUM(C6_VALOR) VALOR_PRODUTOS
    FROM SC6040 C61
    WHERE C6_BLQ  <> 'R'
    AND D_E_L_E_T_ = ' '
    GROUP BY C6_FILIAL,
      C6_NUM,
      C6_CLI,
      C6_LOJA
    ) SC6
  ON C6_FILIAL = C5_FILIAL
  AND C6_NUM   = C5_NUM
  AND C6_CLI   = C5_CLIENTE
  AND C6_LOJA  = C5_LOJACLI
  LEFT JOIN
    (SELECT C9_FILIAL,
      C9_PEDIDO,
      C9_CLIENTE,
      C9_LOJA,
      SUM(C9_QTDLIB) QTD_SC9,
      SUM(
      CASE
        WHEN C9_NFISCAL = ' '
        THEN C9_QTDLIB
        ELSE 0
      END) QTD_SC9_LIB,
      SUM(
      CASE
        WHEN C9_BLCRED
          || C9_BLFIN NOT IN ('    ','10  ')
        THEN C9_QTDLIB
        ELSE 0
      END) QTD_BLQ_FIN,
      ROUND(SUM(
      CASE
        WHEN C9_BLCRED
          || C9_BLFIN NOT IN ('    ','10  ')
        THEN C9_QTDLIB     * C9_PRCVEN
        ELSE 0
      END),2) VALOR_BLQ_FIN,
      SUM(
      CASE
        WHEN C9_BLEST = '02'
        THEN C9_QTDLIB
        ELSE 0
      END) QTD_BLQ_EST,
      ROUND(SUM(
      CASE
        WHEN C9_BLEST = '02'
        THEN C9_QTDLIB * C9_PRCVEN
        ELSE 0
      END),2) VALOR_BLQ_EST,
      ROUND(SUM(
      CASE
        WHEN C9_NFISCAL = ' '
        THEN C9_QTDLIB * C9_PRCVEN
        ELSE 0
      END),2) VLR_FALTA_FATURAR
    FROM SC9040
    WHERE D_E_L_E_T_ = ' '
    GROUP BY C9_FILIAL,
      C9_PEDIDO,
      C9_CLIENTE,
      C9_LOJA
    ) SC9
  ON C9_FILIAL                               = C5_FILIAL
  AND C9_PEDIDO                              = C5_NUM
  AND C9_CLIENTE                             = C5_CLIENTE
  AND C9_LOJA                                = C5_LOJACLI
  WHERE QTD_BLQ_FIN                          = 0
  AND ( SC9.QTD_BLQ_EST                     IS NULL
  OR SC9.QTD_BLQ_EST                         > 0
  OR (ENT_SC6                      +EMP_SC6) > NVL(QTD_SC9,0)
  OR QTD_SC6                                 > ENT_SC6 + NVL(QTD_SC9_LIB,0)
  OR (ENT_SC6                      +EMP_SC6) < NVL(QTD_SC9,0)
  OR ( NVL(QTD_BLQ_EST,0)                    > 0
  AND QTD_SC6                                > ENT_SC6 + NVL(QTD_SC9,0) )
  OR ( NVL(QTD_BLQ_EST,0)                    > 0
  AND QTD_SC6                                = ENT_SC6 + NVL(QTD_SC9,0) ) )
  AND D_E_L_E_T_                             = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_PEDIDO_VENDA" ("CLIENTE", "LOJA", "CLIENTE_NOME", "GRUPO_TRIBUTARIO", "CODIGO_VENDEDOR", "GRUPO_VENDEDOR", "FILIAL_FATURAMENTO", "PEDIDO", "DATA_LIBERACAO_CREDITO", "TIPO_FRETE", "TRANSPORTADORA", "CODIGO_CIDADE", "TIPO_ENVIO", "ID_EMPRESA", "TRANSFERENCIA") AS 
  (
  (SELECT TRIM(A1_COD) AS CLIENTE,
    TRIM(A1_LOJA)      AS LOJA,
    TRIM(A1_NOME)      AS CLIENTE_NOME,
    TRIM(A1_GRPTRIB)   AS GRUPO_TRIBUTARIO,
    TRIM(A3_COD)       AS CODIGO_VENDEDOR,
    TRIM(A3_GRUPO)     AS GRUPO_VENDEDOR,
    TRIM(C5_FILIAL)    AS FILIAL_FATURAMENTO,
    TRIM(C5_NUM)       AS PEDIDO,
    to_Date(C5_EMISSAO,'YYYYMMDD')  AS DATA_LIBERACAO_CREDITO,
    TRIM(C5_TPFRETE)   AS TIPO_FRETE,
    TRIM(C5_TRANSP)    AS TRANSPORTADORA,
    TRIM(A1_CODCID)    AS CODIGO_CIDADE,
    TRIM(A4_TIPENV)    AS TIPO_ENVIO,
    1                  AS ID_EMPRESA,
    0                  AS TRANSFERENCIA
  FROM SC5010
  INNER JOIN
    ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4010 WHERE D_E_L_E_T_ = ' '
    ) SA4
  ON A4_FILIAL = ' '
  AND A4_COD   = C5_TRANSP
  INNER JOIN
    (SELECT A1_FILIAL,
      A1_COD,
      A1_LOJA,
      Trim(A1_NOME) AS A1_NOME,
      A1_CGC,
      A1_CODCID,
      A1_GRPTRIB
    FROM SA1010
    WHERE NOT EXISTS
      (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
      )
    AND D_E_L_E_T_ = ' '
    ) SA1
  ON A1_FILIAL = ' '
  AND A1_COD   = C5_CLIENT
  AND A1_LOJA  = C5_LOJACLI
  INNER JOIN
    (SELECT A3_FILIAL,
      A3_COD,
      A3_NREDUZ,
      A3_GRUPO
    FROM SA3010
    WHERE D_E_L_E_T_ = ' '
    ) SA3
  ON A3_FILIAL     = ' '
  AND A3_COD       = C5_VEND1
  WHERE C5_FILIAL                              IN ('01','11')
  AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
  AND C5_TIPO      = 'N'
  AND C5_NOTA      = ' '
  AND C5_SERIE     = ' '
  AND C5_BLQ      <> 'R'
  AND D_E_L_E_T_   = ' '
  )
UNION ALL
  (SELECT TRIM(A1_COD) AS CLIENTE,
    TRIM(A1_LOJA)      AS LOJA,
    TRIM(A1_NOME)      AS CLIENTE_NOME,
    TRIM(A1_GRPTRIB)   AS GRUPO_TRIBUTARIO,
    TRIM(A3_COD)       AS CODIGO_VENDEDOR,
    TRIM(A3_GRUPO)     AS GRUPO_VENDEDOR,
    TRIM(C5_FILIAL)    AS FILIAL_FATURAMENTO,
    TRIM(C5_NUM)       AS PEDIDO,
    to_Date(C5_EMISSAO,'YYYYMMDD')  AS DATA_LIBERACAO_CREDITO,
    TRIM(C5_TPFRETE)   AS TIPO_FRETE,
    TRIM(C5_TRANSP)    AS TRANSPORTADORA,
    TRIM(A1_CODCID)    AS CODIGO_CIDADE,
    TRIM(A4_TIPENV)    AS TIPO_ENVIO,
    1                  AS ID_EMPRESA,
    1                  AS TRANSFERENCIA
  FROM SC5010
  INNER JOIN
    ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4010 WHERE D_E_L_E_T_ = ' '
    ) SA4
  ON A4_FILIAL = ' '
  AND A4_COD   = C5_TRANSP
  INNER JOIN
    (SELECT A1_FILIAL,
      A1_COD,
      A1_LOJA,
      Trim(A1_NOME) AS A1_NOME,
      A1_CGC,
      A1_CODCID,
      A1_GRPTRIB
    FROM SA1010
    WHERE EXISTS
      (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
      )
    AND D_E_L_E_T_ = ' '
    ) SA1
  ON A1_FILIAL = ' '
  AND A1_COD   = C5_CLIENT
  AND A1_LOJA  = C5_LOJACLI
  INNER JOIN
    (SELECT A3_FILIAL,
      A3_COD,
      A3_NREDUZ,
      A3_GRUPO
    FROM SA3010
    WHERE D_E_L_E_T_ = ' '
    ) SA3
  ON A3_FILIAL     = ' '
  AND A3_COD       = C5_VEND1
  WHERE C5_FILIAL                              IN ('01','11')
  AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
  AND C5_TIPO      = 'N'
  AND C5_NOTA      = ' '
  AND C5_SERIE     = ' '
  AND C5_BLQ      <> 'R'
  AND D_E_L_E_T_   = ' '
  ))
UNION ALL
  (
  (SELECT TRIM(A1_COD) AS CLIENTE,
    TRIM(A1_LOJA)      AS LOJA,
    TRIM(A1_NOME)      AS CLIENTE_NOME,
    TRIM(A1_GRPTRIB)   AS GRUPO_TRIBUTARIO,
    TRIM(A3_COD)       AS CODIGO_VENDEDOR,
    TRIM(A3_GRUPO)     AS GRUPO_VENDEDOR,
    TRIM(C5_FILIAL)    AS FILIAL_FATURAMENTO,
    TRIM(C5_NUM)       AS PEDIDO,
    to_Date(C5_EMISSAO,'YYYYMMDD')  AS DATA_LIBERACAO_CREDITO,
    TRIM(C5_TPFRETE)   AS TIPO_FRETE,
    TRIM(C5_TRANSP)    AS TRANSPORTADORA,
    TRIM(A1_CODCID)    AS CODIGO_CIDADE,
    TRIM(A4_TIPENV)    AS TIPO_ENVIO,
    2                  AS ID_EMPRESA,
    0                  AS TRANSFERENCIA
  FROM SC5040
  INNER JOIN
    ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4040 WHERE D_E_L_E_T_ = ' '
    ) SA4
  ON A4_FILIAL = ' '
  AND A4_COD   = C5_TRANSP
  INNER JOIN
    (SELECT A1_FILIAL,
      A1_COD,
      A1_LOJA,
      Trim(A1_NOME) AS A1_NOME,
      A1_CGC,
      A1_CODCID,
      A1_GRPTRIB
    FROM SA1040
    WHERE NOT EXISTS
      (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
      )
    AND D_E_L_E_T_ = ' '
    ) SA1
  ON A1_FILIAL = ' '
  AND A1_COD   = C5_CLIENT
  AND A1_LOJA  = C5_LOJACLI
  INNER JOIN
    (SELECT A3_FILIAL,
      A3_COD,
      A3_NREDUZ,
      A3_GRUPO
    FROM SA3040
    WHERE D_E_L_E_T_ = ' '
    ) SA3
  ON A3_FILIAL     = ' '
  AND A3_COD       = C5_VEND1
  WHERE C5_FILIAL                              IN ('01','11')
  AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
  AND C5_TIPO      = 'N'
  AND C5_NOTA      = ' '
  AND C5_SERIE     = ' '
  AND C5_BLQ      <> 'R'
  AND D_E_L_E_T_   = ' '
  )
UNION ALL
  (SELECT TRIM(A1_COD) AS CLIENTE,
    TRIM(A1_LOJA)      AS LOJA,
    TRIM(A1_NOME)      AS CLIENTE_NOME,
    TRIM(A1_GRPTRIB)   AS GRUPO_TRIBUTARIO,
    TRIM(A3_COD)       AS CODIGO_VENDEDOR,
    TRIM(A3_GRUPO)     AS GRUPO_VENDEDOR,
    TRIM(C5_FILIAL)    AS FILIAL_FATURAMENTO,
    TRIM(C5_NUM)       AS PEDIDO,
    to_Date(C5_EMISSAO,'YYYYMMDD')  AS DATA_LIBERACAO_CREDITO,
    TRIM(C5_TPFRETE)   AS TIPO_FRETE,
    TRIM(C5_TRANSP)    AS TRANSPORTADORA,
    TRIM(A1_CODCID)    AS CODIGO_CIDADE,
    TRIM(A4_TIPENV)    AS TIPO_ENVIO,
    2                  AS ID_EMPRESA,
    1                  AS TRANSFERENCIA
  FROM SC5040
  INNER JOIN
    ( SELECT A4_FILIAL, A4_COD, A4_TIPENV FROM SA4040 WHERE D_E_L_E_T_ = ' '
    ) SA4
  ON A4_FILIAL = ' '
  AND A4_COD   = C5_TRANSP
  INNER JOIN
    (SELECT A1_FILIAL,
      A1_COD,
      A1_LOJA,
      Trim(A1_NOME) AS A1_NOME,
      A1_CGC,
      A1_CODCID,
      A1_GRPTRIB
    FROM SA1040
    WHERE EXISTS
      (SELECT 'x' FROM SM0 WHERE M0_CGC = A1_CGC AND D_E_L_E_T_ = ' '
      )
    AND D_E_L_E_T_ = ' '
    ) SA1
  ON A1_FILIAL = ' '
  AND A1_COD   = C5_CLIENT
  AND A1_LOJA  = C5_LOJACLI
  INNER JOIN
    (SELECT A3_FILIAL,
      A3_COD,
      A3_NREDUZ,
      A3_GRUPO
    FROM SA3040
    WHERE D_E_L_E_T_ = ' '
    ) SA3
  ON A3_FILIAL     = ' '
  AND A3_COD       = C5_VEND1
  WHERE C5_FILIAL                              IN ('01','11')
  AND C5_EMISSAO  >= TO_CHAR(Add_Months(SYSDATE,-12),'YYYYMMDD')
  AND C5_TIPO      = 'N'
  AND C5_NOTA      = ' '
  AND C5_SERIE     = ' '
  AND C5_BLQ      <> 'R'
  AND D_E_L_E_T_   = ' '
  ))
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_ORIGEM" ("ID", "CODIGO", "DESCRICAO", "FILIAL") AS 
  SELECT R_E_C_N_O_ AS "ID",
    TRIM(X5_CHAVE)        AS CODIGO,
    TRIM(X5_DESCRI)       AS DESCRICAO,
    TRIM(X5_FILIAL )      AS FILIAL
  FROM SX5010
  WHERE X5_TABELA = 'S0'
  AND D_E_L_E_T_ <>'*' AND X5_FILIAL = '01'
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_NOTA_FISCAL_SAIDA_ITEM" ("ID", "NUMERO_NF", "SERIE", "CODIGO_CLIENTE", "LOJA", "NUMERO_PEDIDO", "CODIGO_PRODUTO", "UNIDADE_MEDIDA", "QUANTIDADE", "PRECO_VENDA", "TES", "CFOP", "EMISSAO", "ID_EMPRESA", "FILIAL") AS 
  SELECT R_E_C_N_O_  AS ID,
    TRIM(D2_DOC)     AS NUMERO_NF,
    TRIM(D2_SERIE)   AS SERIE,
    TRIM(D2_CLIENTE) AS CODIGO_CLIENTE,
    TRIM(D2_LOJA)    AS LOJA,
    TRIM(D2_PEDIDO)  AS NUMERO_PEDIDO,
    TRIM(D2_COD)     AS CODIGO_PRODUTO,
    TRIM(D2_UM)      AS UNIDADE_MEDIDA,
    D2_QUANT   AS QUANTIDADE,
    d2_prcven  AS PRECO_VENDA,
    TRIM(D2_TES)     AS TES,
    TRIM(D2_CF)      AS CFOP,
    TRIM(D2_EMISSAO) AS EMISSAO,
    1                AS ID_EMPRESA,
    TRIM(D2_FILIAL)  AS FILIAL
  FROM SD2010
  WHERE D_E_L_E_T_ = ' '
  UNION ALL
  SELECT (R_E_C_N_O_ + 4000000) AS ID,
    TRIM(D2_DOC)                AS NUMERO_NF,
    TRIM(D2_SERIE)              AS SERIE,
    TRIM(D2_CLIENTE)            AS CODIGO_CLIENTE,
    TRIM(D2_LOJA)               AS LOJA,
    TRIM(D2_PEDIDO)             AS NUMERO_PEDIDO,
    TRIM(D2_COD)                AS CODIGO_PRODUTO,
    TRIM(D2_UM)                 AS UNIDADE_MEDIDA,
    D2_QUANT              AS QUANTIDADE,
   d2_prcven            AS PRECO_VENDA,
    TRIM(D2_TES)                AS TES,
    TRIM(D2_CF)                 AS CFOP,
    TRIM(D2_EMISSAO)            AS EMISSAO,
    2                           AS ID_EMPRESA,
    TRIM(D2_FILIAL)             AS FILIAL
  FROM SD2040
  WHERE D_E_L_E_T_ = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_NOTA_FISCAL_SAIDA" ("ID", "NUMERO_NF", "SERIE", "CODIGO_CLIENTE", "LOJA", "DUPLICATA", "ESTADO", "FRETE", "EMISSAO", "ID_EMPRESA") AS 
  SELECT R_E_C_N_O_         AS ID,
    TRIM(F2_DOC)                AS NUMERO_NF,
    TRIM(F2_SERIE)                  AS SERIE,
    TRIM(F2_CLIENTE)               AS CODIGO_CLIENTE,
    TRIM(F2_LOJA)               AS LOJA,
    TRIM(F2_DUPL)               AS DUPLICATA,
    TRIM(F2_EST)               AS ESTADO,
    TRIM(F2_FRETE)               AS FRETE,
    to_Date(F2_EMISSAO,'YYYYMMDD') AS EMISSAO,
    1                              AS ID_EMPRESA
  FROM SF2010
      WHERE D_E_L_E_T_ = ' '
  UNION ALL
     SELECT (R_E_C_N_O_ + 4000000)        AS ID,
    TRIM(F2_DOC)                AS NUMERO_NF,
    TRIM(F2_SERIE)                  AS SERIE,
    TRIM(F2_CLIENTE)               AS CODIGO_CLIENTE,
    TRIM(F2_LOJA)               AS LOJA,
    TRIM(F2_DUPL)               AS DUPLICATA,
    TRIM(F2_EST)               AS ESTADO,
    TRIM(F2_FRETE)               AS FRETE,
    to_Date(F2_EMISSAO,'YYYYMMDD') AS EMISSAO,
    2                              AS ID_EMPRESA
  FROM SF2040
      WHERE D_E_L_E_T_ = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_NOTA_FISCAL_ENTRADA_ITEM" ("ID", "NUMERO_NF", "SERIE", "FORNECEDOR", "LOJA", "NUMERO_PEDIDO", "CODIGO_PRODUTO", "UNIDADE_MEDIDA", "QUANTIDADE", "TIPO", "TES", "CFOP", "EMISSAO", "ID_EMPRESA", "FILIAL") AS 
  SELECT R_E_C_N_O_  AS ID,
    TRIM(D1_DOC)     AS NUMERO_NF,
    TRIM(D1_SERIE)   AS SERIE,
    TRIM(D1_FORNECE) AS FORNECEDOR,
    TRIM(D1_LOJA)    AS LOJA,
    TRIM(D1_PEDIDO)  AS NUMERO_PEDIDO,
    TRIM(D1_COD)     AS CODIGO_PRODUTO,
    TRIM(D1_UM)      AS UNIDADE_MEDIDA,
    D1_QUANT         AS QUANTIDADE,
    TRIM(D1_TIPO)         AS TIPO,
    TRIM(D1_TES)     AS TES,
    TRIM(D1_CF)      AS CFOP,
    TRIM(D1_EMISSAO) AS EMISSAO,
    1                AS ID_EMPRESA,
    TRIM(D1_FILIAL)  AS FILIAL
  FROM SD1010
  WHERE D_E_L_E_T_ = ' '
  UNION ALL
  SELECT (R_E_C_N_O_ + 4000000) AS ID,
    TRIM(D1_DOC)                AS NUMERO_NF,
    TRIM(D1_SERIE)              AS SERIE,
    TRIM(D1_FORNECE)            AS FORNECEDOR,
    TRIM(D1_LOJA)               AS LOJA,
    TRIM(D1_PEDIDO)             AS NUMERO_PEDIDO,
    TRIM(D1_COD)                AS CODIGO_PRODUTO,
    TRIM(D1_UM)                 AS UNIDADE_MEDIDA,
    D1_QUANT                    AS QUANTIDADE,
    TRIM(D1_TIPO)         AS TIPO,
    TRIM(D1_TES)                AS TES,
    TRIM(D1_CF)                 AS CFOP,
    TRIM(D1_EMISSAO)            AS EMISSAO,
    2                           AS ID_EMPRESA,
    TRIM(D1_FILIAL)             AS FILIAL
  FROM SD1040
  WHERE D_E_L_E_T_ = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_NOTA_FISCAL_ENTRADA" ("ID", "NUMERO_NF", "SERIE", "FORNECEDOR", "LOJA", "DUPLICATA", "ESTADO", "FRETE", "TIPO", "EMISSAO", "ID_EMPRESA") AS 
  SELECT R_E_C_N_O_                AS ID,
    TRIM(F1_DOC)                   AS NUMERO_NF,
    TRIM(F1_SERIE)                 AS SERIE,
    TRIM(F1_FORNECE)               AS FORNECEDOR,
    TRIM(F1_LOJA)                  AS LOJA,
    TRIM(F1_DUPL)                  AS DUPLICATA,
    TRIM(F1_EST)                   AS ESTADO,
    TRIM(F1_FRETE)                 AS FRETE,
    TRIM(F1_TIPO)                 AS TIPO,
    to_Date(F1_EMISSAO,'YYYYMMDD') AS EMISSAO,
    1                              AS ID_EMPRESA
  FROM SF1010
  WHERE D_E_L_E_T_ = ' '
  UNION ALL
  SELECT (R_E_C_N_O_ + 4000000)    AS ID,
    TRIM(F1_DOC)                   AS NUMERO_NF,
    TRIM(F1_SERIE)                 AS SERIE,
    TRIM(F1_FORNECE)               AS FORNECEDOR,
    TRIM(F1_LOJA)                  AS LOJA,
    TRIM(F1_TIPO)                 AS TIPO,
    TRIM(F1_DUPL)                  AS DUPLICATA,
    TRIM(F1_EST)                   AS ESTADO,
    TRIM(F1_FRETE)                 AS FRETE,
    to_Date(F1_EMISSAO,'YYYYMMDD') AS EMISSAO,
    2                              AS ID_EMPRESA
  FROM SF1040
  WHERE D_E_L_E_T_ = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_NFE_XML" ("NNF", "SERIE", "NOME", "CNPJ", "DEMI", "ID_FORNECEDOR", "ID_EMPRESA") AS 
  SELECT NNF, SERIE, LOJA.NOME, LOJA.CNPJ, DEMI, ID_FORNECEDOR, '2' AS ID_EMPRESA
FROM OCN_NFE_IDE IDE
INNER JOIN ( SELECT ID, ID_NFE, ID_DESTINATARIO, ID_EMISSOR FROM OCN_NFE_INFO ) INFO ON INFO.ID = IDE.ID_INFONFE
INNER JOIN ( SELECT ID, CNPJ, XNOME FROM OCN_NFE_EMISSOR ) EMIS ON EMIS.ID = INFO.ID_EMISSOR
INNER JOIN ( SELECT NOME, CNPJ, ID_FORNECEDOR FROM OCN_LOJA_FORNECEDOR ) LOJA ON LOJA.CNPJ = EMIS.CNPJ
INNER JOIN ( SELECT ID, CNPJ FROM OCN_NFE_DESTINATARIO ) DEST ON DEST.ID = INFO.ID_DESTINATARIO
WHERE DEST.CNPJ = '01417367000178'
AND NOT EXISTS (SELECT 'x' FROM SF1040 WHERE F1_FILIAL = '01' AND TRIM(F1_DOC) = TRIM(NNF))
AND NOT EXISTS (SELECT 'x' FROM OCN_NFE_STATUS WHERE ID_NFE = INFO.ID_NFE)
UNION ALL
SELECT NNF, SERIE, LOJA.NOME, LOJA.CNPJ, DEMI, ID_FORNECEDOR, '1' AS ID_EMPRESA
FROM OCN_NFE_IDE IDE
INNER JOIN ( SELECT ID, ID_NFE, ID_DESTINATARIO, ID_EMISSOR FROM OCN_NFE_INFO ) INFO ON INFO.ID = IDE.ID_INFONFE
INNER JOIN ( SELECT ID, CNPJ, XNOME FROM OCN_NFE_EMISSOR ) EMIS ON EMIS.ID = INFO.ID_EMISSOR
INNER JOIN ( SELECT NOME, CNPJ, ID_FORNECEDOR FROM OCN_LOJA_FORNECEDOR ) LOJA ON LOJA.CNPJ = EMIS.CNPJ
INNER JOIN ( SELECT ID, CNPJ FROM OCN_NFE_DESTINATARIO ) DEST ON DEST.ID = INFO.ID_DESTINATARIO
WHERE DEST.CNPJ IN ('01447737000110','01447737001272')
AND NOT EXISTS (SELECT 'x' FROM SF1010 WHERE F1_FILIAL IN ('01','02','03','04','05','06','09','10','11') AND TRIM(F1_DOC) = TRIM(NNF))
AND NOT EXISTS (SELECT 'x' FROM OCN_NFE_STATUS WHERE ID_NFE = INFO.ID_NFE)
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_NATUREZA_RECEITA" ("ID", "CODIGO", "TABELA", "DESCRICAO", "ALIQ_PIS", "ALIQ_COF") AS 
  Select r_e_c_n_o_,
    Ccz_Cod,
    Ccz_Tabela,
    Ccz_Desc,
    Ccz_Alqpis,
    Ccz_Alqcof
  FROM Ccz010
  WHERE D_E_L_E_T_ = ' '
  ORDER BY Ccz_Tabela,
    Ccz_Cod
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_MIGRACAO_ARKTUS" ("ID", "ID_FILIAL", "ID_PRODUTO", "ID_INFO_FISCAL", "ID_INFO_PRODUTO", "ID_PRODUTO_BASE") AS 
  (SELECT  Y."ID",Y."ID_FILIAL",Y."ID_PRODUTO",Y."ID_INFO_FISCAL",Y."ID_INFO_PRODUTO",X.ID_PRODUTO_BASE
  FROM OCN_REF_PRODUTO_FILIAL@HOMOLOG Y,(SELECT ID,ID_PRODUTO_BASE
    FROM OCN_REF_PRODUTO@HOMOLOG
    WHERE ID_PRODUTO_BASE IN
      (SELECT ID
      FROM OCN_REF_PRODUTO_BASE@HOMOLOG
      WHERE ID_EMPRESA = 2
      AND ID NOT      IN
        (SELECT HOMO.ID
        FROM
          (SELECT * FROM OCN_REF_PRODUTO_BASE@HOMOLOG WHERE ID_EMPRESA = 2
          ) RAC,
          (SELECT * FROM OCN_REF_PRODUTO_BASE WHERE ID_EMPRESA = 2
          ) HOMO
        WHERE RAC.CODIGO = HOMO.CODIGO
        AND RAC.ID       = HOMO.ID
        )
      )) X
  WHERE Y.ID_PRODUTO = X.ID)
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_ITEM_CONTA" ("ID", "CODIGO", "CODIGO_REDUZIDO", "DESCRICAO") AS 
  SELECT R_E_C_N_O_ AS ID,
    TRIM(CTD_ITEM) AS CODIGO,
    TRIM(CTD_RES)       AS CODIGO_REDUZIDO,
    TRIM(CTD_DESC01)    AS DESCRICAO
  FROM CTD010
  WHERE D_E_L_E_T_ = ' '
 "
"

"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_GRUPO_TRIBUTARIO_" ("ID", "CODIGO", "FILIAL", "DESCRICAO") AS 
  SELECT R_E_C_N_O_ AS "ID",
    X5_CHAVE        AS CODIGO,
    X5_FILIAL       AS FILIAL,
    X5_DESCRI       AS DESCRICAO
  FROM SX5010
  WHERE X5_TABELA = '21'
  AND D_E_L_E_T_  <> '*'
  AND X5_FILIAL   = '01'
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_GRUPO_COMPRA" ("ID", "CODIGO", "NOME", "ITEM", "COD_USUARIO") AS 
  SELECT R_E_C_N_O_  AS ID,
    AJ_GRCOM         AS CODIGO,
    TRIM(AJ_US2NAME) AS NOME,
    AJ_ITEM          AS ITEM,
    AJ_USER          AS COD_USUARIO
  FROM SAJ010
  WHERE D_E_L_E_T_ <> '*'
  AND AJ_FILIAL     = '01'
 "
"
 
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_FORNECEDOR_VIEW" ("ID", "CODIGO", "LOJA", "FILIAL", "NOME", "CNPJ", "INSCRICAO", "DDD", "FONE") AS 
  SELECT R_E_C_N_O_ AS "ID",
    A2_COD          AS CODIGO,
    A2_LOJA         AS LOJA,
    A2_FILIAL       AS FILIAL,
    A2_NOME         AS NOME,
    A2_CGC          AS CNPJ,
    A2_INSCR        AS INSCRICAO,
    A2_DDD          AS DDD,
    A2_TEL          AS FONE
  FROM SA2040
  WHERE D_E_L_E_T_ <> '*'
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_ESTOQUE" ("ID", "FILIAL", "CODIGO_PRODUTO", "ARMAZEM", "QTD_ATUAL", "QTD_RESERVA", "QTD_ENDERECADA", "QTD_PED_VEND", "ID_EMPRESA") AS 
  SELECT R_E_C_N_O_ AS ID,
    TRIM(B2_FILIAL) AS FILIAL,
    TRIM(B2_COD)    AS CODIGO_PRODUTO,
    TRIM(B2_LOCAL)  AS ARMAZEM,
    B2_QATU         AS QTD_ATUAL,
    B2_RESERVA      AS QTD_RESERVA,
    B2_QACLASS      AS QTD_ENDERECADA,
    b2_qpedven      AS QTD_PED_VEND,
    1               AS ID_EMPRESA
  FROM SB2010
  WHERE D_E_L_E_T_ = ' '
  AND R_E_C_D_E_L_ = 0
  UNION ALL
  SELECT R_E_C_N_O_ AS ID,
    TRIM(B2_FILIAL) AS FILIAL,
    TRIM(B2_COD)    AS CODIGO_PRODUTO,
    TRIM(B2_LOCAL)  AS ARMAZEM,
    B2_QATU         AS QTD_ATUAL,
    B2_RESERVA      AS QTD_RESERVA,
    B2_QACLASS      AS QTD_ENDERECADA,
    b2_qpedven      AS QTD_PED_VEND,
    2               AS ID_EMPRESA
  FROM SB2040
  WHERE D_E_L_E_T_ = ' '
  AND R_E_C_D_E_L_ = 0
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_CONTA_CONTABIL" ("ID", "CODIGO", "CODIGO_REDUZIDO", "DESCRICAO") AS 
  SELECT R_E_C_N_O_  AS ID,
    TRIM(CT1_CONTA)  AS CODIGO,
    TRIM(CT1_RES)    AS CODIGO_REDUZIDO,
    TRIM(CT1_DESC01) AS DESCRICAO
  FROM CT1010
  WHERE D_E_L_E_T_ =' ' AND CT1_CLASSE = 2
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_CIDADE" ("ID", "NOME", "ESTADO", "CODIGO_MUNICIPIO") AS 
  SELECT R_E_C_N_O_ AS ID,
    Z3_NOME         AS NOME,
    Z3_ESTADO       AS ESTADO,
    Z3_COD_MUN      AS CODIGO_MUNICIPIO
  FROM CIDADE
  WHERE D_E_L_E_T_ = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_CENTRO_CUSTO" ("ID", "CODIGO", "CODIGO_REDUZIDO", "DESCRICAO") AS 
  SELECT 
    R_E_C_N_O_ AS ID,
    TRIM(CTT_CUSTO) AS CODIGO,
    TRIM(CTT_RES)        AS CODIGO_REDUZIDO,
    TRIM(CTT_DESC01)     AS DESCRICAO
  FROM CTT010
  WHERE D_E_L_E_T_ = ' '
 "
"
  CREATE OR REPLACE FORCE VIEW "OCEAN"."OCN_AGUARDANDO_NOTA_ENTRADA" ("ID", "FILIAL", "ID_EMPRESA", "PEDIDO", "PRODUTO", "QTD_PEDIDO", "QTD_ENTREGUE", "FORNECEDOR", "LOJA", "EMISSAO", "STATUS_PEDIDO") AS 
  SELECT R_E_C_N_O_ AS ID,
    C7_FILIAL FILIAL,
    1 AS ID_EMPRESA,
    C7_NUM PEDIDO,
    TRIM(C7_PRODUTO) PRODUTO,
    C7_QUANT QTD_PEDIDO,
    C7_QUJE QTD_ENTREGUE,
    C7_FORNECE FORNECEDOR,
    C7_LOJA LOJA,
    C7_EMISSAO EMISSAO,
    CASE
      WHEN C7_CONAPRO = 'L'
      AND C7_QUJE     = 0
      THEN 'Aguardando faturamento Fornecedor'
      WHEN C7_CONAPRO = 'L'
      AND C7_QUJE     > 0
      AND C7_QUJE     < C7_QUANT
      THEN 'Atendido Parcial'
    END STATUS_PEDIDO
  FROM SC7010
  WHERE EXISTS
    (SELECT 'x'
    FROM SM0
    WHERE M0_CODIGO    = '01'
    AND M0_CODFIL NOT IN ('07','08')
    AND M0_CODFIL      = C7_FILIAL
    AND D_E_L_E_T_     = ' '
    )
  AND C7_EMISSAO > '20120101'
  AND C7_RESIDUO = ' '
  AND C7_CONAPRO = 'L'
  AND C7_QUJE    < C7_QUANT
  AND D_E_L_E_T_ = ' '
  UNION ALL
  SELECT R_E_C_N_O_ AS ID,
    C7_FILIAL FILIAL,
    2 AS ID_EMPRESA,
    C7_NUM PEDIDO,
    TRIM(C7_PRODUTO) PRODUTO,
    C7_QUANT QTD_PEDIDO,
    C7_QUJE QTD_ENTREGUE,
    C7_FORNECE FORNECEDOR,
    C7_LOJA LOJA,
    C7_EMISSAO EMISSAO,
    CASE
      WHEN C7_CONAPRO = 'L'
      AND C7_QUJE     = 0
      THEN 'Aguardando faturamento Fornecedor'
      WHEN C7_CONAPRO = 'L'
      AND C7_QUJE     > 0
      AND C7_QUJE     < C7_QUANT
      THEN 'Atendido Parcial'
    END STATUS_PEDIDO
  FROM SC7040
  WHERE EXISTS
    (SELECT 'x'
    FROM SM0
    WHERE M0_CODIGO    = '04'
    AND M0_CODFIL NOT IN ('07','08')
    AND M0_CODFIL      = C7_FILIAL
    AND D_E_L_E_T_     = ' '
    )
  AND C7_EMISSAO > '20120401'
  AND C7_RESIDUO = ' '
  AND C7_CONAPRO = 'L'
  AND C7_QUJE    < C7_QUANT
  AND D_E_L_E_T_ = ' '
 "