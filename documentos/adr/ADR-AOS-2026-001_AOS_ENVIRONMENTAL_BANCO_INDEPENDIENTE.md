# ADR-AOS-2026-001

## AOS Environmental como banco de trabajo independiente y transversal

| Campo | Decisión |
|---|---|
| Estado | ACEPTADA |
| Fecha efectiva | 31 de julio de 2026 |
| Baseline | AOS Suite 0.2.0 DEV1 |
| Revisión de arquitectura | ENV-01 |
| Propietario de la decisión | Architecture Owner de AOS |
| Componentes afectados | Suite/Frame, AOSCAD, AOS 3D Core, Wells, Networks, Electrical, Facilities, Fluids, SCADA, Maintenance, Data, Reporting, Viewer y AOS Global |
| Compatibilidad | Se conservan temporalmente `AMBIENTAL` y `AOS_menu_gestion_ambiental` como alias heredados |
| Cambios runtime en esta enmienda | Ninguno |

## 1. Contexto

En AOS 0.1.9 y en la primera documentación de AOS 0.2.0 DEV1, Gestión Ambiental quedó visible principalmente como una opción de AOS Maintenance y como componente HSE del score de pulling. Esa clasificación no representa el alcance requerido.

El dominio ambiental debe administrar eventos e inventarios que atraviesan toda la instalación: derrames, emisiones fugitivas de metano, emisiones de CO₂, liberaciones de H₂S, venteos, flare, combustión, agua producida, residuos, sustancias químicas, riesgo, mitigación, cumplimiento y emisiones indirectas asociadas al consumo de energía.

La ubicación física es parte esencial del dato. Una pérdida debe vincularse inequívocamente con una válvula, sello, brida, tramo de tubería, tanque, batería, equipo, pozo u otro activo. AOSCAD, AOSBCK y AOS 3D Core ya establecen la identidad y la representación espacial mediante `asset_id`, `component_id`, `instance_id`, topología y coordenadas. Por ello, Gestión Ambiental no puede mantenerse como un formulario aislado ni como una etiqueta dentro de Maintenance.

El estado mecánico y la integridad influyen directamente en la probabilidad de pérdida. Sin embargo, la consecuencia ambiental, el inventario emitido, la exposición, la criticidad, el seguimiento y la verificación de mitigaciones pertenecen a un dominio diferente. Asimismo, las emisiones indirectas por energía son transversales a SLA, Electrical, Facilities, Networks y demás consumidores, y requieren una única metodología para evitar factores divergentes y doble conteo.

## 2. Decisión

Se crea y reconoce formalmente **AOS Environmental** como banco de trabajo propio, independiente y transversal.

Identificadores objetivo:

```text
workbench_id = ENVIRONMENTAL
name         = AOS Environmental
module_alias = AMBIENTAL
state        = ROADMAP_ARCHITECTURE_APPROVED
```

El alias `AMBIENTAL` se conserva para compatibilidad con menús, datos y registros históricos. El entrypoint objetivo será `AOS_menu_environmental`. Mientras no se implemente, `AOS_menu_gestion_ambiental` continúa como acceso heredado.

El orden objetivo en la cinta y en el futuro menú es:

```text
AOS SCADA -> AOS ENVIRONMENTAL -> AOS MAINTENANCE
```

AOS Viewer permanece como último banco visible.

## 3. Responsabilidad central

AOS Environmental registra, localiza, cuantifica, evalúa y reporta impactos ambientales asociados a activos físicos y actividades operativas.

Su alcance aprobado incluye:

1. Inventario de fuentes ambientales potenciales.
2. Emisiones fugitivas de CH₄, CO₂, H₂S y especies futuras.
3. Venteos, flare, purgas, despresurizaciones y combustión.
4. Derrames y pérdidas de líquidos.
5. Agua producida, residuos y sustancias químicas.
6. Actividad energética y emisiones indirectas de CO₂ equivalente.
7. Mediciones, campañas LDAR, sensores, alarmas y estimaciones.
8. Riesgo ambiental/HSE, mitigaciones, indicadores y cumplimiento.
9. Acciones correctivas vinculadas con Maintenance.
10. Reportes, Viewer y restricciones para AOS Global.

