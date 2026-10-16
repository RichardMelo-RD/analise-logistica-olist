-- =============================================================================
-- 01_base_entregas.sql
-- Cria a tabela analítica "base_entregas": 1 linha por pedido entregue,
-- com prazos, etapas do processo logístico, frete, região e avaliação.
--
-- Escopo: pedidos com status 'delivered', com data de entrega preenchida,
-- comprados entre jan/2017 e ago/2018 (meses com volume representativo).
-- =============================================================================

CREATE OR REPLACE TABLE orders     AS SELECT * FROM read_csv_auto('data/raw/olist_orders_dataset.csv');
CREATE OR REPLACE TABLE items      AS SELECT * FROM read_csv_auto('data/raw/olist_order_items_dataset.csv');
CREATE OR REPLACE TABLE customers  AS SELECT * FROM read_csv_auto('data/raw/olist_customers_dataset.csv');
CREATE OR REPLACE TABLE sellers    AS SELECT * FROM read_csv_auto('data/raw/olist_sellers_dataset.csv');
CREATE OR REPLACE TABLE reviews    AS SELECT * FROM read_csv_auto('data/raw/olist_order_reviews_dataset.csv');

-- Regiões do Brasil (IBGE)
CREATE OR REPLACE TABLE regioes AS
SELECT * FROM (VALUES
    ('AC','Norte'),('AM','Norte'),('AP','Norte'),('PA','Norte'),('RO','Norte'),('RR','Norte'),('TO','Norte'),
    ('AL','Nordeste'),('BA','Nordeste'),('CE','Nordeste'),('MA','Nordeste'),('PB','Nordeste'),
    ('PE','Nordeste'),('PI','Nordeste'),('RN','Nordeste'),('SE','Nordeste'),
    ('DF','Centro-Oeste'),('GO','Centro-Oeste'),('MS','Centro-Oeste'),('MT','Centro-Oeste'),
    ('ES','Sudeste'),('MG','Sudeste'),('RJ','Sudeste'),('SP','Sudeste'),
    ('PR','Sul'),('RS','Sul'),('SC','Sul')
) AS t(uf, regiao);

-- Itens agregados por pedido: valor, frete e prazo-limite de postagem do vendedor
CREATE OR REPLACE TABLE itens_pedido AS
SELECT
    order_id,
    COUNT(*)                     AS qtd_itens,
    SUM(price)                   AS valor_produtos,
    SUM(freight_value)           AS valor_frete,
    MAX(shipping_limit_date)     AS prazo_postagem,
    ARG_MIN(seller_id, order_item_id) AS seller_id,     -- vendedor do 1º item
    COUNT(DISTINCT seller_id)    AS qtd_vendedores
FROM items
GROUP BY order_id;

-- Uma avaliação por pedido (a mais recente)
CREATE OR REPLACE TABLE avaliacao_pedido AS
SELECT order_id, review_score AS nota_avaliacao
FROM reviews
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) = 1;

CREATE OR REPLACE TABLE base_entregas AS
SELECT
    o.order_id,
    CAST(o.order_purchase_timestamp AS DATE)                         AS data_compra,
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE            AS mes_compra,

    -- Origem e destino
    s.seller_state                                                   AS uf_vendedor,
    c.customer_state                                                 AS uf_cliente,
    rc.regiao                                                        AS regiao_cliente,
    CASE WHEN s.seller_state = c.customer_state
         THEN 'Mesmo estado' ELSE 'Interestadual' END                AS tipo_rota,

    -- Valores
    i.qtd_itens,
    i.valor_produtos,
    i.valor_frete,
    i.valor_frete / NULLIF(i.valor_produtos, 0)                      AS frete_pct_produto,

    -- Etapas do processo (em dias)
    DATE_DIFF('hour', o.order_purchase_timestamp, o.order_approved_at) / 24.0              AS dias_aprovacao,
    DATE_DIFF('hour', o.order_approved_at, o.order_delivered_carrier_date) / 24.0          AS dias_expedicao,
    DATE_DIFF('hour', o.order_delivered_carrier_date, o.order_delivered_customer_date) / 24.0 AS dias_transporte,
    DATE_DIFF('hour', o.order_purchase_timestamp, o.order_delivered_customer_date) / 24.0  AS lead_time_dias,
    DATE_DIFF('day', o.order_purchase_timestamp, o.order_estimated_delivery_date)          AS prazo_prometido_dias,

    -- Pontualidade
    DATE_DIFF('day', CAST(o.order_estimated_delivery_date AS DATE),
                     CAST(o.order_delivered_customer_date AS DATE))  AS dias_atraso,   -- negativo = adiantado
    CAST(o.order_delivered_customer_date AS DATE)
        <= CAST(o.order_estimated_delivery_date AS DATE)             AS entregue_no_prazo,
    o.order_delivered_carrier_date <= i.prazo_postagem               AS vendedor_postou_no_prazo,
    CASE
        WHEN DATE_DIFF('day', CAST(o.order_estimated_delivery_date AS DATE),
                              CAST(o.order_delivered_customer_date AS DATE)) <= 0 THEN '1. No prazo'
        WHEN DATE_DIFF('day', CAST(o.order_estimated_delivery_date AS DATE),
                              CAST(o.order_delivered_customer_date AS DATE)) <= 3 THEN '2. 1 a 3 dias de atraso'
        WHEN DATE_DIFF('day', CAST(o.order_estimated_delivery_date AS DATE),
                              CAST(o.order_delivered_customer_date AS DATE)) <= 7 THEN '3. 4 a 7 dias de atraso'
        ELSE '4. 8+ dias de atraso'
    END                                                              AS faixa_atraso,

    -- Satisfação
    a.nota_avaliacao
FROM orders o
JOIN itens_pedido i        ON i.order_id    = o.order_id
JOIN customers c           ON c.customer_id = o.customer_id
JOIN sellers s             ON s.seller_id   = i.seller_id
LEFT JOIN regioes rc       ON rc.uf         = c.customer_state
LEFT JOIN avaliacao_pedido a ON a.order_id  = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_carrier_date  IS NOT NULL
  AND o.order_approved_at             IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';
