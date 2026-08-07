# AOS 0.0.11c - Profundidad efectiva y punzados distribuidos

## Alcance

Este parche corrige dos problemas de la version Benchmark Ready:

1. Una profundidad de inyeccion editada en GL/JGL podia volver al valor original del `.aosdat` durante la normalizacion.
2. El reporte geologico trataba el caudal total como entrada concentrada en `midperf`, aunque existieran varios intervalos y tiros.

## Correccion de profundidad

- GL/JGL usan `D_iny` como profundidad canonica.
- BES/BM conservan `D_bomba` como profundidad canonica.
- La funcion `aos_set_profundidad` sincroniza aliases y estructuras internas.
- Los motores GL/JGL leen primero `D_iny`.
- Las sensibilidades GL/JGL usan la misma profundidad.
- El menu imprime profundidad solicitada y profundidad efectiva del solver.
- Los aliases de inyeccion ya no pisan una profundidad de bomba explicita de BES/BM.

## Correccion de punzados

- El caudal se distribuye entre todos los tramos y tiros activos.
- Con propiedades uniformes se reparte proporcionalmente al numero de tiros.
- Si existen permeabilidad y skin por tramo, usa transmisibilidad relativa.
- Se reportan Ql, Qo, Qw y caudal por tiro para cada intervalo.
- `midperf` queda solo como referencia geometrica.
- El calculo de erosion sigue sumando la capacidad de todos los tiros.

## Modulos auditados

- GL y JGL: afectados directamente y corregidos.
- Sensibilidades GL/JGL: afectadas por aliases historicos y corregidas.
- BES y BM: usan una profundidad con significado distinto; el parche evita que `D_iny` las sobrescriba.
- Geologia/reportes: aporte distribuido por intervalos y tiros.

## Prueba

En Octave:

```octave
test_parche_0_0_11c_profundidad_punzados
```
