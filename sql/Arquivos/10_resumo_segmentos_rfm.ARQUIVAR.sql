WITH base_cliente AS (
    SELECT
        v.id_cliente,
        CAST(JULIANDAY('2020-01-01') - JULIANDAY(MAX(v.data_transacao)) AS INTEGER) AS recencia_dias,
        COUNT(DISTINCT v.id_transacao) AS frequencia,
        ROUND(SUM(v.quantidade * v.preco_unitario), 2) AS monetario
    FROM fato_vendas v
    JOIN dim_produtos p ON v.id_produto = p.id_produto
    WHERE v.flag_cancelado = 0 AND v.id_cliente IS NOT NULL
    GROUP BY v.id_cliente
),
scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recencia_dias DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequencia ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetario ASC) AS m_score
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
SELECT
    segmento_rfm,
    COUNT(*) AS qtd_clientes,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM segmentado), 2) AS pct_clientes,
    ROUND(SUM(monetario), 2) AS faturamento_total_segmento,
    ROUND(SUM(monetario) * 100.0 / (SELECT SUM(monetario) FROM segmentado), 2) AS pct_faturamento
FROM segmentado
GROUP BY segmento_rfm
ORDER BY pct_faturamento DESC;
