-- ANALISE CANCELAMENTOS POR PAÍS
-- Nota: exclui a transação id C581484 (-80.995 unidades, cliente 16446, produto
-- "Paper Craft Little Birdie") por ser um outlier extremo isolado que distorce
-- a leitura de padrões típicos de cancelamento. Ver nota no README sobre esse caso.
SELECT 
    c.pais_cliente,
    COUNT(DISTINCT v.id_transacao) AS total_pedidos_cancelados,
    -- Protegendo a soma dos cancelamentos contra dízimas do ponto flutuante
    ROUND(SUM(ABS(v.quantidade) * v.preco_unitario), 2) AS total_prejuizo_cancelamento
FROM fato_vendas v
JOIN dim_clientes c ON v.id_cliente = c.id_cliente
WHERE v.flag_cancelado = 1
  AND v.quantidade > -10000
GROUP BY c.pais_cliente
ORDER BY total_prejuizo_cancelamento DESC;

-- RASCUNHO DE CONSULTA PARA VERIFICAR SE EXISTEM REGISTROS COM QUANTIDADE NEGATIVA NA TABELA DE VENDAS
--SELECT quantidade 
--FROM tb_raw_vendas 
--WHERE quantidade < 0 
--LIMIT 5;
