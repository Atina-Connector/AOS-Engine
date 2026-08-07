# AOS 0.1.0 — Sensibilidades con tablas de texto nativo

## Corrección

El parche anterior agregó imágenes PNG de las tablas como compatibilidad visual. Esa decisión fue incorrecta porque una tabla de producción es un dato auditable, no un gráfico.

Este parche:

- elimina la generación de PNG para tablas de sensibilidad;
- elimina el alias gráfico `tabla_sensibilidad`;
- escribe una sección estándar `[RESULTADOS]` con la tabla punto a punto;
- conserva la matriz completa en `[SENSITIVITY_TABLE]`;
- conserva una versión textual en `[SENSITIVITY_TABLE_TEXT]`;
- mantiene ganancias absolutas, porcentuales e incrementales como valores numéricos;
- deja en `[GRAFICOS]` solamente curvas, survey, punzados y diagnósticos visuales.

## Contrato AOSRPT

La versión de reporte pasa a `1.6`, con:

```ini
viewer_schema=AOS_VIEWER_SENSITIVITY_1.2
tabla_renderizado=TEXTO_NATIVO
tabla_como_imagen=NO
```

La sección de presentación general utiliza:

```ini
[RESULTADOS]
formato_tabla=TEXTO_NATIVO
tabla_imagen=NO
tabla_columnas=...
tabla_unidades=...
punto_001=...
```

La tabla es buscable, copiable y procesable sin pérdida de precisión.
