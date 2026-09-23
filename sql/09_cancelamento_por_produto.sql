-- ANALISE CANCELAMENTOS POR PRODUTO
-- Nota: exclui a transação id C581484 (-80.995 unidades, cliente 16446, produto
-- "Paper Craft Little Birdie") por ser um outlier extremo isolado que distorce
-- a leitura de padrões típicos de cancelamento. Ver nota no README sobre esse caso.
SELECT
    p.nome_produto,
    COUNT(DISTINCT v.id_transacao) AS total_pedidos_cancelados,
    ROUND(SUM(ABS(v.quantidade) * v.preco_unitario), 2) AS total_prejuizo_cancelamento
FROM fato_vendas v
JOIN dim_produtos p ON v.id_produto = p.id_produto
WHERE v.flag_cancelado = 1
  AND v.quantidade > -10000
GROUP BY p.nome_produto
ORDER BY total_prejuizo_cancelamento DESC;