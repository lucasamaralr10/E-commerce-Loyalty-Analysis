-- SAZONALIDADE

SELECT
    strftime('%Y-%m', data_transacao) AS ano_mes,
    ROUND(SUM(v.quantidade * v.preco_unitario), 2) AS faturamento_mensal,
    COUNT(DISTINCT v.id_transacao) AS total_pedidos
FROM fato_vendas v
WHERE v.flag_cancelado = 0
GROUP BY ano_mes
ORDER BY ano_mes;
