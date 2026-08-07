# AOS 0.0.11 — Compilación Benchmark Ready

## 1. Propósito

Esta compilación deja AOS 0.0.11 preparado para ejecutar el benchmark del pozo testigo Supati X1 ST antes de comenzar el solver JGL acoplado de AOS 0.0.12.

No es un parche. Es el árbol completo del programa.

## 2. Convención de unidades

AOS usa el sistema métrico en toda interacción con el usuario y en los nuevos archivos `.aosdat`:

| Variable | Unidad AOS | Referencia secundaria |
|---|---:|---:|
| Presión | bar | psi entre paréntesis |
| Profundidad/longitud | m | ft entre paréntesis |
| Caudal de líquido/petróleo/agua | m³/d | bpd entre paréntesis |
| Gas producido/inyección | Sm³/d | MMscf/d entre paréntesis |
| Temperatura | °C | — |
| Diámetro | mm o m según el campo | pulgadas cuando corresponde |

El núcleo numérico puede conservar Pa y m³/s internamente. Esas unidades no se solicitan al usuario.

## 3. Importación integral de `.aosdat`

El importador ahora:

1. lee todas las secciones;
2. conserva todos los parámetros escalares en `aosdat_sections`;
3. normaliza aliases métricos y campos históricos;
4. deja el caso como `CONFIG_ACTIVA`;
5. carga automáticamente el survey;
6. carga automáticamente la geología cuando existe `[GEOLOGIA]`;
7. carga automáticamente los intervalos de `[PUNZADOS]`;
8. sincroniza punzados con `CONFIG_ACTIVA.punzados` y `geologia.intervalos` cuando corresponde;
9. carga estado mecánico y referencias de benchmark;
10. mantiene compatibilidad con archivos antiguos que usan Pa, K, m³/s o nombres heredados.

Las secciones futuras o desconocidas no se descartan: quedan preservadas para reexportación.

## 4. Geología automática

Cuando el `.aosdat` contiene `[GEOLOGIA]`, AOS la deja activa al importar el pozo. La opción 10 del menú sirve únicamente para reemplazarla o editarla manualmente.

Si el archivo contiene punzados pero no geología, los punzados se conservan y se muestran en el survey, pero AOS no inventa una geología completa.

## 5. Survey y punzados

La opción 9 del menú abre una figura con seis vistas:

1. trayectoria MD–TVD con intervalos de punzado resaltados;
2. inclinación;
3. diámetro interno de tubing;
4. trayectoria 3D con los tramos punzados;
5. track específico de punzados y densidad en tiros/m;
6. azimut y resumen de longitud/tiros.

## 6. Pozo testigo AOS-001

Archivo incluido:

```text
datos/ejemplos/benchmarks/SUPATI_X1_ST_BENCHMARK_AOS_001.aosdat
```

Contiene:

- parámetros métricos del caso;
- survey de 13 estaciones;
- cinco intervalos de punzado a 15 tiros/m;
- geología sintética identificada como análogo de prueba;
- estado mecánico disponible;
- referencias numéricas del informe PROSPER.

La geología sintética no debe tratarse como petrofísica medida.

## 7. Ejecución

Desde la raíz de AOS:

```octave
AOS
```

Para verificar la compilación:

```octave
VERIFICAR_AOS_0_0_11
```

Para cargar directamente el benchmark:

```octave
CARGAR_BENCHMARK_SUPATI_001
```

Después, ejecute `AOS` y seleccione Gas Lift convencional para el primer benchmark.

## 8. Alcance de JGL

Esta compilación no incorpora todavía el nuevo acoplamiento iterativo GL–eductor. Se preserva la física JGL existente en 0.0.11 para mantener trazabilidad.

AOS 0.0.12 tendrá como objetivo:

- solución continua, no discreta, entre comportamiento GL y Jet Lift;
- iteración GL/VLP ↔ eductor;
- balance de energía y cantidad de movimiento;
- restricciones físicas de presión motriz, intake y potencia;
- convergencia trazable sin resultados imposibles.

## 9. Estado de verificación

La distribución incluye pruebas automatizadas para GNU Octave. En el entorno usado para preparar este ZIP no había un ejecutable de Octave disponible; por eso se realizaron comprobaciones estáticas, validación estructural del benchmark y revisión del archivo comprimido. La ejecución de `VERIFICAR_AOS_0_0_11` en el equipo de trabajo completa la prueba de runtime.
