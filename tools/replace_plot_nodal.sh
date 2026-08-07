#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="${1:-app/src}"

echo "Buscando llamadas a plot_nodal en: $ROOT_DIR"

# Mostrar coincidencias antes de modificar.
grep -RIn \
  --include='*.m' \
  -E '^[[:space:]]*plot_nodal[[:space:]]*\(.*\)[[:space:]]*;?[[:space:]]*$' \
  "$ROOT_DIR" || true

python3 - "$ROOT_DIR" <<'PY'
import re
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1])

# Solo reemplaza llamadas completas de una línea.
# No modifica líneas comentadas ni definiciones de funciones.
pattern = re.compile(
    r'^([ \t]*)plot_nodal[ \t]*(\([^;\n]*\))[ \t]*;?[ \t]*$'
)

modified_files = 0
replacements = 0

for path in root.rglob("*.m"):
    original = path.read_text(encoding="utf-8")
    output_lines = []
    file_replacements = 0

    for line in original.splitlines(keepends=True):
        newline = "\n" if line.endswith("\n") else ""
        content = line[:-1] if newline else line

        match = pattern.match(content)

        if not match:
            output_lines.append(line)
            continue

        indent = match.group(1)
        arguments = match.group(2)

        replacement = (
            f'{indent}if (!strcmpi(getenv("AOS_GRAPHICS_MODE"), "off"))\n'
            f'{indent}  plot_nodal{arguments};\n'
            f'{indent}else\n'
            f'{indent}  fprintf("Grafico nodal omitido: modo CLI.\\n");\n'
            f'{indent}endif{newline}'
        )

        output_lines.append(replacement)
        file_replacements += 1

    if file_replacements:
        backup = path.with_suffix(path.suffix + ".bak")

        if not backup.exists():
            shutil.copy2(path, backup)

        path.write_text("".join(output_lines), encoding="utf-8")

        modified_files += 1
        replacements += file_replacements

        print(f"MODIFICADO: {path} ({file_replacements} reemplazo/s)")

print()
print(f"Archivos modificados: {modified_files}")
print(f"Llamadas reemplazadas: {replacements}")
PY