# Reporte de empaquetado SENS-GLJGL-02

## Productos

- Distribucion completa: `AOS_0_2_0_DEV1_ENV02_SENS02_COMPLETO.zip`.
- Parche incremental: `PARCHE_AOS_SENS_GLJGL_02_POLINOMIO_EXPLICITO.zip`.
- Base exigida para el parche: copia limpia de `AOS_0_2_0_DEV1_ENV02_SENS01`.

## Contenido del cambio

- Archivos nuevos: 25.
- Archivos modificados: 18.
- Archivos eliminados: 0.
- Menu explicito con modos discreto, polinomico informativo y polinomico verificado.
- Grados AUTO, 2, 3, 4 y 5; grado 5 identificado como historico AOS.
- Recalculo fisico obligatorio del maximo por derivada cero en modo verificado.
- Nucleos GL/JGL protegidos sin cambios.

## Reproducibilidad

- Los ZIP se construyen con entradas ordenadas y fecha fija `2026-08-06 12:00:00`.
- El parche contiene un directorio `payload/` para superponer sobre SENS01.
- `PAYLOAD_SHA256.txt` permite verificar cada archivo del parche.
- La aplicacion del payload se compara byte a byte contra la distribucion completa antes de publicar.

## Estado

- Auditoria estatica: `PASS_STATIC`.
- Validacion dinamica: `NOT_RUN_GNU_OCTAVE_UNAVAILABLE`.
