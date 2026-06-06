from PIL import Image
from tkinter import Tk, filedialog, simpledialog, messagebox
import os
import sys


def add_color(color_to_index, palette, rgba):
    r, g, b, a = rgba

    if a == 0:
        rgba = (0, 0, 0, 0)

    if rgba in color_to_index:
        return color_to_index[rgba]

    if len(palette) >= 256:
        raise RuntimeError("Erro: a imagem tem mais de 256 cores.")

    index = len(palette)
    color_to_index[rgba] = index
    palette.append(rgba)
    return index


def wait_exit():
    print()
    input("Pressione ENTER para sair...")


def main():
    root = Tk()
    root.withdraw()

    png_path = filedialog.askopenfilename(
        title="Selecione o tileset PNG",
        filetypes=[("PNG files", "*.png")]
    )

    if not png_path:
        print("Nenhum arquivo selecionado.")
        wait_exit()
        return

    tilew = simpledialog.askinteger(
        "TileTool",
        "Largura do tile:",
        initialvalue=16,
        minvalue=1
    )

    if tilew is None:
        print("Operacao cancelada.")
        wait_exit()
        return

    tileh = simpledialog.askinteger(
        "TileTool",
        "Altura do tile:",
        initialvalue=16,
        minvalue=1
    )

    if tileh is None:
        print("Operacao cancelada.")
        wait_exit()
        return

    transparent_first = messagebox.askyesno(
        "TileTool",
        "Usar indice 0 como transparente/preto?\n\nRecomendado: SIM"
    )

    img = Image.open(png_path).convert("RGBA")
    width, height = img.size

    if width % tilew != 0:
        raise RuntimeError("A largura da imagem nao e divisivel pela largura do tile.")

    if height % tileh != 0:
        raise RuntimeError("A altura da imagem nao e divisivel pela altura do tile.")

    pixels = img.load()
    tiles_x = width // tilew
    tiles_y = height // tileh

    palette = []
    color_to_index = {}

    if transparent_first:
        color_to_index[(0, 0, 0, 0)] = 0
        palette.append((0, 0, 0, 0))

    out = bytearray()

    for ty in range(tiles_y):
        for tx in range(tiles_x):
            start_x = tx * tilew
            start_y = ty * tileh

            for y in range(tileh):
                for x in range(tilew):
                    rgba = pixels[start_x + x, start_y + y]
                    index = add_color(color_to_index, palette, rgba)
                    out.append(index)

    base = os.path.splitext(png_path)[0]
    bin_path = base + ".bin"
    pal_path = base + ".pal"

    with open(bin_path, "wb") as f:
        f.write(out)

    pal_out = bytearray()

    for r, g, b, a in palette:
        if a == 0:
            r, g, b = 0, 0, 0

        pal_out.append(b)
        pal_out.append(g)
        pal_out.append(r)
        pal_out.append(0)

    with open(pal_path, "wb") as f:
        f.write(pal_out)

    print("Conversao concluida.")
    print("Imagem:", png_path)
    print("Tamanho:", width, "x", height)
    print("Tile:", tilew, "x", tileh)
    print("Tiles por linha:", tiles_x)
    print("Tiles por coluna:", tiles_y)
    print("Total de tiles:", tiles_x * tiles_y)
    print("Arquivo BIN:", bin_path)
    print("Tamanho BIN:", len(out), "bytes")
    print("Arquivo PAL:", pal_path)
    print("Cores na paleta:", len(palette))
    print("Tamanho PAL:", len(palette) * 4, "bytes")

    messagebox.showinfo("TileTool", "Conversao concluida com sucesso!")
    wait_exit()


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print()
        print("ERRO:")
        print(e)
        try:
            messagebox.showerror("TileTool - ERRO", str(e))
        except Exception:
            pass
        wait_exit()
