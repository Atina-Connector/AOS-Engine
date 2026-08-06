# AOS 0.1.9 R2 HF3.5

## Composicion transversal de tablas

HF3.5 separa los datos calculados de su presentacion en el documento. Toda
tabla se conserva y el usuario decide si se imprime completa, resumida,
muestreada, como anexo o solo queda disponible para datos y AOS Viewer.

### Perfiles

- Ejecutivo
- Tecnico
- Auditoria completa
- Personalizado, tabla por tabla

### Modos por tabla

- `FULL_BODY`
- `SUMMARY`
- `SAMPLED`
- `FULL_APPENDIX`
- `VIEWER_ONLY`
- `EXCLUDED_EXPORT`, sin destruir los datos

### Cobertura

- informes genericos SLA y de pozo;
- BM/GF3, incluida Carta Gibbs y ciclo promedio;
- BES V2 y BES3;
- comparacion BES3 encendida/apagada;
- CGF y EGF;
- diseno de mandriles;
- sensibilidades comunes y especializadas;
- reportes graficos genericos;
- AOSCAD simple y enriquecido.

Las sensibilidades conservan la tabla como resultado primario y se proponen
completas en todos los perfiles.

### Contrato de archivo

Se incorporan `REPORT_COMPOSITION`, `TABLE_PRESENTATION_*`, `TABLE_INDEX`,
`TABLE_*`, `TABLE_ARCHIVE_INDEX` y `TABLE_ARCHIVE_*`. El manifiesto informa
conteos reales y la version activa de AOS. Los archivos anteriores siguen
siendo legibles.

### Importacion

El lector AOS reconoce las tablas nativas visibles y archivadas, evita que sus
metadatos se interpreten como configuracion y presenta un inventario compacto.

### No modificado

No se modificaron ecuaciones, correlaciones, solvers, resultados numericos,
configuracion fisica, formatos `.aosdat`, geometria DXF/STEP ni AOSBCK.
