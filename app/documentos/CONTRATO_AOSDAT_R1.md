# Contrato AOSDAT R1 — extensión progresiva

AOSDAT continúa siendo un archivo de texto versionado con secciones. Un paquete puede contener cualquier combinación de dominios. La importación es automática e indiferenciada.

Secciones canónicas nuevas o reservadas:

```ini
[CATALOGOS]
[CALIBRACION]
[SCADA]
[ECONOMIA]
[PCP]
[LDL]
[INYECTORES]
[MALLAS]
[BATERIAS]
[FLUIDOS]
[RED_ELECTRICA]
[ARRANQUE]
```

Aliases reconocidos se normalizan sin borrar el bloque original en `aosdat_sections`.

Reglas:

1. Los datos explícitos del archivo prevalecen para el caso.
2. Los catálogos embebidos son snapshots del proyecto y no modifican silenciosamente catálogos permanentes.
3. Los datos medidos y la calibración pueden ser consumidos por SCADA según política.
4. Los comandos operativos no se ejecutan automáticamente en 0.1.1-R1.
5. Las secciones desconocidas se preservan para lectores futuros.
6. Un fallo de validación no debe producir una mezcla parcial con el caso anterior.
