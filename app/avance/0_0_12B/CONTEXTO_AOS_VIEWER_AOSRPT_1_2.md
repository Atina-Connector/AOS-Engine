# AOS Viewer — Contrato de intercambio `.aosrpt` 1.2

**Proyecto:** AOS — AESIR Oilfield Simulation  
**Versión emisora:** AOS 0.0.12B Viewer Ready  
**Entorno objetivo de AOS:** GNU Octave  
**Objetivo:** permitir que AOS Viewer reconstruya y muestre el pozo utilizando únicamente el `.aosrpt`, sin requerir el `.aosdat` original.

## 1. Decisión de arquitectura

El `.aosdat` define el caso de simulación. El `.aosrpt` representa una fotografía portable de la corrida y debe contener los datos necesarios para que el Viewer reconstruya el contexto geométrico y operativo.

Los dos formatos conservan la extensión `.aosrpt` y continúan siendo archivos de texto:

- **Ligero:** resultados, diagnósticos y tablas reconstruibles; no incluye imágenes.
- **Enriquecido:** contiene exactamente el mismo cuerpo de datos y agrega imágenes PNG codificadas en Base64.

No se requiere un segundo archivo para survey, punzados o tubing.

## 2. Pregunta de exportación

Después de elegir el tipo de reporte, AOS pregunta:

```text
Incluir survey, tubing, punzados y equipo de fondo? (s/n) [s]:
```

La respuesta predeterminada es **sí**.

- En el reporte ligero se incluyen los datos tabulares.
- En el enriquecido se incluyen los mismos datos y `survey_png_base64`.
- Si el usuario responde no, se conserva `[VIEWER_CONTEXT]` con `incluido=0` para que el Viewer distinga una exclusión voluntaria de la ausencia accidental de datos.

## 3. Identificación de versión

El encabezado incorpora:

```ini
[AOS_REPORT]
version=1.2
viewer_schema=AOS_VIEWER_CONTEXT_1.0
```

El Viewer debe usar `viewer_schema` para seleccionar el parser. Los lectores anteriores pueden ignorar las secciones desconocidas.

## 4. Sección `[VIEWER_CONTEXT]`

Define metadatos y convenciones:

```ini
[VIEWER_CONTEXT]
schema=AOS_VIEWER_CONTEXT_1.0
incluido=1
sistema=GL
unidades_profundidad=m
convencion_inclinacion=grados_desde_vertical
convencion_tvd=positiva_hacia_abajo
```

La inclinación sigue la convención petrolera de AOS: cero grados es vertical.

## 5. Sección `[SURVEY]`

Contiene una fila por estación:

```ini
[SURVEY]
estado=cargado
n_puntos=7
formato=idx,MD_m,TVD_m,inclinacion_deg,azimut_deg,ID_tubing_m,ID_casing_m,rugosidad_m
1,0.000000,0.000000,0.000000,0.000000,0.06200000,0.12000000,0.00001500
```

### Reglas para el Viewer

- La línea `formato=` es autoritativa respecto del orden de columnas.
- Los datos comienzan en la primera línea sin `=` posterior a `formato=` y terminan al comenzar otra sección.
- `NaN` significa dato no disponible.
- Debe preservarse MD como eje de referencia principal.
- TVD se dibuja positiva hacia abajo.
- El Viewer puede reconstruir X/Y a partir de MD, inclinación y azimut cuando corresponda.

## 6. Sección `[TUBING_PROFILE]`

Duplica de forma explícita la geometría necesaria para un track de completación:

```ini
[TUBING_PROFILE]
estado=cargado
n_puntos=7
formato=idx,MD_m,ID_tubing_m,ID_casing_m,rugosidad_m
```

El survey completo sigue siendo la fuente primaria. Esta sección simplifica el consumo por Viewer y permite evolucionar la geometría sin alterar el parser de trayectoria.

## 7. Sección `[PERFORATIONS]`

Contiene la geometría de los intervalos punzados, independientemente de la distribución productiva:

