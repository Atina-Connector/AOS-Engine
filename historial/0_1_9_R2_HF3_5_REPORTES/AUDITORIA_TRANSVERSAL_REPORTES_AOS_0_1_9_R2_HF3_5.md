# Auditoria transversal de reportes AOS 0.1.9 R2 HF3.5

## Objetivo

Incorporar una unica capa de composicion para todos los modulos que generan
reportes con tablas, incluyendo simulaciones, disenos, comparaciones,
sensibilidades y AOSCAD.

La necesidad fue confirmada por el reporte BM de SUP-X1 ST: su manifiesto
informaba cero tablas y cero graficos, aunque el documento contenia una Carta
Gibbs de 721 puntos y numerosas tablas adicionales. HF3.5 corrige la fuente del
manifiesto y evita que una tabla extensa se imprima obligatoriamente.

## Regla de integridad

La composicion del documento no modifica la corrida. Todas las tablas se
preservan completas. El usuario decide solamente su presentacion:

- `FULL_BODY`
- `SUMMARY`
- `SAMPLED`
- `FULL_APPENDIX`
- `VIEWER_ONLY`
- `EXCLUDED_EXPORT`

Los modos `SUMMARY`, `SAMPLED`, `VIEWER_ONLY` y `EXCLUDED_EXPORT` conservan la
tabla completa en el archivo interno del `.aosrpt`. En `.aoscad`, las tablas
originales permanecen en el JSON canonico.

## Perfiles

- Ejecutivo
- Tecnico
- Auditoria completa
- Personalizado, tabla por tabla

Las tablas de sensibilidad son resultados primarios y se proponen completas en
todos los perfiles. El usuario puede cambiar la decision en el modo
personalizado.

## Cobertura integrada

- exportacion generica `.aosrpt` simple y enriquecida;
- dispatcher transversal de informes;
- BM y Gibbs Foundation 3;
- BES V2;
- BES3 y comparacion encendida/apagada;
- CGF y EGF;
- diseno de mandriles;
- sensibilidades historicas y transversales;
- reportes graficos genericos;
- AOSCAD simple y enriquecido;
- importacion y lectura de tablas nativas.

Los modulos futuros pueden registrar tablas mediante `param.aosrpt_tablas` o
`contexto.report_tables` sin crear otro sistema de seleccion.

## Contrato de archivo

- `[REPORT_MANIFEST]` schema `AOS_REPORT_MANIFEST_1.1`;
- `[REPORT_COMPOSITION]`;
- `[TABLE_PRESENTATION_<id>]`;
- `[TABLE_INDEX]` y `[TABLE_###]` para salida visible;
- `[TABLE_ARCHIVE_INDEX]` y `[TABLE_ARCHIVE_###]` para datos completos que no
  deben ocupar paginas;
- `full_data_policy=ALWAYS_PRESERVE`.

## Compatibilidad

Los reportes historicos continúan siendo legibles. El importador evita que las
secciones nuevas sean reconstruidas como configuracion del caso. El Viewer
actual debe ser validado por su equipo para mostrar `TABLE_ARCHIVE_*` como datos
consultables sin renderizarlos automaticamente en PDF.

## No modificado

No se modificaron ecuaciones, correlaciones, solvers, resultados numericos,
Survey, geologia, punzados, DXF, STEP, `.aosdat`, AOSBCK ni la fisica de GF3.

## Estado de validacion

La construccion fue auditada estaticamente y el parche fue aplicado en una
copia limpia de HF3.4 para comparar el resultado archivo por archivo. La
campana dinamica final debe ejecutarse en GNU Octave, que no esta disponible en
el entorno de construccion.
