"""Executa as consultas da pasta sql/ com DuckDB e exporta a base para o Power BI.

Uso (a partir da raiz do projeto):
    python scripts/rodar_sql.py
"""
from pathlib import Path

import duckdb

RAIZ = Path(__file__).resolve().parent.parent
PASTA_SQL = RAIZ / "sql"
SAIDA = RAIZ / "data" / "processed" / "base_entregas.csv"


def comandos(arquivo: Path) -> list[str]:
    """Separa um arquivo .sql em comandos individuais."""
    return [c.strip() for c in arquivo.read_text(encoding="utf-8").split(";") if c.strip()]


def preparar_base(con: duckdb.DuckDBPyConnection) -> None:
    """Cria a tabela base_entregas (sql/01_base_entregas.sql)."""
    for comando in comandos(PASTA_SQL / "01_base_entregas.sql"):
        con.execute(comando)


if __name__ == "__main__":
    import os

    os.chdir(RAIZ)  # os caminhos dos CSVs no SQL são relativos à raiz
    con = duckdb.connect()
    preparar_base(con)

    for arquivo in sorted(PASTA_SQL.glob("0[2-9]_*.sql")):
        print(f"\n{'=' * 70}\n{arquivo.name}\n{'=' * 70}")
        for comando in comandos(arquivo):
            con.sql(comando).show(max_width=200)

    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    con.execute(f"COPY base_entregas TO '{SAIDA.as_posix()}' (HEADER, DELIMITER ',')")
    print(f"\nBase exportada para o Power BI: {SAIDA.relative_to(RAIZ)}")
    print("Caminho completo (cole no parâmetro CaminhoCSV do Power BI):")
    print(f"  {SAIDA}")
