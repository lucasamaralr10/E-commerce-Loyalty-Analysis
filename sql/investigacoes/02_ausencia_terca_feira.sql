SELECT
    strftime('%w', data_transacao) AS codigo_dia,
    COUNT(*) AS total_registros
FROM fato_vendas
WHERE flag_cancelado = 0
GROUP BY codigo_dia
ORDER BY codigo_dia;