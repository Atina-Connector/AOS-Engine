# AOS 0.0.11 — Manual de uso

## 1. Inicio

1. Descomprima la carpeta completa.
2. Abra GNU Octave.
3. Cambie a la carpeta raíz de AOS.
4. Ejecute:

```octave
AOS
```

AOS agrega sus rutas internas y abre el menú principal.

## 2. Verificación inicial

Antes de comenzar el benchmark ejecute una vez:

```octave
VERIFICAR_AOS_0_0_11
```

La rutina verifica:

- importación del pozo testigo;
- lectura de todos los bloques del `.aosdat`;
- carga automática de geología y punzados;
- exportación y reimportación sin pérdida de datos principales;
- conversiones de unidades;
- compatibilidad con `.aosdat` históricos;
- generación del gráfico de survey/punzados cuando hay toolkit gráfico.

## 3. Unidades

La interfaz trabaja con:

- presión: bar;
- profundidad/longitud: m;
- caudal de líquido: m³/d;
- gas producido o inyectado: Sm³/d;
- temperatura: °C;
- diámetro: mm o m según la variable.

Las referencias imperiales aparecen entre paréntesis. No ingrese presiones en Pa en los menús.

## 4. Importar un `.aosdat`

Desde el menú:

```text
12 - Exportar / Importar .aosdat / .aosrpt
 1 - Importar configuración desde .aosdat
```

Elija búsqueda estándar o navegación manual.

Al finalizar, AOS informa:

- cantidad de secciones preservadas;
- número de puntos del survey;
- estado de geología;
- cantidad de intervalos de punzado;
- benchmark cargado, si existe;
- caudal de gas configurado.

Todo el caso queda activo para los módulos. No es necesario volver a cargar survey, geología ni punzados desde otras opciones.

## 5. Contenido reconocido

AOS reconoce y preserva, entre otros:

```text
[AOS_DATA]
[CONFIG]
[POZO]
[FLUIDOS]
[TUBING]
[CASING]
[GL]
[JGL]
[BES]
[BM]
[INT1]
[BOMBEO_MECANICO]
[GEOLOGIA]
[SURVEY]
[PUNZADOS]
[ESTADO_MECANICO]
[BENCHMARK_PROSPER]
```

Las secciones futuras también se conservan en `aosdat_sections` aunque la versión actual todavía no las utilice en un solver.

## 6. Survey y punzados

Seleccione:

```text
9 - Visualizar survey y punzados
```

Si el `.aosdat` activo contiene survey, AOS lo usa automáticamente. Los punzados se muestran:

- resaltados sobre MD–TVD;
- resaltados sobre la trayectoria 3D;
- en un track dedicado con profundidad y tiros/m.

## 7. Geología

Si el `.aosdat` incluye `[GEOLOGIA]`, AOS la carga y la deja activa automáticamente.

La opción:

```text
10 - Cargar / editar geología manualmente
```

solo se necesita para reemplazarla o crearla cuando el archivo no contiene geología.

Los datos sintéticos o estimados quedan identificados en la estructura y no sustituyen una interpretación petrofísica real.

## 8. Simulación GL para el benchmark Supati

Carga rápida:

```octave
CARGAR_BENCHMARK_SUPATI_001
AOS
```

Luego seleccione:

```text
2 - Simular Gas Lift convencional
```

Use los valores cargados del `.aosdat` como defaults. El caso principal incluido contiene:

- IPR Vogel;
- VLP Duns & Ros;
- `Pwh = 29.971 bar (420 psi)`;
- profundidad de inyección `1945.4 m`;
- presión de burbuja `21.4 bar`;
- `Qiny = 19 333.61 Sm³/d (0.68276 MMscf/d)`.

Los valores PROSPER están guardados como referencia en `[BENCHMARK_PROSPER]`; no se usan para forzar la solución.

## 9. Exportar un `.aosdat`

Desde la opción 12 seleccione exportar configuración actual. La opción recomendada es **caso completo**.

El archivo nuevo utiliza unidades métricas explícitas y conserva:

- configuración;
- geología;
- survey;
- punzados;
- estado mecánico;
- Bombeo Mecánico;
- benchmark;
- secciones futuras preservadas.

## 10. Módulos existentes

El menú principal incluye:

1. Jet Gas Lift;
2. Gas Lift convencional;
3. BES;
4. Bombeo Mecánico;
5. sensibilidad JGL/GL;
6. sensibilidad BES;
7. diseño de mandriles;
8. calibración;
9. survey/punzados;
10. geología;
11. importación CSV;
12. intercambio `.aosdat` / `.aosrpt`;
13. configuración por defecto;
14. visor de reportes.

Cada módulo toma como base `CONFIG_ACTIVA`, por lo que los parámetros importados aparecen como valores por defecto de sus menús.

## 11. Alcance de JGL

AOS 0.0.11 mantiene el modelo JGL existente. No use el benchmark GL para calibrar artificialmente el eductor.

El siguiente desarrollo, AOS 0.0.12, implementará el acoplamiento iterativo continuo entre:

- reservorio/IPR;
- columna GL/VLP;
- eductor de fondo;
- energía y cantidad de movimiento;
- presión de succión y descarga;
- convergencia del punto operativo.
