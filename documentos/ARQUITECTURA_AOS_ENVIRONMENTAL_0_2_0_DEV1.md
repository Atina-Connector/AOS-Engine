# AOS Environmental

## Arquitectura de banco de trabajo para AOS 0.2.0 DEV1 — revisión ENV-02

**Estado:** ROADMAP_RUNTIME_SHELL  
**Decisión:** ADR-AOS-2026-001  
**Runtime:** entrypoint independiente implementado en ENV-02; cálculos pendientes  
**Alias heredado:** `AMBIENTAL` / `AOS_menu_gestion_ambiental`

## 1. Propósito

AOS Environmental será el banco de gestión ambiental de la Suite. Relacionará cada fuente, detección, emisión, derrame, medición, cálculo, riesgo y acción con un activo físico inequívoco y con el período en el que ocurrió.

## 2. Arquitectura funcional

```text
                         AOSCAD / AOS 3D Core
                  identidad, geometria y ubicacion
                                   |
                                   v
AOS Wells -----------> AOS ENVIRONMENTAL <----------- AOS Facilities
estado mecanico          |         |                   procesos/inventarios
                         |         |
AOS Networks ------------+         +------------------ AOS Fluids
presion/caudal/topologia                            composicion/propiedades
                         |         |
AOS Electrical / SLA ----+         +------------------ AOS SCADA
actividad energetica                                  mediciones/alarmas
                                   |
                                   v
                          AOS Maintenance
                    reparacion e intervencion
                                   |
                                   v
                              AOS Global
            optimizacion con restricciones ambientales
```

## 3. Objetos de ingeniería

El banco distinguirá conceptualmente:

```text
activo fisico
  -> fuente ambiental potencial
  -> evento, medicion o actividad
  -> calculo e inventario
  -> riesgo y consecuencia
  -> accion de mitigacion
  -> verificacion y cierre
```

No se congelan todavía las entidades de datos; el diagrama define responsabilidades.

## 4. Dependencias obligatorias

| Dependencia | Información consumida |
|---|---|
| AOSCAD / AOS 3D Core | `asset_id`, geometría, topología, puertos, nodos, tramos, selección y overlays |
| AOS Wells | Survey, MD/TVD, completación, estado mecánico e integridad de pozo |
| AOS Networks | presión, caudal, sentido de flujo, inventario lineal y estado de válvulas/líneas |
| AOS Facilities | equipos, procesos, tanques, contenciones, balances e inventarios |
| AOS Electrical / SLA | actividad energética, potencia, pérdidas y horas de operación |
| AOS Fluids | composición, densidad, PVT, fracciones de CH₄/CO₂/H₂S y propiedades |
| AOS SCADA | mediciones, históricos, tags, alarmas y estado de validación |
| AOS Data | importación, catálogos, schemas, interoperabilidad y trazabilidad |
| Reporting / Viewer | tablas, mapas, gráficos, recursos 2D/3D y distribución |

## 5. Salidas y consumidores

| Consumidor | Resultado ambiental esperado |
|---|---|
| AOS Maintenance | criticidad, acción requerida, activo, prioridad y verificación posterior |
| Pulling Intelligence | score ambiental/HSE y reglas críticas |
| AOS Global | emisiones, restricciones, riesgo, costo y reducción por escenario |
| Viewer | inventarios, eventos, tendencias, mapas, activos y evidencias |
| SCADA | recomendaciones de tags, umbrales y calidad de medición |
| AOSCAD | overlays de fuente, evento, masa, criticidad y estado de mitigación |

## 6. Localización física

Orden de preferencia:

1. Activo y subcomponente identificados.
2. Nodo, puerto, tramo o estación AOSCAD.
3. Pozo con MD/TVD.
4. Coordenadas XYZ con método e incertidumbre.
5. Área o instalación cuando no pueda aislarse el componente.

La descripción libre nunca sustituye una identidad disponible.

## 7. Dominio ambiental

### Emisiones fugitivas

CH₄, CO₂, H₂S y especies futuras, asociadas a válvulas, sellos, bridas, instrumentos, conexiones, tanques, líneas, cabezas de pozo y equipos.

### Emisiones directas operativas

Venteo, flare, purga, despresurización, combustión, pruebas e intervenciones.

### Derrames

Petróleo, condensado, agua producida, productos químicos, combustibles, lubricantes y fluidos de intervención, con fuente y área afectada.

### Energía y emisiones indirectas

Actividad de electricidad, gas, diésel y otros portadores. AOS Environmental aplica factores versionados; los consumidores no mantienen factores oficiales propios.

### Riesgo y mitigación

Probabilidad aportada por integridad y operación, consecuencia ambiental calculada por el banco, acciones ejecutadas por Maintenance y cierre verificado por medición o inspección.

## 8. Menú objetivo

```text
========== AOS ENVIRONMENTAL ==========

 1 - Proyecto, instalaciones y activos ambientales
 2 - Visualizar activos y eventos en AOSCAD
 3 - Inventario de fuentes de emision
 4 - Emisiones fugitivas y campanas LDAR
 5 - Venteo, flare y emisiones directas
 6 - H2S y liberaciones de gases toxicos
 7 - Derrames y perdidas liquidas
 8 - Agua producida, residuos y sustancias
 9 - Consumo energetico y emisiones indirectas
10 - Estado mecanico y riesgo ambiental
11 - SCADA, sensores, alarmas e historicos
12 - Escenarios de mitigacion
13 - Acciones correctivas y vinculo con Maintenance
14 - Indicadores, inventarios y cumplimiento
15 - Reportes ambientales y Viewer
16 - Importar / exportar datos ambientales
17 - Configuracion, factores y catalogos
18 - Estado, validacion y roadmap
 0 - Volver
```

Este menú está implementado como shell de navegación en ENV-02. Las opciones científicas permanecen en roadmap y muestran un estado honesto de no disponibilidad.

## 9. Roadmap

| Hito | Resultado |
|---|---|
| E0 — ENV-01 | ADR, workbench, fronteras, dependencias y orden de cinta |
| E1 — ENV-02 | Entrypoint, menú, registro runtime, navegación y alias heredado |
| E2 — Contratos | Identidad espacial, fuentes, eventos, mediciones, energía, factores y acciones |
| E3 — Eventos localizados | Derrames, CH₄, CO₂, H₂S y overlays AOSCAD |
| E4 — Energía | Emisiones indirectas, factores y prevención de doble conteo |
| E5 — Integridad/SCADA | Estado mecánico, alarmas, históricos, LDAR y reconciliación |
| E6 — Inteligencia | Riesgo, mitigación, cumplimiento, economía y AOS Global |

## 10. No objetivos de ENV-02

- no implementar ecuaciones;
- no definir factores regulatorios;
- no crear un nuevo formato propietario;
- no eliminar todavía el menú histórico ni el alias `AMBIENTAL`;
- no modificar la física interna de AOSCAD, SCADA o Maintenance;
- no declarar el banco BETA u OPERATIVO.
