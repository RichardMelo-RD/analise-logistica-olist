# 📊 Dashboard no Power BI

Esta pasta tem o dashboard pronto no formato **Power BI Project (`.pbip`)**: o modelo de dados,
as medidas DAX e a página do relatório ficam em arquivos de texto, o que permite versionar tudo no Git.

```
powerbi/
├── dashboard_logistica.pbip              ← abra este arquivo no Power BI Desktop
├── dashboard_logistica.SemanticModel/    ← modelo: tabela, tipos, medidas DAX
└── dashboard_logistica.Report/           ← página com os visuais
```

## ▶️ Abrindo o dashboard

1. **Gere a base** (se ainda não gerou), na raiz do projeto:
   ```bash
   python scripts/baixar_dados.py
   python scripts/rodar_sql.py
   ```
   No final, o script mostra o **caminho completo** do `base_entregas.csv`. Copie esse caminho.
2. No **Power BI Desktop** (versão atualizada): **Arquivo → Abrir → Procurar** e escolha
   `powerbi/dashboard_logistica.pbip`.
   - Se der erro dizendo que o formato não é suportado: **Arquivo → Opções e configurações → Opções →
     Recursos de visualização** → marque **"Opção de salvamento do projeto do Power BI (.pbip)"**,
     reinicie o Power BI e tente de novo.
3. Os visuais vão abrir **vazios** (o projeto não guarda os dados, só a estrutura). Para carregar:
   **Página Inicial → Transformar dados → Editar parâmetros → `CaminhoCSV`** → cole o caminho do passo 1
   → **OK** → **Aplicar alterações**.
4. Pronto! Confira se os cartões mostram estes valores (sem filtro de região):

   | Pedidos | % No Prazo | Lead Time Médio | Folga do Prazo | Frete % do Produto | Nota Média |
   |---|---|---|---|---|---|
   | 96.188 | 93,2% | 12,5 dias | 11,7 dias | 16,7% | 4,16 ★ |

5. **Para o portfólio:** tire um print da página e salve como `images/dashboard.png`.
   Também vale salvar uma cópia como `.pbix` (**Arquivo → Salvar como → .pbix**) para quem quiser
   baixar e abrir com um clique.

> ⚠️ Se algum visual aparecer com erro ou desconfigurado, os dados e as medidas continuam corretos.
> Dá para refazer só aquele visual seguindo a seção **Construindo do zero** abaixo.

## 📐 O que tem no dashboard

| Visual | O que mostra |
|---|---|
| Cartões | Pedidos, % no prazo, lead time, folga do prazo prometido, frete % e nota média |
| Filtro | Região de destino (filtra a página inteira) |
| Colunas + linha | Volume de pedidos x % no prazo por mês (Black Friday e mar/2018 aparecem na hora) |
| Barras | % no prazo por UF, das piores para as melhores |
| Barras empilhadas | Dias em cada etapa (aprovação, expedição, transporte) por região |
| Colunas | Nota média por faixa de atraso (o achado principal) |

---

# 🛠️ Construindo do zero

O resto deste guia mostra como o dashboard foi construído, passo a passo. Use para entender cada
parte, refazer um visual ou montar a sua própria versão.

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

A faixa de atraso já vem pronta na coluna `faixa_atraso`, calculada no SQL
(`sql/01_base_entregas.sql`). Se preferir fazer em DAX, seria uma coluna calculada assim:

```DAX
Faixa de Atraso =
SWITCH(
    TRUE(),
    Entregas[dias_atraso] <= 0, "1. No prazo",
    Entregas[dias_atraso] <= 3, "2. 1 a 3 dias de atraso",
    Entregas[dias_atraso] <= 7, "3. 4 a 7 dias de atraso",
    "4. 8+ dias de atraso"
)
```

As medidas de etapas desconsideram os ~1,3% de pedidos com datas inconsistentes:

```DAX
Dias Transporte =
CALCULATE(
    AVERAGE(Entregas[dias_transporte]),
    Entregas[dias_aprovacao] >= 0,
    Entregas[dias_expedicao] >= 0,
    Entregas[dias_transporte] >= 0
)
```
(`Dias Aprovação` e `Dias Expedição` seguem a mesma lógica.)

## 4. Layout (1 página, 1280 × 720)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Performance Logística · E-commerce Olist           [Filtro: Região ▾]   │
├────────────┬────────────┬────────────┬────────────┬────────────┬─────────┤
│  Pedidos   │ % No Prazo │ Lead Time  │  Folga do  │  Frete %   │  Nota   │
│  96.188    │   93,2%    │ 12,5 dias  │ Prazo 11,7 │   16,7%    │  4,16★  │
├────────────┴────────────┴────────────┴──────┬─────┴────────────┴─────────┤
│  Pedidos (colunas) x % No Prazo (linha)     │  % No Prazo por UF         │
│  por mês → Black Friday e mar/2018          │  (barras, piores primeiro) │
├─────────────────────────────────┬───────────┴────────────────────────────┤
│  Dias por etapa, por região     │  Nota Média por Faixa de Atraso        │
│  (barras empilhadas)            │  (colunas) → o gráfico mais forte      │
└─────────────────────────────────┴────────────────────────────────────────┘
```

Dicas de design:
- Use **no máximo 2 ou 3 cores**: azul para o padrão e vermelho para o que está abaixo da meta.
- Formatação condicional no `% No Prazo` (vermelho abaixo de 90%).
- Títulos que **contam o achado**, não só descrevem o gráfico. Exemplo: em vez de
  "Nota por faixa de atraso", use "1 a 3 dias de atraso já derrubam a nota em 1 ponto".

## 5. Publicar no portfólio

1. Salve (o `.pbip` salva direto nos arquivos da pasta) e faça commit.
2. Tire um print da página (ou grave um GIF curto com o [ScreenToGif](https://www.screentogif.com/))
   e salve em `images/dashboard.png`.
3. No `README.md`, descomente a seção **Dashboard** para exibir o print.
4. (Opcional) Publique no Power BI Service com **Publicar na Web** e coloque o link no README.
