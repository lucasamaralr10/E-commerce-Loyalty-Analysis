-- Ticket médio por país

SELECT
    c.pais_cliente,
    COUNT(DISTINCT v.id_transacao) AS total_pedidos,
    ROUND(SUM(v.quantidade * v.preco_unitario) / COUNT(DISTINCT v.id_transacao), 2) AS ticket_medio
FROM fato_vendas v
JOIN dim_clientes c ON v.id_cliente = c.id_cliente
WHERE v.flag_cancelado = 0
GROUP BY c.pais_cliente
HAVING COUNT(DISTINCT v.id_transacao) >= 20  -- filtra ruído de países com poucas transações
ORDER BY ticket_medio DESC;
