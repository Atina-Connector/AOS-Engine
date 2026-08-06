# AOS 0.0.11d - Geologia distribuida y zoom de punzados

## Alcance

- Distribuye Ql, Qo y Qw entre todos los intervalos y tiros activos.
- `midperf` queda solo como referencia geometrica.
- Para geologia uniforme, el aporte se reparte por cantidad de tiros.
- Si existen permeabilidad y skin por tramo, usa transmisibilidad relativa.
- Arenamiento, conificacion y erosion se informan tambien por intervalo.
- El `.aosrpt` liviano guarda solo datos de distribucion, sin graficos.
- El `.aosrpt` enriquecido agrega el grafico de aporte por profundidad.
- El plot de survey conserva la trayectoria completa y agrega un track con zoom automatico sobre la zona punzada.

## Regla de ingenieria

La produccion no puede evaluarse como si ingresara por un unico punto o una sola perforacion cuando existen varios intervalos y tiros activos.
