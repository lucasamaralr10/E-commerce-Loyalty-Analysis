DROP TABLE IF EXISTS dim_produtos;

CREATE TABLE dim_produtos (
    id_produto TEXT PRIMARY KEY,
    nome_produto TEXT
);

INSERT INTO dim_produtos (id_produto, nome_produto)
SELECT id_produto, nome_produto
FROM tb_raw_vendas
WHERE id_produto IS NOT NULL
GROUP BY id_produto, nome_produto;

DROP TABLE IF EXISTS fato_vendas;

CREATE TABLE fato_vendas (
    id_transacao TEXT,
    id_cliente INTEGER,
    id_produto TEXT,
    data_transacao TEXT,
    quantidade INTEGER,
    preco_unitario NUMERIC,
    flag_cancelado INTEGER,
    flag_outlier_quantidade INTEGER,
    FOREIGN KEY (id_cliente) REFERENCES dim_clientes(id_cliente),
    FOREIGN KEY (id_produto) REFERENCES dim_produtos(id_produto)
);

INSERT INTO fato_vendas
SELECT
    id_transacao, id_cliente, id_produto, data_transacao,
    quantidade, preco_unitario,
    CASE WHEN id_transacao LIKE 'C%' THEN 1 ELSE 0 END AS flag_cancelado,
    flag_outlier_quantidade
FROM tb_raw_vendas;

CREATE INDEX idx_fato_id_cliente ON fato_vendas(id_cliente);
CREATE INDEX idx_fato_id_produto ON fato_vendas(id_produto);
CREATE INDEX idx_fato_flag_cancelado ON fato_vendas(flag_cancelado);
CREATE INDEX idx_dim_clientes_id ON dim_clientes(id_cliente);
CREATE INDEX idx_dim_produtos_id ON dim_produtos(id_produto);
ANALYZE;