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
        title="Selecione a spritesheet PNG",
        filetypes=[("PNG files", "*.png")]
    )

    if not png_path:
        print("Nenhum arquivo selecionado.")
        wait_exit()
        return

    framew = simpledialog.askinteger(
        "SheetTool",
        "Largura de cada frame:",
        initialvalue=60,
        minvalue=1
    )

    if framew is None:
        print("Operacao cancelada.")
        wait_exit()
        return

    frameh = simpledialog.askinteger(
        "SheetTool",
        "Altura de cada frame:",
        initialvalue=60,
        minvalue=1
    )

    if frameh is None:
        print("Operacao cancelada.")
        wait_exit()
        return

    transparent_first = messagebox.askyesno(
        "SheetTool",
        "Usar indice 0 como transparente/preto?\n\nRecomendado: SIM"
    )

    img = Image.open(png_path).convert("RGBA")
    width, height = img.size

    if width % framew != 0:
        raise RuntimeError("A largura da imagem nao e divisivel pela largura do frame.")

    if height % frameh != 0:
        raise RuntimeError("A altura da imagem nao e divisivel pela altura do frame.")

    pixels = img.load()
    frames_x = width // framew
    frames_y = height // frameh

    palette = []
    color_to_index = {}

    if transparent_first:
        color_to_index[(0, 0, 0, 0)] = 0
        palette.append((0, 0, 0, 0))

    out = bytearray()

    for fy in range(frames_y):
        for fx in range(frames_x):
            start_x = fx * framew
            start_y = fy * frameh

            for y in range(frameh):
                for x in range(framew):
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
    print("Frame:", framew, "x", frameh)
    print("Frames por linha:", frames_x)
    print("Frames por coluna:", frames_y)
    print("Total de frames:", frames_x * frames_y)
    print("Arquivo BIN:", bin_path)
    print("Tamanho BIN:", len(out), "bytes")
    print("Arquivo PAL:", pal_path)
    print("Cores na paleta:", len(palette))
    print("Tamanho PAL:", len(palette) * 4, "bytes")

    messagebox.showinfo("SheetTool", "Conversao concluida com sucesso!")
    wait_exit()


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print()
        print("ERRO:")
        print(e)
        try:
            messagebox.showerror("SheetTool - ERRO", str(e))
        except Exception:
            pass
        wait_exit()
