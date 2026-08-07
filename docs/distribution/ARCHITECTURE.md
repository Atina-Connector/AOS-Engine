# Arquitectura de distribución AOS

Estado: código implementado (Fases 3–4 del plan de distribución), **sin
validar todavía en una máquina Windows real**. Ver
`docs/distribution/WINDOWS_BUILD.md` y `WINDOWS_INSTALLER.md` para los
checklists de prueba obligatorios antes de confiar en esto.

## Layout instalado

```
C:\Program Files\AOS\
├── AOS.exe                          launcher nativo (Win32 C)
├── runtime\octave\
│   └── mingw64\bin\octave-cli.exe   runtime portable de GNU Octave 8.4.0
└── app\
    ├── AOS.m  VERSION  AOS_VERSION.txt
    ├── src\  config\  datos\
    ├── datos_usuario\               junction -> Documents\AOS\datos_usuario
    └── intercambio\                 junction -> Documents\AOS\intercambio

%USERPROFILE%\Documents\AOS\
├── datos_usuario\   (dato real del usuario, sembrado la primera vez)
├── intercambio\     (idem, incluye los DXF/STEP/.aoscad de ejemplo)
├── salida\          (vacía; ningún .m la referencia hoy, ver más abajo)
└── logs\            (idem)
```

## Cómo encajan las piezas

1. **`packaging/windows/scripts/prepare-octave-runtime.ps1`** descarga
   `octave-8.4.0-w64.7z` (misma versión que `docker/Dockerfile`, ver
   "Paridad con Docker" abajo), verifica su SHA-256 contra un hash pinneado
   en el propio script, y lo extrae completo (sin recortar toolchains
   alternativos como `clang64`/`ucrt64`/`mingw32` — se prefirió no adivinar
   qué es seguro borrar sin poder probarlo en Windows real) en
   `build\windows\runtime\octave\`.
2. **`packaging/windows/scripts/stage-app.ps1`** copia de `app/` sólo lo
   `RUNTIME_REQUIRED` (ver `REPOSITORY_LAYOUT.md`) a `build\windows\app\`,
   como lista blanca explícita, no por patrón de exclusión. Genera
   `build\windows\app-manifest.txt` con la lista exacta de archivos.
3. **`packaging/windows/launcher/aos_launcher.c`** (compilado por
   `launcher/build.ps1` con MSVC) es `AOS.exe`. Ubica
   `runtime\octave\mingw64\bin\octave-cli.exe` y `app\AOS.m` en forma
   relativa a su propia carpeta (`GetModuleFileNameW`), y los invoca con
   `CreateProcessW` heredando la consola actual — sin redirigir stdio a
   mano, sin `CREATE_NEW_CONSOLE`. Esto es lo que permite que `AOS.exe`
   funcione igual desde un acceso directo, `cmd` o PowerShell, sin tocar el
   `PATH` del usuario ni variables de entorno globales.
4. **`packaging/windows/installer/AOS.iss`** (Inno Setup) empaqueta las
   tres piezas de arriba. Su parte no trivial es el `[Code]` post-install:
   migra el contenido semilla de `app\datos_usuario` y `app\intercambio` a
   `Documents\AOS\` la primera vez, y deja esas dos carpetas dentro de la
   instalación como junctions NTFS hacia esa ubicación real — el mismo
   modelo mental que ya usan los bind-mounts de
   `docker/docker-compose.yml`, pero sin ningún cambio en el código Octave
   (que ya asume rutas relativas tipo `fullfile('intercambio', ...)`
   confiando en que `AOS.m` hizo `cd(root_dir)` al arrancar).

## Por qué `salida\` y `logs\` no son junctions

El `Dockerfile` crea `/opt/aos/salida` y `/opt/aos/logs` a nivel raíz, pero
al auditar el código (`grep` sobre todo `src/`) el único lugar que usa esos
nombres es `src/modulos/scada/aos_scada_rutas.m`, y ahí son subcarpetas de
`intercambio/scada/salida` e `intercambio/scada/logs` — ya cubiertas por la
junction de `intercambio`. No hay ningún `.m` que lea o escriba
`app\salida` o `app\logs` a nivel raíz. El instalador igual crea
`Documents\AOS\salida` y `Documents\AOS\logs` vacías (sin junction, porque
no hay nada del lado de `app\` para vincular) para cumplir el layout de
carpetas pedido y dejarlas visibles en el Explorador para uso futuro.

## Paridad con Docker

`docker/Dockerfile` instala Octave 8.4.0 (paquete `octave` de Ubuntu
24.04). Se pinneó la misma versión para Windows exactamente para que el
comportamiento de AOS no dependa de qué build de Octave se está usando —
cualquier diferencia de resultados entre Docker y Windows sería un bug real
a investigar, no una diferencia de versión esperada. Si en el futuro se
actualiza la versión de Octave en el Dockerfile, hay que agregar el hash
correspondiente a `$KnownHashes` en `prepare-octave-runtime.ps1` y
actualizar el default de `-Version`.

## Qué NO hace esta arquitectura (todavía)

- No compila nada de AOS a C++/`.oct` — los `.m` fuente viajan tal cual en
  `app\`.
- No firma digitalmente `AOS.exe` ni `AOS-Setup.exe` (ver
  `RELEASE_PROCESS.md`, sección de code signing).
- No hay auto-update.
- No recorta el runtime de Octave (se distribuye completo, ~800 MB
  descomprimido) — es una optimización de tamaño diferida a después de
  validar el piloto en Windows real.
