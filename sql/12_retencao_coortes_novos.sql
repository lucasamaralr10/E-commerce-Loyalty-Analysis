-- =====================================================================
-- 12_retencao_coortes_novos.sql
-- Retenção em M1 e M6 dos clientes realmente novos (média ponderada).
-- Fonte da manchete "~18% voltam a comprar no mês seguinte e ~24%
-- compram no 6º mês".
--
-- Mesma lógica de coorte de 07_coorte_retencao.sql: coorte = mês da
-- primeira compra válida; atividade = qualquer compra não cancelada.
-- Filtros:
--   * exclui dez/2018: o dataset começa nesse mês, então esse coorte
--     reúne a base de clientes antigos (censura à esquerda);
--   * inclui só os coortes de jan a mai/2019: a partir de jun/2019 o M6
--     cairia em dez/2019, mês parcial com dados até 09/12 (censura à direita).
-- Média ponderada = soma dos clientes que voltaram / soma dos tamanhos
-- dos coortes (coortes maiores pesam mais).
-- Resultado na auditoria: 2.080 clientes; M1 = 18,27%; M6 = 24,13%.
-- =====================================================================
WITH primeira_compra AS (
    SELECT id_cliente, MIN(strftime('%Y-%m', data_transacao)) AS mes_coorte
    FROM fato_vendas
    WHERE flag_cancelado = 0
    GROUP BY id_cliente
),
atividade AS (
    SELECT DISTINCT
        v.id_cliente,
        pc.mes_coorte,
        (CAST(strftime('%Y', v.data_transacao) AS INTEGER) - CAST(substr(pc.mes_coorte, 1, 4) AS INTEGER)) * 12
      + (CAST(strftime('%m', v.data_transacao) AS INTEGER) - CAST(substr(pc.mes_coorte, 6, 2) AS INTEGER)) AS mes_relativo
    FROM fato_vendas v
    JOIN primeira_compra pc ON v.id_cliente = pc.id_cliente
    WHERE v.flag_cancelado = 0
),
por_coorte AS (
    SELECT
        mes_coorte,
        SUM(mes_relativo = 0) AS tamanho,
        SUM(mes_relativo = 1) AS m1,
        SUM(mes_relativo = 6) AS m6
    FROM atividade
    GROUP BY mes_coorte
)
SELECT
    SUM(tamanho)                              AS clientes_novos,
    SUM(m1)                                   AS voltaram_m1,
    ROUND(100.0 * SUM(m1) / SUM(tamanho), 2)  AS pct_m1_ponderado,
    SUM(m6)                                   AS compraram_m6,
    ROUND(100.0 * SUM(m6) / SUM(tamanho), 2)  AS pct_m6_ponderado
FROM por_coorte
WHERE mes_coorte BETWEEN '2019-01' AND '2019-05';
