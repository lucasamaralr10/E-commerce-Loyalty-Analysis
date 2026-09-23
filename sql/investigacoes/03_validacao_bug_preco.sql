-- Total de faturamento usando o preço MÉDIO (o que RFM e outras queries atuais usam)
SELECT ROUND(SUM(v.quantidade * v.preco_unitario), 2) AS total_via_preco_medio
FROM fato_vendas v
JOIN dim_produtos p ON v.id_produto = p.id_produto
WHERE v.flag_cancelado = 0;

-- Total de faturamento usando o preço REAL de cada transação (dado bruto, sem distorção)
SELECT ROUND(SUM(quantidade * preco_unitario), 2) AS total_via_preco_real
FROM tb_raw_vendas
WHERE id_transacao NOT LIKE 'C%';
