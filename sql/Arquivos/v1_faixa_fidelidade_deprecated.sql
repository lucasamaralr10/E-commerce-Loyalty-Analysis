-- RECORRENCIA
WITH tbl_pedidos_cliente AS (
    SELECT 
        id_cliente,
        COUNT(DISTINCT id_transacao) AS total_compras
    FROM fato_vendas
    WHERE flag_cancelado = 0 AND id_cliente IS NOT NULL
    GROUP BY id_cliente
)
SELECT 
    CASE 
        WHEN total_compras = 1 THEN 'Comprou apenas 1 vez (Churn)'
        WHEN total_compras BETWEEN 2 AND 5 THEN 'Cliente Recorrente (2 a 5 compras)'
        ELSE 'Cliente Ultra Fiel (Mais de 5 compras)'
    END AS faixa_fidelidade,
    COUNT(*) AS qtd_clientes,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM tbl_pedidos_cliente), 2) AS percentual_base
FROM tbl_pedidos_cliente
GROUP BY faixa_fidelidade;
