-- =====================================================================
-- 13_consultas_metricas_finais.sql
-- Consultas de apoio a números citados no README que não tinham
-- arquivo próprio. Todas usam fato_vendas (+ dim_clientes na B).
-- =====================================================================

-- ---------------------------------------------------------------------
-- A) Cancelamentos vs. faturamento bruto
-- Faturamento bruto (vendas não canceladas), valor dos cancelamentos
-- (negativo), faturamento líquido e peso dos cancelamentos sobre o bruto.
-- Fonte de: "cancelamentos representam ~4,2% do faturamento bruto".
-- Resultado na auditoria: bruto £ 62.781.304,54; cancelamentos
-- -£ 2.646.715,27; líquido £ 60.134.589,27; 4,22% do bruto.
-- ---------------------------------------------------------------------
SELECT
    ROUND(SUM(CASE WHEN flag_cancelado = 0 THEN quantidade * preco_unitario END), 2) AS faturamento_bruto,
    ROUND(SUM(CASE WHEN flag_cancelado = 1 THEN quantidade * preco_unitario END), 2) AS valor_cancelamentos,
    ROUND(SUM(quantidade * preco_unitario), 2)                                       AS faturamento_liquido,
    ROUND(100.0 * -SUM(CASE WHEN flag_cancelado = 1 THEN quantidade * preco_unitario END)
          / SUM(CASE WHEN flag_cancelado = 0 THEN quantidade * preco_unitario END), 2) AS pct_cancelado_sobre_bruto
FROM fato_vendas;

-- ---------------------------------------------------------------------
-- B) Taxa de cancelamento sem o Reino Unido
-- Mesma fórmula da taxa geral (03_analise_cancelamentos_pais.sql),
-- excluindo clientes do Reino Unido. Equivale ao bookmark
-- "Sem Reino Unido" do Power BI (que mostra ~16,4%).
-- Resultado na auditoria: 16,36%.
-- ---------------------------------------------------------------------
SELECT
    COUNT(DISTINCT CASE WHEN v.flag_cancelado = 1 THEN v.id_transacao END) AS pedidos_cancelados,
    COUNT(DISTINCT v.id_transacao)                                         AS pedidos_total,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN v.flag_cancelado = 1 THEN v.id_transacao END)
          / COUNT(DISTINCT v.id_transacao), 2)                             AS pct_pedidos_cancelados
FROM fato_vendas v
JOIN dim_clientes c ON v.id_cliente = c.id_cliente
WHERE c.pais_cliente <> 'Reino Unido';

-- ---------------------------------------------------------------------
-- C) Os 2 pedidos de atacado comprados e depois cancelados
-- Identifica os cancelamentos extremos (quantidade <= -10.000) e soma a
-- compra original (mesmo cliente e produto, quantidade >= 10.000) e o
-- valor estornado. Fonte de: "RFM e Pareto incluem £ 1,84 Mi dos dois
-- pedidos de atacado cancelados (clientes 12346 e 16446), ~2,9% do total".
-- Resultado na auditoria: compras £ 1.842.831,90 (2,94% do bruto);
-- estornado £ 1.341.472,85 (o cancelamento do cliente 16446 foi
-- registrado à metade do preço da compra — anomalia da fonte).
-- ---------------------------------------------------------------------
WITH extremos AS (
    SELECT DISTINCT id_cliente, id_produto
    FROM fato_vendas
    WHERE flag_cancelado = 1 AND quantidade <= -10000
),
linhas AS (
    SELECT v.*
    FROM fato_vendas v
    JOIN extremos e ON v.id_cliente = e.id_cliente AND v.id_produto = e.id_produto
    WHERE ABS(v.quantidade) >= 10000
)
SELECT
    COUNT(DISTINCT id_cliente)                                                        AS clientes,
    ROUND(SUM(CASE WHEN flag_cancelado = 0 THEN quantidade * preco_unitario END), 2)  AS compras_brutas,
    ROUND(-SUM(CASE WHEN flag_cancelado = 1 THEN quantidade * preco_unitario END), 2) AS valor_estornado,
    ROUND(100.0 * SUM(CASE WHEN flag_cancelado = 0 THEN quantidade * preco_unitario END)
          / (SELECT SUM(quantidade * preco_unitario) FROM fato_vendas WHERE flag_cancelado = 0), 2) AS pct_do_bruto
FROM linhas;

-- ---------------------------------------------------------------------
-- D) Validação cruzada: linhas de venda válidas
-- Total de linhas não canceladas após a limpeza. Comparado com um
-- notebook público independente sobre a mesma base, que chegou ao
-- mesmo valor (ver seção "Validação cruzada" do README).
-- Resultado na auditoria: 522.601.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS linhas_venda_validas
FROM fato_vendas
WHERE flag_cancelado = 0;
