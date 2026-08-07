# installer/

`AOS.iss` (Inno Setup 6). Implementado, sin validar todavía en una máquina
Windows real — ver `docs/distribution/WINDOWS_INSTALLER.md` para el
checklist de prueba manual, que es obligatorio antes de confiar en esto.

Qué hace:

- Instala en `Program Files\AOS\` (`AOS.exe`, `runtime\`, `app\`), con
  `AppId` fijo para que Inno Setup reconozca upgrades en vez de instalar en
  paralelo.
- Después de copiar los archivos, migra el contenido semilla de
  `app\datos_usuario` y `app\intercambio` a
  `%USERPROFILE%\Documents\AOS\...` (solo la primera vez; en upgrades
  respeta el dato real ya existente del usuario) y reemplaza esas dos
  carpetas dentro de la instalación por junctions NTFS (`mklink /J`) —
  mismo modelo mental que los bind-mounts de `docker/docker-compose.yml`,
  sin tocar ningún código Octave. `salida\` y `logs\` se crean vacías en
  `Documents\AOS\` (ver `docs/distribution/REPOSITORY_LAYOUT.md`: hoy
  ningún `.m` las referencia por ruta relativa, así que no necesitan
  junction, solo existir para el layout de carpetas pedido).
- Al desinstalar, saca las junctions (`rmdir` sin `/s`, que borra sólo el
  punto de unión) **antes** de que Inno Setup intente borrar los archivos
  que recuerda haber instalado — así nunca borra a través de la junction
  hacia el dato real del usuario en `Documents\AOS`.
- Crea acceso directo (menú inicio + escritorio opcional), soporta
  instalación silenciosa (`/VERYSILENT`) y Windows 10/11 de 64 bits.

La versión se inyecta desde CI con `/DAOSVersion=<version>` (leída de
`app/VERSION`); no hay una versión hardcodeada de verdad en el `.iss`.
