-- 03_pontualidade_por_regiao.sql
-- Onde a operação falha mais? Pontualidade, lead time e frete por região
-- e por UF de destino (UFs com pelo menos 300 pedidos, para evitar ruído).

-- Por região
SELECT
    regiao_cliente                                              AS regiao,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(entregue_no_prazo::INT) * 100, 1)                 AS pct_no_prazo,
    ROUND(AVG(lead_time_dias), 1)                               AS lead_time_medio,
    ROUND(AVG(prazo_prometido_dias), 1)                         AS prazo_prometido_medio,
    ROUND(AVG(valor_frete), 2)                                  AS frete_medio,
    ROUND(SUM(valor_frete) / SUM(valor_produtos) * 100, 1)      AS frete_pct_produto
FROM base_entregas
GROUP BY regiao_cliente
ORDER BY pct_no_prazo;

-- Por UF (as 10 piores)
SELECT
    uf_cliente                                                  AS uf,
    regiao_cliente                                              AS regiao,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(entregue_no_prazo::INT) * 100, 1)                 AS pct_no_prazo,
    ROUND(AVG(lead_time_dias), 1)                               AS lead_time_medio
FROM base_entregas
GROUP BY uf_cliente, regiao_cliente
HAVING COUNT(*) >= 300
ORDER BY pct_no_prazo
LIMIT 10;
