import csv
from tkinter import Tk, filedialog
import os
import sys

Tk().withdraw()

csv_path = filedialog.askopenfilename(
    title="Selecione o CSV exportado do Tiled",
    filetypes=[("CSV files", "*.csv")]
)

if not csv_path:
    print("Nenhum arquivo selecionado.")
    input("Pressione ENTER para sair...")
    sys.exit()

values = []

try:
    with open(csv_path, "r", encoding="utf-8-sig") as f:
        reader = csv.reader(f)

        for row_number, row in enumerate(reader, start=1):

            for col_number, item in enumerate(row, start=1):

                item = item.strip()

                if item == "":
                    continue

                tiled_value = int(item)

                # Trata qualquer valor negativo ou 0 como vazio
                if tiled_value <= 0:
                    engine_value = 0
                else:
                    engine_value = tiled_value

                if engine_value > 255:
                    raise ValueError(
                        f"Tile fora do limite 0-255 "
                        f"(Linha {row_number}, Coluna {col_number}) "
                        f"Valor: {engine_value}"
                    )

                values.append(engine_value)

    if len(values) == 0:
        raise ValueError("Nenhum tile encontrado no CSV.")

    bin_path = os.path.splitext(csv_path)[0] + ".bin"

    with open(bin_path, "wb") as f:
        f.write(bytes(values))

    print()
    print("Tilemap convertido com sucesso!")
    print("Arquivo:", bin_path)
    print("Quantidade de tiles:", len(values))
    print()
    print("Regras:")
    print("-1 -> 0 (vazio)")
    print(" 0 -> 0 (vazio)")
    print(" 1 -> 1")
    print(" 2 -> 2")
    print(" etc...")

except Exception as e:
    print()
    print("ERRO:")
    print(e)

print()
input("Pressione ENTER para sair...")