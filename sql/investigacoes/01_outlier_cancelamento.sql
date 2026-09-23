SELECT
    v.id_transacao,
    v.id_cliente,
    p.nome_produto,
    v.data_transacao,
    v.quantidade,
    v.preco_unitario,
    ROUND(ABS(v.quantidade) * v.preco_unitario, 2) AS valor_transacao
FROM fato_vendas v
JOIN dim_produtos p ON v.id_produto = p.id_produto
WHERE v.flag_cancelado = 1
  AND v.quantidade <= -10000
ORDER BY v.quantidade ASC;

SELECT *
FROM fato_vendas
WHERE id_produto = (
    SELECT id_produto FROM dim_produtos WHERE nome_produto = 'Paper Craft Little Birdie'
)
AND flag_cancelado = 1
ORDER BY quantidade ASC
LIMIT 5;