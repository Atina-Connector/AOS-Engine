# Instalador Windows — instructivo de prueba

`packaging/windows/installer/AOS.iss` (Inno Setup 6) está implementado pero
**nunca se ejecutó en una máquina Windows real**. Todo lo que sigue es la
prueba manual obligatoria antes de considerar esto confiable — no alcanza
con que `windows-build.yml` termine en verde (eso sólo prueba que
compila).

## Qué máquina usar

Una VM limpia de Windows 10 o 11 de 64 bits, **sin** Octave, Docker, WSL,
Python, Git, ni Visual C++ Redistributable preinstalados — si se instala
sobre una máquina de desarrollo que ya tiene todo eso, la prueba no dice
nada sobre si un usuario final real puede instalarlo. Opciones prácticas:
una VM local (Hyper-V/VirtualBox/Parallels con una ISO de evaluación de
Windows), o una VM de nube (Azure/AWS) descartable.

## 1. Conseguir el instalador

Cualquiera de las dos opciones de `WINDOWS_BUILD.md`: bajar
`AOS-Setup-<version>.exe` de los artifacts de GitHub Actions, o compilarlo
localmente. Copiarlo a la VM de prueba.

## 2. Instalación limpia

- [ ] Ejecutar `AOS-Setup-<version>.exe`. Debe pedir elevación (UAC) — es
  esperado, instala en Program Files.
- [ ] El wizard muestra nombre y versión de AOS correctamente.
- [ ] Dejar todo por default (ruta `C:\Program Files\AOS`) y completar.
- [ ] Verificar que existan:
  - `C:\Program Files\AOS\AOS.exe`
  - `C:\Program Files\AOS\runtime\octave\mingw64\bin\octave-cli.exe`
  - `C:\Program Files\AOS\app\AOS.m`
- [ ] Verificar que **no** haya quedado nada suelto en
  `C:\Program Files\AOS\app\datos_usuario` ni `...\intercambio` como
  carpeta real — deben verse como junction. Confirmar con:
  ```
  dir "C:\Program Files\AOS\app" 
  ```
  (las junctions se listan con `<JUNCTION>` en vez de `<DIR>`).
- [ ] Confirmar que `%USERPROFILE%\Documents\AOS\datos_usuario` y
  `...\intercambio` existen y tienen el contenido semilla (por ejemplo
  `intercambio\cad\recibidos\demo_aos_wells.dxf`).
- [ ] Confirmar que `%USERPROFILE%\Documents\AOS\salida` y `...\logs`
  existen (vacías).

## 3. Arranque sin herramientas de desarrollo

- [ ] En una terminal (cmd o PowerShell, **no** elevada), sin agregar nada
  al PATH manualmente:
  ```
  "C:\Program Files\AOS\AOS.exe"
  ```
  Debe mostrar el menú principal de AOS (`AOS SUITE 0.2.0 DEV1 - ...`).
- [ ] Confirmar que responde a la interacción normal: elegir una opción del
  menú, volver, etc.
- [ ] Salir con `0`, confirmar con `s`. `AOS.exe` debe devolver el control a
  la terminal (`echo %ERRORLEVEL%` en cmd, o `$LASTEXITCODE` en PowerShell,
  debería ser `0`).
- [ ] Repetir haciendo doble clic en el acceso directo del menú inicio (y,
  si se marcó esa opción durante la instalación, en el del escritorio). Debe
  abrir una consola nueva con el mismo menú.
- [ ] Confirmar que la máquina **no tiene** Octave, Docker, WSL, Python ni
  Git instalados y aun así todo lo anterior funcionó.

## 4. Flujo real: importar, calcular, exportar

- [ ] Desde el menú, importar un `.aosdat` de ejemplo (hay casos en
  `C:\Program Files\AOS\app\datos\ejemplos\`) y dejarlo activo.
- [ ] Correr una simulación simple (por ejemplo Gas Lift/JGL con los
  valores por defecto del caso importado).
- [ ] Generar un reporte `.aosrpt` desde el menú de reportes, apuntando a
  la carpeta estándar (`intercambio/reportes/enviados`).
- [ ] Confirmar que el archivo generado aparece en
  `%USERPROFILE%\Documents\AOS\intercambio\reportes\enviados\` — visible
  directamente desde el Explorador de Windows, sin tener que buscarlo
  dentro de Program Files.
- [ ] Si el módulo generó algún gráfico, confirmar que se ve una ventana de
  gráfico real (el build de Windows de Octave trae Qt/GUI, a diferencia del
  Octave headless de Docker) o que el archivo de imagen se generó
  correctamente si el flujo es a archivo.

## 5. Upgrade

- [ ] Con la instalación anterior todavía en pie y con datos reales ya
  generados en `Documents\AOS`, instalar de nuevo `AOS-Setup-<version>.exe`
  (misma versión u otra).
- [ ] El instalador debe reconocerlo como upgrade (mismo `AppId`), no crear
  una instalación paralela.
- [ ] Confirmar que **no se perdió** el contenido de `Documents\AOS`
  generado en el paso 4 (el `.aosrpt` exportado debe seguir estando ahí).
- [ ] Confirmar que `app\datos_usuario` y `app\intercambio` siguen siendo
  junctions hacia el mismo `Documents\AOS` de antes (no junctions rotas, no
  carpetas reales nuevas pisando el link).

## 6. Desinstalación

- [ ] Desinstalar desde "Aplicaciones y características" o el acceso
  directo "Uninstall AOS" del menú inicio.
- [ ] Confirmar que `C:\Program Files\AOS\` desaparece por completo.
- [ ] **Crítico:** confirmar que `%USERPROFILE%\Documents\AOS\` (con todo
  su contenido, incluido el `.aosrpt` generado en el paso 4) **sigue
  existiendo intacto** después de desinstalar. Este es el punto que más
  puede fallar silenciosamente si la lógica de las junctions tiene un bug
  — revisar con cuidado antes de dar por bueno el instalador.

## 7. Instalación silenciosa (opcional, para automatizar pruebas futuras)

- [ ] `AOS-Setup-<version>.exe /VERYSILENT /SUPPRESSMSGBOXES` instala sin
  mostrar UI. Repetir los checks del punto 2.

## Qué hacer si algo falla

Cada fallo apunta a un archivo concreto:

| Síntoma | Revisar |
|---|---|
| El instalador no abre / error de Inno Setup | `packaging/windows/installer/AOS.iss`, sección `[Setup]` |
| `AOS.exe` no encuentra Octave o `AOS.m` | `packaging/windows/launcher/aos_launcher.c` (resolución de rutas) |
| `AOS.exe` requiere instalar algo (VC++ Redistributable) | `packaging/windows/launcher/build.ps1` (falta `/MT`) |
| Las carpetas de usuario no son junctions, o son carpetas reales | sección `[Code]` de `AOS.iss`, `MigrateToUserDataAndLink` |
| Desinstalar borró `Documents\AOS` | sección `[Code]` de `AOS.iss`, `RemoveJunctionSafely` / `CurUninstallStepChanged` |
| Octave arranca pero AOS no encuentra `config/`/`datos/` | `packaging/windows/scripts/stage-app.ps1` (puede faltar algo en la lista blanca) |

Reportar cualquier hallazgo de esta prueba para ajustar el código antes de
considerar el piloto listo para un usuario de prueba real.