```ini
[PERFORATIONS]
estado=cargado
n_tramos=5
formato=idx,MD_desde_m,MD_hasta_m,TVD_desde_m,TVD_hasta_m
```

No debe confundirse con `[PUNZADOS_DISTRIBUIDOS]`, que contiene resultados de aporte por intervalo. El Viewer puede usar ambas:

- `[PERFORATIONS]`: posición física.
- `[PUNZADOS_DISTRIBUIDOS]`: aporte y diagnóstico productivo.

## 8. Sección `[DOWNHOLE_EQUIPMENT]`

Localiza el componente principal del SLA:

```ini
[DOWNHOLE_EQUIPMENT]
tipo=PUNTO_INYECCION_GL
estado=definido
MD_m=1903.700000
TVD_m=1890.400000
descripcion=Punto efectivo de inyeccion GL
```

Tipos iniciales:

- `PUNTO_INYECCION_GL`
- `EDUCTOR_JGL`
- `BOMBA_BES`
- `BOMBA_MECANICA`

El diseño admite agregar mandriles, packer, sensores y otros equipos mediante nuevas secciones en versiones futuras.

## 9. Imagen del survey en el reporte enriquecido

El reporte enriquecido agrega en `[GRAFICOS]`:

```ini
survey_estado=OK
survey_png_base64=<datos Base64>
```

La imagen contiene inicialmente:

- trayectoria MD–TVD;
- inclinación;
- perfil de ID de tubing;
- referencia visual de punzados cuando están disponibles;
- ubicación del equipo de fondo principal.

### Prioridad de datos

La imagen es una representación visual. Las tablas `[SURVEY]`, `[TUBING_PROFILE]`, `[PERFORATIONS]` y `[DOWNHOLE_EQUIPMENT]` son autoritativas.

El Viewer debe:

1. reconstruir el modelo desde las tablas;
2. mostrar la imagen embebida si existe;
3. regenerar una visualización propia si no existe o si el usuario solicita interacción.

## 10. Compatibilidad hacia atrás

El Viewer debe aceptar:

- reportes 1.0/1.1 sin contexto geométrico;
- reportes 1.2 con `incluido=0`;
- reportes 1.2 con survey pero sin imagen;
- reportes 1.2 enriquecidos con imagen.

Cuando no exista `[SURVEY]`, debe indicar “Survey no incluido en el reporte”, no “survey vacío”.

## 11. Importación dentro de AOS

AOS 0.0.12B también puede reconstruir `CONFIG_ACTIVA.survey` y `CONFIG_ACTIVA.punzados` desde las tablas embebidas al cargar un reporte. Esto permite usar el `.aosrpt` como expediente portable, aunque la simulación rigurosa debe conservar trazabilidad respecto del `.aosdat` original.

## 12. Seguridad y robustez del parser

El Viewer no debe ejecutar contenido del reporte. Debe tratar Base64 como datos y validar:

- tamaño máximo de imagen;
- número máximo razonable de estaciones;
- columnas declaradas por `formato=`;
- valores no finitos;
- orden creciente de MD;
- intervalos de punzados con base mayor o igual al tope.

## 13. Extensiones futuras previstas

El contrato puede evolucionar con secciones adicionales sin romper la versión 1.2:

```text
[PACKER]
[MANDRELS]
[CASING_PROFILE]
[SENSORS]
[PRESSURE_PROFILE]
[TEMPERATURE_PROFILE]
[ATTACHMENTS_MANIFEST]
```

La regla será: nuevas secciones son opcionales y los parsers deben ignorar las que no reconozcan.

## 14. Criterios de aceptación Viewer

1. Abrir un `.aosrpt` ligero 1.2 y reconstruir trayectoria, tubing, punzados y equipo.
2. Abrir un enriquecido y decodificar `survey_png_base64`.
3. Mostrar los mismos MD/TVD que AOS.
4. No requerir el `.aosdat` para visualizar el expediente.
5. Diferenciar ausencia, exclusión voluntaria y error de imagen.
6. Mantener compatibilidad con `.aosrpt` 1.0 y 1.1.
