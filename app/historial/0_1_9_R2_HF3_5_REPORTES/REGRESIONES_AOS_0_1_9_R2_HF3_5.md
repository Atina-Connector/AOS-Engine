# Regresiones AOS 0.1.9 R2 HF3.5

## Criterios obligatorios

1. Toda tabla disponible debe conservarse en el reporte.
2. `VIEWER_ONLY` y `EXCLUDED_EXPORT` no deben generar perdida de filas.
3. `SUMMARY` y `SAMPLED` deben conservar la tabla completa en archivo interno.
4. El manifiesto debe reportar conteos reales de tablas y graficos.
5. Sensibilidades deben proponer `FULL_BODY` en todos los perfiles.
6. Carta Gibbs y ciclo GF3 de 721 puntos deben poder quedar solo para Viewer.
7. AOSCAD no debe cambiar sus tablas de entrada o resultados al agregar
   metadatos de composicion.
8. El importador no debe reconstruir configuracion a partir de secciones
   `TABLE_*` o `REPORT_*`.
9. Los exportadores cubiertos deben invocar el servicio transversal.
10. Ningun cambio debe introducir archivos `.mat` o funciones duplicadas.

## Pruebas

- `test_aos_report_composition_hf3_5`
- `test_aos_report_module_tables_hf3_5`
- `test_aos_report_sensitivity_hf3_5`
- `test_aos_aoscad_report_composition_hf3_5`
- `test_aos_report_coverage_hf3_5`
