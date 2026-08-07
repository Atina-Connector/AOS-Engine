# AOS v13 - Semáforos operativos globales

## Principio

Los semáforos no son una decoración gráfica ni pertenecen solamente a BM. Son una capa común de lectura rápida para todos los módulos de AOS.

Deben aparecer en:

- consola de Octave;
- gráficos operativos cuando corresponda;
- `.aosrpt` liviano;
- `.aosrpt` enriquecido / Viewer.

## Estados

```text
🟢 [VERDE]     Operación preliminarmente normal
🟡 [AMARILLO]  Operación posible con precauciones
🔴 [ROJO]      Riesgo operativo alto o condición no aceptable
```

El estado entre corchetes es obligatorio porque algunos dispositivos viejos o mensajes de baja conectividad pueden no renderizar los símbolos Unicode.

## Alcance actual

La v13 genera semáforos para:

- JGL;
- GL convencional;
- BES;
- BM/Gibbs;
- diagnóstico común de tubería cuando está disponible.

## Regla para módulos futuros

Todo módulo nuevo debe devolver o permitir generar una estructura:

```text
sem.sistema
sem.general
sem.descripcion
sem.items(i).nombre
sem.items(i).estado
sem.items(i).mensaje
```

El Viewer no debe inferir estados desde texto libre; debe leer esta estructura o la sección `[SEMAFOROS]` del `.aosrpt`.