## 4. Autoridades de datos y fronteras

### 4.1 AOSCAD, AOSBCK y AOS 3D Core

Son la autoridad de:

- identidad del activo;
- geometría;
- ubicación 2D/3D;
- topología y conectividad;
- puertos, nodos, tramos e instancias;
- selección y representación visual.

No calculan emisiones, consecuencias ni riesgo ambiental.

### 4.2 AOS Environmental

Es la autoridad de:

- fuente ambiental;
- evento o detección;
- medición;
- estimación o cálculo;
- masa, volumen, caudal y duración;
- riesgo y criticidad ambiental;
- mitigación, seguimiento y cierre ambiental;
- inventarios e indicadores.

No duplica ni modifica geometría o topología.

### 4.3 AOS Wells, Networks, Facilities, Electrical y Maintenance

Publican estado mecánico, condición, degradación, fallas, inspecciones, presiones, caudales, inventarios, consumos y acciones. No mantienen un modelo ambiental paralelo.

### 4.4 AOS Fluids

Es la fuente oficial de composición y propiedades necesarias para convertir una pérdida física en masa por especie o para evaluar toxicidad, dispersión y comportamiento del fluido.

### 4.5 AOS SCADA

Publica mediciones, tags, históricos, alarmas, eventos y estados de validación. AOS Environmental conserva el vínculo entre el dato SCADA, el activo y el resultado ambiental.

### 4.6 AOS Maintenance

Programa y ejecuta inspecciones, reparaciones, pulling y otras acciones correctivas. Consume criticidad y recomendaciones de AOS Environmental. El cierre de una orden de mantenimiento no cierra automáticamente el evento ambiental: se requiere verificación posterior.

### 4.7 AOS Global

Consume emisiones, riesgos, restricciones y costos de mitigación para optimización integrada. No reproduce la física ni los inventarios del banco ambiental.

## 5. Regla espacial obligatoria

Todo evento o fuente debe vincularse a un `asset_id` cuando exista un activo identificable. La referencia puede complementarse con:

- `component_id`;
- `instance_id`;
- puerto, sello, brida o subcomponente;
- nodo AOSCAD;
- tramo y estación sobre tubería;
- coordenadas XYZ;
- pozo, MD y TVD;
- área afectada o contención secundaria.

Una descripción libre es información complementaria, no una identidad física suficiente.

## 6. Relación con estado mecánico

La arquitectura separa dos cálculos:

```text
estado mecanico / integridad -> probabilidad de perdida
AOS Environmental           -> consecuencia, inventario, riesgo y prioridad ambiental
```

AOS Environmental podrá combinar probabilidad de falla con presión, caudal, inventario, composición, duración probable, detectabilidad, contención y receptores. La metodología detallada se definirá durante el diseño de contratos y solvers.

## 7. Emisiones indirectas por energía

Los bancos consumidores publicarán actividad energética medida, reconciliada, simulada o estimada. AOS Environmental seleccionará factores versionados y calculará emisiones indirectas y CO₂ equivalente.

Regla:

```text
modulo consumidor -> actividad energetica
AOS Environmental -> factor + calculo + trazabilidad + prevencion de doble conteo
```

Los módulos consumidores no deben incorporar factores ambientales divergentes como fuente oficial de verdad.

## 8. Compatibilidad y migración

