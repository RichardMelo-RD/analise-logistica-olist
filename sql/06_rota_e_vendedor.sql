-- 06_rota_e_vendedor.sql
-- O atraso nasce no vendedor ou no transporte?

-- Rota: mesmo estado x interestadual
SELECT
    tipo_rota,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(entregue_no_prazo::INT) * 100, 1)                 AS pct_no_prazo,
    ROUND(AVG(lead_time_dias), 1)                               AS lead_time_medio,
    ROUND(SUM(valor_frete) / SUM(valor_produtos) * 100, 1)      AS frete_pct_produto
FROM base_entregas
GROUP BY tipo_rota;

-- Vendedor postou dentro do prazo-limite?
SELECT
    CASE WHEN vendedor_postou_no_prazo THEN 'Postou no prazo'
         ELSE 'Postou atrasado' END                             AS postagem_vendedor,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(entregue_no_prazo::INT) * 100, 1)                 AS pct_entregue_no_prazo
FROM base_entregas
GROUP BY postagem_vendedor;
