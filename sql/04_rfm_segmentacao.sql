-- RFM completo com scoring por quintil

-- SEGMENTAÇÃO RFM
WITH base_cliente AS (
    SELECT
        v.id_cliente,
        c.pais_cliente,
        CAST(JULIANDAY('2020-01-01') - JULIANDAY(MAX(v.data_transacao)) AS INTEGER) AS recencia_dias,
        COUNT(DISTINCT v.id_transacao) AS frequencia,
        ROUND(SUM(v.quantidade * v.preco_unitario), 2) AS monetario
    FROM fato_vendas v
    JOIN dim_clientes c ON v.id_cliente = c.id_cliente
    WHERE v.flag_cancelado = 0 AND v.id_cliente IS NOT NULL
    GROUP BY v.id_cliente
),
scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recencia_dias DESC, id_cliente) AS r_score, 
        NTILE(5) OVER (ORDER BY frequencia ASC, id_cliente) AS f_score,
        NTILE(5) OVER (ORDER BY monetario ASC, id_cliente) AS m_score
    FROM base_cliente
),
segmentado AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Campeões'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Novos Promissores'
            WHEN r_score <= 2 AND f_score >= 4 THEN 'Em Risco (Alto Valor)'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Perdidos'
            ELSE 'Regulares'
        END AS segmento_rfm
    FROM scores
)
SELECT *,
    CASE segmento_rfm
        WHEN 'Campeões' THEN 1
        WHEN 'Regulares' THEN 2
        WHEN 'Novos Promissores' THEN 3
        WHEN 'Em Risco (Alto Valor)' THEN 4
        WHEN 'Perdidos' THEN 5
        ELSE 99
    END AS ordem_segmento
FROM segmentado;