1. `AMBIENTAL` se mantiene como alias de `ENVIRONMENTAL`.
2. `AOS_menu_gestion_ambiental` se mantiene como alias temporal.
3. Las secciones históricas `[ambiental]`, `[gestion_ambiental]`, `[hse]` y `[emisiones]` deberán ser aceptadas por los futuros adaptadores.
4. AOS Maintenance mantendrá el acceso heredado durante una etapa de transición, pero la cinta y el registro objetivo mostrarán AOS Environmental como banco propio.
5. No se crea en este ADR un nuevo formato propietario ni se decide una extensión de archivo ambiental.
6. La migración no puede romper reportes ni casos históricos.

## 9. Consecuencias positivas

- Identidad espacial inequívoca de eventos y fuentes.
- Separación correcta entre integridad, ambiente y mantenimiento.
- Inventario ambiental transversal a toda la Suite.
- Una sola metodología para emisiones indirectas.
- Mejor trazabilidad entre detección, cálculo, orden correctiva y verificación.
- Capacidad de representar eventos y criticidad en AOSCAD 2D/3D.
- Integración futura con AOS Global sin duplicación de física.

## 10. Costos y riesgos

- Se requieren contratos nuevos y adaptadores de compatibilidad.
- Deben definirse reglas de precedencia entre medición, reconciliación, simulación y estimación.
- Existe riesgo de doble conteo energético si no se gobierna la actividad efectiva.
- Deben versionarse factores de emisión, bases de cálculo y horizontes de CO₂ equivalente.
- H₂S exige conservar toxicidad y exposición por separado de CO₂ equivalente.
- La calidad de localización depende de la madurez del inventario AOSCAD y de los identificadores de activos.

## 11. Fases de implementación

### Fase A — Arquitectura ENV-01

Incluye este ADR, corrección del roadmap, alta del workbench objetivo, fronteras, orden de cinta y documentación. No modifica runtime.

### Fase B — Diseño de contratos

Definirá entidades, campos, unidades, cardinalidades, estados, precedencias, invalidación, catálogos y round-trip.

Entidades candidatas:

```text
ENVIRONMENTAL_SOURCE
ENVIRONMENTAL_EVENT
ENVIRONMENTAL_MEASUREMENT
ENERGY_ACTIVITY
EMISSION_FACTOR
ENVIRONMENTAL_RESULT
ENVIRONMENTAL_RISK
ENVIRONMENTAL_ACTION
```

### Fase C — Scaffold runtime

Creará el entrypoint independiente, menú, contexto, registro, importación/exportación y alias de compatibilidad.

### Fase D — Capacidades ambientales

Implementará inventarios, derrames, emisiones fugitivas/directas, H₂S, energía indirecta, riesgo y reportes.

### Fase E — Integración avanzada

Incluirá SCADA, LDAR, overlays AOSCAD, Maintenance, Viewer y AOS Global.

## 12. Criterios de aceptación de esta decisión

La enmienda ENV-01 se considera correctamente incorporada cuando:

1. AOS Environmental figura como workbench independiente en los manifests 0.2.0.
2. El orden de cinta es SCADA, Environmental, Maintenance.
3. Maintenance ya no declara propiedad del modelo ambiental.
4. La documentación distingue arquitectura objetivo y runtime heredado.
5. AOSCAD figura como autoridad espacial.
6. La actividad energética y la conversión ambiental están separadas.
7. Se conserva compatibilidad con `AMBIENTAL` y el menú histórico.
8. No se presenta ningún contrato detallado o cálculo como implementado antes de su diseño y validación.
9. AOS Viewer sigue siendo el último banco visible.
10. No se modifica la física de los solvers en esta enmienda.

## 13. Decisiones diferidas

Quedan fuera de este ADR:

- schemas y campos definitivos;
- extensión o estructura de archivos ambientales;
- fuentes regulatorias de factores;
- horizonte temporal y potencial de calentamiento global;
- algoritmos de cuantificación de fugas;
- modelos de dispersión y exposición;
- matrices de riesgo;
- interfaz gráfica definitiva;
- criterios de promoción a BETA u OPERATIVO.

Estas decisiones requerirán documentos y pruebas propios.
