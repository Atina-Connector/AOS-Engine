# AOS Suite 0.2.0 DEV1

Primera baseline modular para el desarrollo distribuido de AOS.

**Revisión de arquitectura:** ENV-02  
**Decisión:** ADR-AOS-2026-001 — AOS Environmental como banco independiente  
**Cambios runtime de ENV-02:** menú, entrypoint, registro, alias y selftest  
**Revisión científica vigente:** SENS-GLJGL-03

## Motor oficial

GNU Octave. MATLAB no es la plataforma objetivo. AOS no utiliza archivos `.mat` como fuente paralela de verdad.

## Inicio

```octave
cd('/ruta/AOS_0_2_0_DEV1_ENV02_SENS03')
clear functions
rehash
VERIFICAR_AOS_0_2_0_DEV1(false)
AOS
```

Campaña completa:

```octave
VERIFICAR_AOS_0_2_0_DEV1(true)
```

## Arquitectura objetivo

- Workbenches: SLA, Wells, CAD, Networks, Electrical, Facilities, Geology, Fluids, SCADA, Environmental, Maintenance, Data, Solvers, Global y Viewer.
- Servicios: gestión de casos, reportes, unidades, catálogos, validación, AOS 3D Core y AOSBCK.
- Solvers: hidráulicos, eléctricos, mecánicos, térmicos, geológicos, reservorio, producción, redes, optimización, economía, confiabilidad y fluidos.
- AOS Environmental: emisiones fugitivas y directas, derrames, H₂S, energía indirecta, riesgo, mitigación y trazabilidad espacial por `asset_id`.
- AOSCAD / AOS 3D Core: autoridad de identidad, geometría, ubicación y topología física.
- AOS Maintenance: integridad, confiabilidad, pulling y ejecución de acciones correctivas; consume resultados ambientales.
- AOS Global: orquestador futuro, no duplicador de física.

## Estado runtime ENV-02

El menú GNU Octave registra quince workbenches. `AOS Environmental` aparece después de SCADA y antes de Maintenance y abre el entrypoint independiente `AOS_menu_environmental`. El banco actual es un shell de navegación y contratos: todavía no publica cálculos, factores, importadores ni reportes ambientales especializados. `AOS_menu_gestion_ambiental` se conserva como alias histórico.


## Sensibilidades GL/JGL SENS-GLJGL-03

SENS01 conserva la paridad puntual-barrido y la publicacion estricta. SENS02
agrega el tratamiento de curva visible: discreto, polinomico informativo o
polinomico verificado, con grado 5 historico. SENS03 corrige la condicion motriz
JGL cuando se fuerza `Qiny` y `P_iny_sup` es cero o no esta informada. El usuario
elige de forma explicita entre derivar la presion requerida, verificar una
presion disponible o confirmar ausencia de presion motriz.
La simulacion puntual JGL con `Qiny` fijo utiliza el mismo menu, evitando que el comportamiento puntual y el barrido diverjan.

Para cada punto JGL se reportan `Ps`, diferencial motriz requerido, presion
motriz de fondo, columna compresible, perdidas de inyeccion, presion superficial
requerida, margen y limite de `Qiny` por presion. La sensibilidad agrega una
grafica de presiones absolutas y otra de sus componentes. El dato importado de
presion no se sobrescribe en forma oculta.
La auditoria diferencia la presion importada original de una presion ingresada manualmente.

Verificacion especifica:

```octave
VERIFICAR_SENS_GLJGL_03(false)
VERIFICAR_SENS_GLJGL_03(true)
```

## Reportes

AOS 0.2.0 DEV1 integra composición transversal de tablas. Los datos completos se preservan aunque una tabla no se renderice en el cuerpo del reporte.

## Estado

Versión de desarrollo. AOSCAD R16 continúa como candidato a revisión, BES3 permanece no validado y varios bancos conservan estado BETA, ROADMAP o CONCEPTUAL. AOS Environmental está en `ROADMAP_RUNTIME_SHELL`: su navegación está implementada, pero sus cálculos científicos permanecen pendientes y no deben presentarse como disponibles.

## Documentos principales

- `AOS_0_2_0_DEV1_CONTEXTO_COMPLETO.md`
- `documentos/adr/ADR-AOS-2026-001_AOS_ENVIRONMENTAL_BANCO_INDEPENDIENTE.md`
- `documentos/ARQUITECTURA_AOS_ENVIRONMENTAL_0_2_0_DEV1.md`
- `ARCHITECTURE_REVISION.txt`
- `NOTA_RUNTIME_AOS_ENVIRONMENTAL_ENV02.md`

Los DOCX generados en ENV-01 se conservan como antecedente de arquitectura. La actualización runtime ENV-02 está documentada en los Markdown y archivos de control indicados arriba.

## Auditoría y aplicación

- `AUDITORIA_ENMIENDA_ARQUITECTURA_ENV01.md`
- `AUDITORIA_ENMIENDA_ARQUITECTURA_ENV01.json`
- `INSTRUCCIONES_APLICACION_ENV01.md`
- `MANIFEST_AOS_0_2_0_DEV1_ENV01.txt`
- `SHA256SUMS_AOS_0_2_0_DEV1_ENV01.txt`

ENV-01 permanece como antecedente de arquitectura sin cambios runtime. ENV-02 implementa el shell independiente y agrega su auditoría específica:

- `AUDITORIA_AOS_ENVIRONMENTAL_ENV02.md`
- `AUDITORIA_AOS_ENVIRONMENTAL_ENV02.json`
- `CHANGELOG_AOS_ENVIRONMENTAL_ENV02.md`
- `NOTA_RUNTIME_AOS_ENVIRONMENTAL_ENV02.md`

La verificación dinámica debe completarse en GNU Octave.

### Documentos de control SENS-GLJGL-03

- `CHANGELOG_SENS_GLJGL_03.md`
- `REGRESIONES_SENS_GLJGL_03.md`
- `INSTRUCCIONES_APLICACION_SENS_GLJGL_03.md`
- `AUDITORIA_ESTATICA_SENS_GLJGL_03.md`
- `REPORTE_EMPAQUETADO_SENS_GLJGL_03.md`

SENS03 se distribuye de forma acumulativa: la entrega completa ya contiene SENS01 y SENS02, y el parche publicado se aplica directamente sobre una copia limpia de SENS01.
