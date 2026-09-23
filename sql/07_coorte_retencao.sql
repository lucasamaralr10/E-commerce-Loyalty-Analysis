-- Coorte de retenção mensal

-- COORTE DE RETENÇÃO (MESES RELATIVOS)
WITH primeira_compra AS (
    SELECT id_cliente, MIN(strftime('%Y-%m', data_transacao)) AS mes_coorte
    FROM fato_vendas WHERE flag_cancelado = 0
    GROUP BY id_cliente
),
atividade AS (
    SELECT
        v.id_cliente,
        pc.mes_coorte,
        strftime('%Y-%m', v.data_transacao) AS mes_atividade
    FROM fato_vendas v
    JOIN primeira_compra pc ON v.id_cliente = pc.id_cliente
    WHERE v.flag_cancelado = 0
)
SELECT
    mes_coorte,
    mes_atividade,
    -- Calcula a diferença em meses entre o mês de atividade e o mês de aquisição (coorte)
    (CAST(strftime('%Y', mes_atividade || '-01') AS INTEGER) - CAST(strftime('%Y', mes_coorte || '-01') AS INTEGER)) * 12
      + (CAST(strftime('%m', mes_atividade || '-01') AS INTEGER) - CAST(strftime('%m', mes_coorte || '-01') AS INTEGER)) AS mes_relativo,
    COUNT(DISTINCT id_cliente) AS clientes_ativos
FROM atividade
GROUP BY mes_coorte, mes_atividade
ORDER BY mes_coorte, mes_relativo;