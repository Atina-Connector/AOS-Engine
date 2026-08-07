# Layout del repositorio AOS

## Por qué se unificó

Hasta la migración de agosto de 2026, `app/` (el código Octave de AOS) tenía
su propio repositorio Git, y todo lo de Docker/packaging vivía un nivel por
encima sin ningún control de versiones. Eso hacía imposible tener un único
historial, un único `.gitignore` y un pipeline de CI que viera todo el árbol
a la vez. Se unificó en un solo repo en la raíz, preservando el historial de
`app/` sin reescribir sus commits (ver sección "Migración de historial" más
abajo).

## Árbol

```
.
├── app/                        Código AOS (Octave). Ver detalle abajo.
├── docker/                     Dockerfile, docker-compose.yml y wrappers
│                                (aos, aos-internal) para desarrollo/testing.
│                                No lo usa el usuario final de Windows.
├── packaging/
│   └── windows/                Runtime Octave portable, launcher AOS.exe e
│                                instalador Inno Setup. Ver
│                                packaging/windows/README.md.
├── tools/                      Scripts auxiliares de repo que no forman
│                                parte del path de Octave de app/ ni de
│                                Docker (p. ej. replace_plot_nodal.sh).
├── runtime/                    Datos mutables de desarrollo/testing local
│                                con Docker (bind-mounts). Gitignorado.
├── build/                      Artefactos intermedios de build. Gitignorado.
├── dist/                       Instaladores/ZIP finales. Gitignorado.
├── docs/distribution/          Esta documentación.
└── .github/workflows/          CI (pendiente, ver RELEASE_PROCESS.md).
```

## `app/` — qué hay adentro

`app/` es exactamente el contenido histórico del repo original de AOS, sin
reorganizar. Contiene tanto lo necesario en runtime (`AOS.m`, `src/`,
`config/`, `datos/`) como documentación, auditorías históricas y tests que
NO se distribuyen a un usuario final de Windows. La clasificación completa
(qué entra en el instalador y qué no) vive en el plan de distribución
Windows; en resumen:

- **Va al instalador:** `AOS.m`, `VERSION`, `AOS_VERSION.txt`, `src/` (menos
  `src/docs`, `src/tests`, `src/diagnosticos/legacy`), `config/`, `datos/`.
- **Va al instalador como plantilla semilla** (después reemplazada por
  junctions hacia `Documents\AOS\`): `datos_usuario/`, `intercambio/`.
- **No va al instalador** (pero sigue en el repo/Docker): `herramientas/`,
  `tests/`, `ejemplos/` (top-level), `documentos/`, `src/docs/`,
  `historial/`, `avance/`, y todos los `AUDITORIA_*`, `CHANGELOG_*`,
  `HISTORIAL_*`, `MANIFEST_*`, `SHA256SUMS_*`, `REGRESIONES_*`,
  `INSTRUCCIONES_*`, `VERIFICAR_*` (excepto el vigente
  `VERIFICAR_AOS_0_2_0_DEV1.m`, que se usa en CI/smoke test pero tampoco se
  instala en `Program Files`), `DIAGNOSTICAR_*`.

Nada de esto se borró del repositorio: la distribución Windows simplemente
no copia esas rutas al instalador.

## Versión canónica

`app/VERSION` (hoy `0.2.0-DEV1`) es la única fuente que leen los scripts de
build/CI para nombrar artefactos (`AOS-Setup-0.2.0-dev1.exe`, etc.). No hay
un `VERSION` separado en la raíz del repo — evita mantener el mismo dato en
dos lugares a mano. `app/AOS_VERSION.txt` sigue existiendo tal cual estaba:
es un texto descriptivo que Octave lee en tiempo de ejecución
(`aos_version_actual.m`) para mostrarle la versión al usuario; cumple un rol
distinto (texto para humanos, no un identificador de build) y no se tocó.

## Migración de historial

`app/` tenía 4 commits, un solo branch (`master`), sin remotes ni tags. Se
importaron al repo unificado con `git subtree add --prefix=app`, que **no
reescribe los commits originales** (conservan sus hashes:
`6e30520`, `43857d6`, `5d38903`, `bfb9895`) — quedan como ancestros de un
commit de merge (`Merge AOS app history into app/ subdirectory`). Se
prefirió esto sobre `git filter-repo --to-subdirectory-filter`, que habría
logrado el mismo resultado final pero generando nuevos hashes para esos 4
commits. `git log -- app/AOS.m` no atraviesa el merge por la simplificación
de historial por defecto de Git; para ver la historia real de un archivo
anterior a la migración hay que mirar los commits originales directamente
(`git log <hash> -- AOS.m`, con el path sin el prefijo `app/`).
