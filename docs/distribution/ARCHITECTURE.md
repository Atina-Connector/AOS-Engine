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
   `PATH` del usuario ni variables de entorno globales. También fija
   `AOS_GRAPHICS_MODE=file` antes de lanzar Octave (ver "Paridad con
   Docker" abajo) para que no se abran ventanas de gráficos.
4. **`packaging/windows/installer/AOS.iss`** (Inno Setup) empaqueta las
   tres piezas de arriba. Tiene dos partes no triviales en `[Code]`:
   - Post-install migra el contenido semilla de `app\datos_usuario` y
     `app\intercambio` a `Documents\AOS\` la primera vez, y deja esas dos
     carpetas dentro de la instalación como junctions NTFS hacia esa
     ubicación real — el mismo modelo mental que ya usan los bind-mounts de
     `docker/docker-compose.yml`, pero sin ningún cambio en el código
     Octave (que ya asume rutas relativas tipo
     `fullfile('intercambio', ...)` confiando en que `AOS.m` hizo
     `cd(root_dir)` al arrancar).
   - También resetea el `LastWriteTime` de todo `app\` al momento de la
     instalación (ver "Advertencias de timestamp" abajo), antes de crear
     las junctions para no tocar nunca el dato real del usuario.

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

**Modo gráfico:** Docker queda en CLI puro de forma estructural (el
contenedor no tiene display en absoluto, más `GNUTERM=dumb` en
`docker-compose.yml`), no porque `AOS_GRAPHICS_MODE=off` (el valor que de
hecho está seteado ahí) dispare la lógica de `AOS.m` — esa lógica compara
contra el string `"file"`, no `"off"`, así que en Docker ese chequeo nunca
se ejercita realmente. El runtime de Octave para Windows sí trae Qt/GUI
completo, así que sin pedir explícitamente el modo headless abriría
ventanas de gráficos reales. `aos_launcher.c` fija `AOS_GRAPHICS_MODE=file`
(el valor que `AOS.m` sí reconoce) antes de invocar Octave, logrando el
mismo resultado de punta a punta (nunca se abre una ventana, los gráficos
que se exportan a archivo siguen generándose) sin tocar `AOS.m` ni el
`docker-compose.yml` existente.

## Advertencias de timestamp ("time stamp for '...' is in the future")

Octave compara el `mtime` de cada `.m` contra el reloj de la máquina que lo
ejecuta. Los archivos que llegan al instalador conservan el `mtime` del
checkout en el runner de GitHub Actions; si el reloj de la máquina de
destino está atrasado respecto a ese momento (frecuente en VMs recién
creadas, clonadas de una imagen, o sin sincronización horaria), Octave
marca esos archivos como "del futuro" en cada arranque — es sólo
cosmético, no cambia ningún resultado. `AOS.iss` lo resuelve reseteando el
`LastWriteTime` de todo `app\` al momento de la instalación, usando el
reloj local de esa misma máquina (nunca puede quedar en el futuro respecto
de sí misma). Si el problema persiste después de instalar, es señal de que
el reloj del sistema sigue mal configurado — vale la pena confirmarlo
aparte (`Configuración → Hora e idioma → Sincronizar ahora`).

## Límite conocido: `input()` de Octave no funciona contra un pipe en Windows

Confirmado en una máquina real: si a `octave-cli.exe` (o a `AOS.exe`) se lo
arranca con stdin redirigido a un pipe anónimo (como hace
`System.Diagnostics.Process` con `RedirectStandardInput=$true`, el patrón
que usaría cualquier intento de automatizar la navegación del menú), la
primera llamada a `input()`/`aos_leer_opcion` falla con
`error: input: reading user-input failed!` — sin importar que ya se le
haya escrito algo al pipe. No es un bug de AOS ni del launcher: el resto
del arranque (`AOS.exe` localiza Octave y `AOS.m`, carga todo `src/`, e
imprime el menú principal completo) funciona perfecto hasta ese punto
exacto, confirmando que el problema es específicamente la lectura
interactiva contra un stdin no-tty en Windows, no el arranque en sí.

Por esto `smoke-test.ps1` no intenta navegar el menú de punta a punta por
automatización — sólo valida que el arranque llega hasta imprimir el
primer prompt sin error. La navegación interactiva real (importar, simular,
exportar, salir) se prueba a mano contra una consola real, ver el
checklist de `WINDOWS_INSTALLER.md`.

## Qué NO hace esta arquitectura (todavía)

- No compila nada de AOS a C++/`.oct` — los `.m` fuente viajan tal cual en
  `app\`.
- No firma digitalmente `AOS.exe` ni `AOS-Setup.exe` (ver
  `RELEASE_PROCESS.md`, sección de code signing).
- No hay auto-update.
- No recorta el runtime de Octave (se distribuye completo, ~800 MB
  descomprimido) — es una optimización de tamaño diferida a después de
  validar el piloto en Windows real.
