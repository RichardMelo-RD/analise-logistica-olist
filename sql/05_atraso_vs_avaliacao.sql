-- 05_atraso_vs_avaliacao.sql
-- Quanto o atraso custa em satisfação do cliente?

SELECT
    CASE
        WHEN dias_atraso <= 0 THEN '1. No prazo'
        WHEN dias_atraso <= 3 THEN '2. 1 a 3 dias de atraso'
        WHEN dias_atraso <= 7 THEN '3. 4 a 7 dias de atraso'
        ELSE                       '4. 8+ dias de atraso'
    END                                                         AS faixa_atraso,
    COUNT(*)                                                    AS pedidos,
    ROUND(AVG(nota_avaliacao), 2)                               AS nota_media,
    ROUND(AVG((nota_avaliacao <= 2)::INT) * 100, 1)             AS pct_notas_1_ou_2
FROM base_entregas
WHERE nota_avaliacao IS NOT NULL
GROUP BY faixa_atraso
ORDER BY faixa_atraso;
