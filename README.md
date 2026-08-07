# AOS Suite

Plataforma modular en GNU Octave para optimización de levantamiento
artificial y producción de pozos (Gas Lift/JGL, BES, Bombeo Mecánico, PCP,
CGF, EGF, redes, CAD/topología, geología, ambiental, etc.), desarrollada por
AESIR Oilfield Systems. Ver `app/README.md` y `app/CLAUDE.md` para la
arquitectura del código en sí.

## Estructura del repositorio

```
app/            Código AOS (Octave) — ver docs/distribution/REPOSITORY_LAYOUT.md
docker/         Desarrollo y testing en contenedor (no lo usa el usuario final)
packaging/      Empaquetado de distribución Windows (en construcción)
tools/          Scripts auxiliares de repo
runtime/        Datos mutables de desarrollo local (gitignorado)
build/ dist/    Artefactos de build/release (gitignorados)
docs/           Documentación de arquitectura y distribución
```

Ver `docs/distribution/REPOSITORY_LAYOUT.md` para el detalle completo y la
justificación de esta organización.

## Desarrollo (Docker)

```bash
docker compose -f docker/docker-compose.yml up -d
./docker/aos run       # AOS interactivo
./docker/aos verify    # VERIFICAR_AOS_0_2_0_DEV1
./docker/aos shell     # shell dentro del contenedor
```

Esto sigue siendo el flujo de referencia para desarrollo/testing en
Mac/Linux. No requiere ni afecta el flujo de distribución Windows descripto
abajo.

## Distribución Windows (en construcción)

El objetivo es entregar `AOS-Setup-<version>.exe` (y un
`AOS-Portable-<version>-win-x64.zip` para QA) que instalen y corran AOS en
Windows 10/11 sin que el usuario instale Octave, Docker, WSL, Python ni Git.
Todavía no está implementado — ver `packaging/windows/README.md` y
`docs/distribution/` para el diseño ya acordado de cada pieza (runtime
Octave portable, launcher `AOS.exe`, instalador Inno Setup, CI en GitHub
Actions).
