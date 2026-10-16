# 📊 Guia: montando o dashboard no Power BI

Este guia mostra, passo a passo, como montar o dashboard de performance logística a partir
da base tratada em SQL. A ideia é que **você mesmo construa** o `.pbix`. É assim que se aprende,
e é isso que você vai explicar numa entrevista.

---

## 1. Gerar a base

Na raiz do projeto:

```bash
pip install -r requirements.txt
python scripts/baixar_dados.py
python scripts/rodar_sql.py
```

Isso cria `data/processed/base_entregas.csv`: 1 linha por pedido entregue, já com prazos,
etapas, frete, região e avaliação.

## 2. Importar no Power BI Desktop

1. **Obter dados → Texto/CSV →** `data/processed/base_entregas.csv` **→ Transformar dados**.
2. ⚠️ **Atenção à vírgula decimal.** O CSV usa **ponto** como separador decimal. Se o seu Windows
   estiver em português, selecione as colunas numéricas (`valor_*`, `dias_*`, `lead_time_dias`,
   `frete_pct_produto`) → botão direito → **Alterar tipo → Usando localidade… → Número decimal /
   Inglês (Estados Unidos)**. Sem isso, `12.5` vira `125`.
3. Confira os tipos: `data_compra` e `mes_compra` = **Data**; `entregue_no_prazo` e
   `vendedor_postou_no_prazo` = **Verdadeiro/Falso**.
4. Renomeie a tabela para **`Entregas`** e clique em **Fechar e Aplicar**.

> 💡 **Diferencial:** crie uma **tabela Calendário** (`Modelagem → Nova tabela`) e relacione com
> `Entregas[data_compra]`. Recrutadores notam modelagem bem feita.
>
> ```DAX
> Calendario = ADDCOLUMNS(
>     CALENDAR(DATE(2017,1,1), DATE(2018,8,31)),
>     "Ano", YEAR([Date]),
>     "Mes", FORMAT([Date], "mmm/yy"),
>     "MesNum", YEAR([Date]) * 100 + MONTH([Date])
> )
> ```
> Depois: selecione a coluna `Mes` → **Classificar por coluna → MesNum**.

## 3. Medidas DAX

Crie uma tabela vazia chamada `_Medidas` (Inserir dados → OK) para organizar as medidas:

```DAX
Pedidos = COUNTROWS(Entregas)

% No Prazo =
DIVIDE(
    CALCULATE(COUNTROWS(Entregas), Entregas[entregue_no_prazo] = TRUE()),
    [Pedidos]
)

Pedidos Atrasados = CALCULATE([Pedidos], Entregas[entregue_no_prazo] = FALSE())

Lead Time Médio (dias) = AVERAGE(Entregas[lead_time_dias])

Prazo Prometido (dias) = AVERAGE(Entregas[prazo_prometido_dias])

Folga do Prazo (dias) = [Prazo Prometido (dias)] - [Lead Time Médio (dias)]

Frete Médio = AVERAGE(Entregas[valor_frete])

Frete % do Produto =
DIVIDE(SUM(Entregas[valor_frete]), SUM(Entregas[valor_produtos]))

Nota Média = AVERAGE(Entregas[nota_avaliacao])

% Vendedor Postou no Prazo =
DIVIDE(
    CALCULATE(COUNTROWS(Entregas), Entregas[vendedor_postou_no_prazo] = TRUE()),
    [Pedidos]
)

Dias Transporte = AVERAGE(Entregas[dias_transporte])
Dias Expedição  = AVERAGE(Entregas[dias_expedicao])
```

Formate `% No Prazo`, `Frete % do Produto` e `% Vendedor Postou no Prazo` como **Porcentagem**
(1 casa decimal) e `Frete Médio` como **Moeda (R$)**.

Coluna calculada para a faixa de atraso (em `Entregas`):

```DAX
Faixa de Atraso =
SWITCH(
    TRUE(),
    Entregas[dias_atraso] <= 0, "1. No prazo",
    Entregas[dias_atraso] <= 3, "2. 1 a 3 dias",
    Entregas[dias_atraso] <= 7, "3. 4 a 7 dias",
    "4. 8+ dias"
)
```

## 4. Layout sugerido (1 página, 16:9)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  📦 Performance Logística · Olist         [Segmentação: Região] [Período] │
├────────────┬────────────┬────────────┬────────────┬────────────┬─────────┤
│  Pedidos   │ % No Prazo │ Lead Time  │  Folga do  │  Frete %   │  Nota   │
│  96.188    │   93,2%    │ 12,5 dias  │ Prazo 11,7 │   16,7%    │  4,16★  │
├────────────┴────────────┴─────────┬──┴────────────┴────────────┴─────────┤
│  Mapa (Mapa coroplético/Mapa)     │  % No Prazo por mês (linha)           │
│  Local: uf_cliente                │  + Pedidos (colunas)                  │
│  Cor: % No Prazo                  │  → evidencia Black Friday e mar/2018  │
├───────────────────────────────────┼───────────────────────────────────────┤
│  Etapas por região                │  Nota Média por Faixa de Atraso       │
│  (barras empilhadas: Expedição +  │  (colunas)                            │
│   Transporte)                     │  → o gráfico mais forte do projeto    │
└───────────────────────────────────┴───────────────────────────────────────┘
```

Dicas de design:
- Use **no máximo 2 ou 3 cores**: azul para o padrão e vermelho para o que está abaixo da meta.
- Formatação condicional no `% No Prazo` (vermelho abaixo de 90%).
- Títulos que **contam o achado**, não só descrevem o gráfico. Exemplo: em vez de
  "Nota por faixa de atraso", use "1 a 3 dias de atraso já derrubam a nota em 1 ponto".

## 5. Publicar no portfólio

1. Salve como `powerbi/dashboard_logistica.pbix` e faça commit.
2. Tire um print da página (ou grave um GIF curto com o [ScreenToGif](https://www.screentogif.com/))
   e salve em `images/dashboard.png`.
3. No `README.md`, descomente a seção **Dashboard** para exibir o print.
4. (Opcional) Publique no Power BI Service com **Publicar na Web** e coloque o link no README.
