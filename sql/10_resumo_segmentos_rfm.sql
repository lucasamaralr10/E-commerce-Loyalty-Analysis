-- =====================================================================
-- 10_resumo_segmentos_rfm.sql
-- Resumo agregado da segmentação RFM: clientes e faturamento por segmento.
-- Fonte do achado "Campeões = ~20,7% dos clientes e ~60,7% do faturamento".
--
-- IMPORTANTE: a lógica de scoring é IDÊNTICA à de 04_rfm_segmentacao.sql,
-- inclusive o desempate por id_cliente nos NTILE (correção do achado nº 3
-- da auditoria). A versão antiga arquivada (sem desempate) é a que gerava
-- o número 22%/63% e NÃO deve ser reaproveitada.
-- Denominador: faturamento de vendas não canceladas dos 4.718 clientes
-- com ao menos uma compra válida.
-- =====================================================================
WITH base_cliente AS (
    SELECT
        v.id_cliente,
        CAST(JULIANDAY('2020-01-01') - JULIANDAY(MAX(v.data_transacao)) AS INTEGER) AS recencia_dias,
        COUNT(DISTINCT v.id_transacao) AS frequencia,
        SUM(v.quantidade * v.preco_unitario) AS monetario
    FROM fato_vendas v
    WHERE v.flag_cancelado = 0
    GROUP BY v.id_cliente
),
scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recencia_dias DESC, id_cliente) AS r_score,
        NTILE(5) OVER (ORDER BY frequencia ASC,  id_cliente)   AS f_score,
        NTILE(5) OVER (ORDER BY monetario ASC,   id_cliente)   AS m_score
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
    COUNT(*)                                                    AS qtd_clientes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)          AS pct_clientes,
    ROUND(SUM(monetario), 2)                                    AS faturamento_segmento,
    ROUND(100.0 * SUM(monetario) / SUM(SUM(monetario)) OVER (), 2) AS pct_faturamento,
    ROUND(AVG(monetario), 2)                                    AS faturamento_medio_cliente
FROM segmentado
GROUP BY segmento_rfm
ORDER BY pct_faturamento DESC;
