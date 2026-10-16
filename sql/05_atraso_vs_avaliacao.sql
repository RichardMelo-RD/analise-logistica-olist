-- 05_atraso_vs_avaliacao.sql
-- Quanto o atraso custa em satisfação do cliente?
-- (faixa_atraso é calculada em 01_base_entregas.sql a partir de dias_atraso)

SELECT
    faixa_atraso,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(nota_avaliacao), 2)                               AS nota_media,
    ROUND(AVG((nota_avaliacao <= 2)::INT) * 100, 1)             AS pct_notas_1_ou_2
FROM base_entregas
WHERE nota_avaliacao IS NOT NULL
GROUP BY faixa_atraso
ORDER BY faixa_atraso;
