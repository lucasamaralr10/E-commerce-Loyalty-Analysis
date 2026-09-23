-- Mapeamento de Recência (Dias desde a última compra de cada cliente)
--Essa query calcula há quantos dias cada cliente fez sua última transação, essencial para estratégias de Marketing/CRM

SELECT 
    v.id_cliente,
    c.pais_cliente,
    MAX(v.data_transacao) AS data_ultima_compra,
    CAST(JULIANDAY('2020-01-01') - JULIANDAY(MAX(v.data_transacao)) AS INTEGER) AS dias_desde_ultima_compra
FROM fato_vendas v
JOIN dim_clientes c ON v.id_cliente = c.id_cliente
WHERE v.flag_cancelado = 0
GROUP BY v.id_cliente;
