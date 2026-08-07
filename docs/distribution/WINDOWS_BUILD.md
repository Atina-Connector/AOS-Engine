# Cómo generar un build de Windows (pendiente)

Este documento va a cubrir, una vez implementada la Fase 3/5:

- cómo correr `packaging/windows/scripts/prepare-octave-runtime.ps1`
  localmente en una VM/máquina Windows para armar `runtime/octave/`;
- cómo compilar el launcher `AOS.exe` (MSVC Build Tools);
- cómo disparar manualmente `.github/workflows/windows-build.yml`
  (`workflow_dispatch`) desde GitHub y descargar los artifacts resultantes
  (`AOS-Portable-<version>-win-x64.zip`, `AOS-Setup-<version>.exe`) sin
  necesitar una PC Windows física para cada release;
- requisitos previos (repo con remote de GitHub configurado — todavía no
  existe uno).

Se redacta con contenido real cuando exista el workflow correspondiente.
