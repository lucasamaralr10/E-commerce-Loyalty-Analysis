-- FATURAMENTO POR DIA DA SEMANA
SELECT
    CASE strftime('%w', data_transacao)
        WHEN '0' THEN 'Domingo' WHEN '1' THEN 'Segunda' WHEN '2' THEN 'Terça'
        WHEN '3' THEN 'Quarta' WHEN '4' THEN 'Quinta' WHEN '5' THEN 'Sexta'
        WHEN '6' THEN 'Sábado' END AS dia_semana,
    CASE strftime('%w', data_transacao)
        WHEN '0' THEN 1 WHEN '1' THEN 2 WHEN '2' THEN 3
        WHEN '3' THEN 4 WHEN '4' THEN 5 WHEN '5' THEN 6
        WHEN '6' THEN 7 END AS ordem_dia,
    ROUND(SUM(v.quantidade * v.preco_unitario), 2) AS faturamento,
    COUNT(DISTINCT v.id_transacao) AS total_pedidos
FROM fato_vendas v
WHERE v.flag_cancelado = 0
GROUP BY dia_semana, ordem_dia
ORDER BY ordem_dia;