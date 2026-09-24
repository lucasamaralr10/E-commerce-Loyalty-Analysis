-- Total de faturamento via fato_vendas, com o preço unitário REAL de cada transação
-- (modelagem corrigida; é o que RFM e as demais queries atuais usam)
SELECT ROUND(SUM(v.quantidade * v.preco_unitario), 2) AS total_via_preco_medio
FROM fato_vendas v
JOIN dim_produtos p ON v.id_produto = p.id_produto
WHERE v.flag_cancelado = 0;

-- Total de faturamento usando o preço REAL de cada transação (dado bruto, sem distorção)
SELECT ROUND(SUM(quantidade * preco_unitario), 2) AS total_via_preco_real
FROM tb_raw_vendas
WHERE id_transacao NOT LIKE 'C%';

-- Reprodução do BUG da modelagem antiga: preço escolhido arbitrariamente por produto
-- (GROUP BY sem agregação: o SQLite pega o preço de uma linha qualquer do grupo).
-- Resultado não-determinístico. Na reprodução da auditoria: £ 41.904.259,78
-- (~33% abaixo do valor correto de £ 62.781.304,54).
WITH preco_arbitrario AS (
    SELECT id_produto, preco_unitario FROM tb_raw_vendas GROUP BY id_produto
)
SELECT ROUND(SUM(r.quantidade * p.preco_unitario), 2) AS total_preco_arbitrario_bug
FROM tb_raw_vendas r
JOIN preco_arbitrario p ON r.id_produto = p.id_produto
WHERE r.id_transacao NOT LIKE 'C%';
