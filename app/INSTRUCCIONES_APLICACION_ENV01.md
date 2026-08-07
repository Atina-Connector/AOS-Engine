# Instrucciones de aplicación — ENV-01

## Alcance

ENV-01 es una enmienda de arquitectura y documentación para la baseline **AOS Suite 0.2.0 DEV1**. Formaliza AOS Environmental como banco de trabajo independiente y transversal mediante `ADR-AOS-2026-001`.

No modifica código GNU Octave `.m`, no crea el entrypoint runtime y no implementa contratos ni cálculos ambientales.

## Baseline requerida

Aplicar únicamente sobre una copia identificada de:

```text
AOS Suite 0.2.0 DEV1
Baseline de origen: AOS 0.1.9 R2 HF3.4-CAD-R16
Integración: composición transversal de tablas HF3.5
```

No aplicar automáticamente sobre una revisión posterior sin comparar manifests y documentos.

## Procedimiento

1. Conservar intacta la carpeta original de AOS 0.2.0 DEV1.
2. Crear una copia de trabajo, por ejemplo `AOS_0_2_0_DEV1_ENV01`.
3. Copiar el contenido del parche sobre la raíz de esa copia, preservando las rutas relativas.
4. Confirmar que no se agregó, eliminó ni modificó ningún archivo `.m`.
5. Revisar:
   - `ARCHITECTURE_REVISION.txt`;
   - `documentos/adr/ADR-AOS-2026-001_AOS_ENVIRONMENTAL_BANCO_INDEPENDIENTE.md`;
   - `documentos/ARQUITECTURA_AOS_ENVIRONMENTAL_0_2_0_DEV1.md`;
   - `src/roadmap/aos_environmental_workbench_0_2_0_dev1.json`;
   - `AUDITORIA_ENMIENDA_ARQUITECTURA_ENV01.md`.
6. Validar los JSON y ejecutar la verificación de AOS en GNU Octave.

## Verificación GNU Octave pendiente

```octave
cd('/ruta/AOS_0_2_0_DEV1_ENV01')
clear functions
rehash
VERIFICAR_AOS_0_2_0_DEV1(false)
VERIFICAR_AOS_0_2_0_DEV1(true)
```

La verificación dinámica no fue ejecutada durante la generación porque GNU Octave no está disponible en ese entorno.

## Resultado esperado

- El runtime heredado continúa funcionando sin cambios y mantiene catorce bancos ejecutables.
- Los manifests de arquitectura enumeran quince bancos objetivo.
- `ENVIRONMENTAL` aparece entre `SCADA` y `MAINTENANCE`.
- `runtime_available=false` para AOS Environmental.
- `AMBIENTAL` y `AOS_menu_gestion_ambiental` continúan como alias históricos.
- AOS Viewer permanece último.

## Próxima etapa autorizada

Diseño y aprobación de contratos de datos ambientales antes de crear código runtime o ecuaciones.
