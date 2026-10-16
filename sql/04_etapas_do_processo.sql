-- 04_etapas_do_processo.sql
-- Em qual etapa o tempo é gasto? Aprovação → expedição (vendedor) → transporte.
--
-- Qualidade de dados: ~1,3% dos pedidos têm data de postagem anterior à
-- aprovação ou entrega anterior à postagem (registros inconsistentes).
-- Esses pedidos ficam fora desta análise de etapas.

SELECT
    COALESCE(regiao_cliente, 'Brasil (total)')                  AS regiao,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(dias_aprovacao), 1)                               AS aprovacao,
    ROUND(AVG(dias_expedicao), 1)                               AS expedicao_vendedor,
    ROUND(AVG(dias_transporte), 1)                              AS transporte,
    ROUND(AVG(lead_time_dias), 1)                               AS lead_time_total
FROM base_entregas
WHERE dias_aprovacao  >= 0
  AND dias_expedicao  >= 0
  AND dias_transporte >= 0
GROUP BY ROLLUP (regiao_cliente)
ORDER BY lead_time_total;
