#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path


def format_size(bytes_size):
    for unit in ("B", "KB", "MB", "GB"):
        if bytes_size < 1024:
            return f"{bytes_size:.1f} {unit}"
        bytes_size /= 1024
    return f"{bytes_size:.1f} TB"


def list_largest_files(directory="/var/log", top_n=20, sort_by="size"):
    files = []
    path = Path(directory)

    if not path.exists():
        print(f"Error: '{directory}' no existe.", file=sys.stderr)
        sys.exit(1)

    if not path.is_dir():
        print(f"Error: '{directory}' no es un directorio.", file=sys.stderr)
        sys.exit(1)

    for entry in path.rglob("*"):
        if entry.is_file() and not entry.is_symlink():
            try:
                size = entry.stat().st_size
                files.append((size, entry))
            except (PermissionError, OSError):
                pass

    if sort_by == "name":
        files.sort(key=lambda x: x[1].name.lower())
    else:
        files.sort(key=lambda x: x[0], reverse=True)

    top = files[:top_n]

    print(f"{'Tamaño':>10}  Archivo")
    print("-" * 70)
    for size, filepath in top:
        print(f"{format_size(size):>10}  {filepath}")

    print(f"\nTotal archivos encontrados: {len(files)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Lista los archivos más grandes de un directorio.")
    parser.add_argument("directory", nargs="?", default="/var/log", help="Directorio a analizar (default: /var/log)")
    parser.add_argument("top_n", nargs="?", type=int, default=20, help="Cantidad de archivos a mostrar (default: 20)")
    parser.add_argument("--sort-by", choices=["size", "name"], default="size", help="Criterio de ordenamiento (default: size)")
    args = parser.parse_args()

    list_largest_files(args.directory, args.top_n, args.sort_by)
