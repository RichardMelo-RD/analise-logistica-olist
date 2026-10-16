"""Baixa os CSVs da base pública da Olist para data/raw/.

Fonte: repositório oficial da Olist no GitHub (licença MIT)
https://github.com/olist/work-at-olist-data
"""
from pathlib import Path
from urllib.request import urlretrieve

URL_BASE = "https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/"
ARQUIVOS = [
    "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_customers_dataset.csv",
    "olist_sellers_dataset.csv",
    "olist_order_reviews_dataset.csv",
]

destino = Path(__file__).resolve().parent.parent / "data" / "raw"
destino.mkdir(parents=True, exist_ok=True)

for nome in ARQUIVOS:
    arquivo = destino / nome
    if arquivo.exists():
        print(f"✔ {nome} (já existe)")
        continue
    print(f"↓ baixando {nome}...")
    urlretrieve(URL_BASE + nome, arquivo)

print(f"\nPronto! Arquivos em {destino}")
