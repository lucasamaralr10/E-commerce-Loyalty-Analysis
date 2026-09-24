-- =====================================================================
-- 11_curva_pareto_clientes.sql
-- Teste direto de concentração de receita (Princípio de Pareto):
-- ordena clientes APENAS pelo faturamento e mede quanto da receita os
-- top X% concentram. Diferente do resumo RFM (10_), aqui não há
-- circularidade com os critérios de recência/frequência.
-- Leitura: "os top 20% dos clientes geram N% da receita".
-- =====================================================================
WITH receita_cliente AS (
    SELECT id_cliente, SUM(quantidade * preco_unitario) AS monetario
    FROM fato_vendas
    WHERE flag_cancelado = 0
    GROUP BY id_cliente
),
ranqueado AS (
    SELECT
        id_cliente,
        monetario,
        ROW_NUMBER() OVER (ORDER BY monetario DESC, id_cliente) AS posicao,
        COUNT(*)       OVER ()                                  AS total_clientes,
        SUM(monetario) OVER (ORDER BY monetario DESC, id_cliente
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS receita_acumulada,
        SUM(monetario) OVER ()                                  AS receita_total
    FROM receita_cliente
),
faixas(pct_top_clientes) AS (
    VALUES (1), (5), (10), (20), (50), (80), (100)
)
SELECT
    f.pct_top_clientes,
    MAX(r.posicao)                                                AS qtd_clientes,
    ROUND(100.0 * MAX(r.receita_acumulada) / MAX(r.receita_total), 2) AS pct_receita_acumulada
FROM faixas f
JOIN ranqueado r
  ON r.posicao * 100 <= r.total_clientes * f.pct_top_clientes   -- sem CEIL(): funciona em qualquer versão do SQLite
GROUP BY f.pct_top_clientes
ORDER BY f.pct_top_clientes;
