-- Para calibrar um limite mais defensável que -10000 "no chute"
SELECT
    quantidade
FROM fato_vendas
WHERE flag_cancelado = 1
ORDER BY quantidade ASC
LIMIT 10;