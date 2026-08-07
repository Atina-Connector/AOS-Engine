# Contrato transversal de composicion de tablas AOS HF3.5

## Principio

Los datos calculados no se eliminan por una decision de presentacion. Todas las
tablas quedan dentro del `.aosrpt` o, en AOSCAD, dentro del JSON canonico. La
composicion controla solamente que objetos se renderizan en el cuerpo, anexo o
quedan disponibles para AOS Viewer y exportacion de datos.

## Perfiles

- `EXECUTIVE`: resumen, resultados primarios y tablas pequenas.
- `TECHNICAL`: resultados principales, tablas tecnicas y anexos moderados.
- `AUDIT`: tablas completas, enviando las extensas a anexos.
- `CUSTOM`: decision individual para cada tabla.

Las tablas de sensibilidades son resultados primarios y se proponen completas
en todos los perfiles. El usuario puede cambiar su modo en `CUSTOM`.

## Modos de presentacion

- `FULL_BODY`: tabla completa en el cuerpo.
- `SUMMARY`: resumen visible y tabla completa archivada.
- `SAMPLED`: muestra trazable visible y tabla completa archivada.
- `FULL_APPENDIX`: tabla completa en anexo.
- `VIEWER_ONLY`: no se renderiza en el documento; queda completa para datos.
- `EXCLUDED_EXPORT`: no se muestra en esa exportacion, pero se preserva.

## Secciones del archivo

- `[REPORT_COMPOSITION]`: perfil y contadores reales.
- `[TABLE_PRESENTATION_<id>]`: decision de presentacion por tabla.
- `[TABLE_INDEX]` y `[TABLE_###]`: tablas visibles o anexos.
- `[TABLE_ARCHIVE_INDEX]` y `[TABLE_ARCHIVE_###]`: datos completos que no deben
  ocupar paginas en la exportacion visible.

AOS Viewer debe construir el menu desde `TABLE_INDEX` y ofrecer las tablas de
`TABLE_ARCHIVE_INDEX` en un grupo de datos o bajo la tabla visible relacionada,
sin renderizarlas automaticamente en PDF.

## Regla de integridad

`full_data_policy=ALWAYS_PRESERVE`. Una tabla omitida del PDF sigue disponible
para Viewer, auditoria, CSV y nueva exportacion sin recalcular.
