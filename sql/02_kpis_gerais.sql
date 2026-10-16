-- 02_kpis_gerais.sql
-- Visão geral: os principais indicadores logísticos do período.

SELECT
    COUNT(*)                                                    AS pedidos_entregues,
    ROUND(AVG(entregue_no_prazo::INT) * 100, 1)                 AS pct_entregue_no_prazo,
    ROUND(MEDIAN(lead_time_dias), 1)                            AS lead_time_mediano_dias,
    ROUND(AVG(lead_time_dias), 1)                               AS lead_time_medio_dias,
    ROUND(AVG(prazo_prometido_dias), 1)                         AS prazo_prometido_medio_dias,
    ROUND(AVG(prazo_prometido_dias - lead_time_dias), 1)        AS folga_media_dias,
    ROUND(SUM(valor_frete) / SUM(valor_produtos) * 100, 1)      AS frete_pct_valor_produtos,
    ROUND(AVG(valor_frete), 2)                                  AS frete_medio_por_pedido,
    ROUND(AVG(vendedor_postou_no_prazo::INT) * 100, 1)          AS pct_vendedor_postou_no_prazo,
    ROUND(AVG(nota_avaliacao), 2)                               AS nota_media
FROM base_entregas;
