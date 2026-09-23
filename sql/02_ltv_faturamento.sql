-- LTV FATURAMENTO
SELECT 
    v.id_cliente,
    c.pais_cliente,
    COUNT(DISTINCT v.id_transacao) AS total_pedidos_realizados,
    -- O ROUND(..., 2) garante que o resultado final terá exatamente 2 casas decimais
    ROUND(SUM(v.quantidade * v.preco_unitario), 2) AS faturamento_total_ltv
FROM fato_vendas v
JOIN dim_clientes c ON v.id_cliente = c.id_cliente
WHERE v.flag_cancelado = 0
GROUP BY v.id_cliente
ORDER BY faturamento_total_ltv DESC;
