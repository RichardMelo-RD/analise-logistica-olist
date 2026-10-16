-- 07_evolucao_mensal.sql
-- Como volume e pontualidade evoluíram mês a mês?

SELECT
    mes_compra                                                  AS mes,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(entregue_no_prazo::INT) * 100, 1)                 AS pct_no_prazo,
    ROUND(AVG(lead_time_dias), 1)                               AS lead_time_medio
FROM base_entregas
GROUP BY mes_compra
ORDER BY mes_compra;
