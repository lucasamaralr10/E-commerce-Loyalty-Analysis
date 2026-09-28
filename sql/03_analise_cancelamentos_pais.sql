-- ANALISE CANCELAMENTOS POR PAÍS
-- Nota: o filtro quantidade > -10000 exclui os 2 cancelamentos extremos:
-- C581484 (-80.995 unidades, cliente 16446, produto "Paper Craft Little Birdie")
-- e C541433 (-74.215 unidades, cliente 12346). São outliers isolados (pedidos de
-- atacado cancelados por inteiro) que distorcem a leitura de padrões típicos de
-- cancelamento. Ver seção de auditoria no README.
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

-- TAXA DE CANCELAMENTO GERAL (todos os países, sem exclusões)
-- Mesma fórmula da medida DAX "Taxa de Cancelamento":
-- pedidos cancelados / (pedidos cancelados + pedidos válidos).
-- Diferença: aqui entram todos os cancelamentos (3.379 / 23.168 = 14,58%);
-- a medida DAX exclui os 2 cancelamentos extremos (quantidade <= -10000,
-- clientes 12346 e 16446) e mostra 3.377 / 23.166 = 14,58%. A taxa é a mesma.
-- Obs.: o bookmark "Sem Reino Unido" do Power BI mostra outro recorte (~16,4%).
SELECT
    COUNT(DISTINCT CASE WHEN flag_cancelado = 1 THEN id_transacao END) AS pedidos_cancelados,
    COUNT(DISTINCT id_transacao)                                       AS pedidos_total,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN flag_cancelado = 1 THEN id_transacao END)
          / COUNT(DISTINCT id_transacao), 2)                           AS pct_pedidos_cancelados
FROM fato_vendas;

-- RASCUNHO DE CONSULTA PARA VERIFICAR SE EXISTEM REGISTROS COM QUANTIDADE NEGATIVA NA TABELA DE VENDAS
--SELECT quantidade 
--FROM tb_raw_vendas 
--WHERE quantidade < 0 
--LIMIT 5;
