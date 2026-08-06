# AOS Suite 0.2.0 DEV1

## Documento integral de contexto, continuidad y arranque de desarrollo distribuido

**Fecha de baseline:** 31 de julio de 2026  
**Motor científico oficial:** GNU Octave  
**Estado:** DESARROLLO; no constituye liberación productiva  
**Baseline de origen:** AOS 0.1.9 R2 HF3.4-CAD-R16  
**SHA-256 de la baseline recibida:** `addcee6e609aac769794fada358f9d8246539378a806e69a1b035818949ac421`  
**Integración adicional incluida:** composición transversal de tablas y reportes HF3.5  
**Versión resultante:** `0.2.0-DEV1`  
**Revisión de arquitectura:** `ENV-02`  
**Decisión aprobada:** `ADR-AOS-2026-001 — AOS Environmental como banco independiente`  
**Alcance de ENV-02:** implementa el shell runtime del banco independiente; los contratos detallados y cálculos científicos permanecen pendientes.

---

# 1. Propósito de este documento

Este documento es el traspaso formal para iniciar un chat limpio y para distribuir AOS entre grupos de trabajo especializados sin perder el contexto técnico, la arquitectura ni las decisiones acumuladas. Debe tratarse como la referencia inicial de AOS 0.2.0 DEV1 junto con el código de la distribución.

AOS dejó de ser un único simulador lineal. La Suite es ahora una plataforma modular en GNU Octave con bancos de trabajo, servicios transversales, solvers comunes y una futura capa AOS Global. Cada banco puede evolucionar como programa independiente, pero no puede duplicar ni modificar unilateralmente los núcleos científicos compartidos.

## Reglas que deben preservarse en cualquier conversación nueva

1. GNU Octave es la plataforma objetivo. MATLAB puede utilizarse como referencia conceptual, pero no como dependencia ni como motor oficial.
2. Antes de escribir código o generar parches, primero se plantea la solución física y arquitectónica, se discute y luego se implementa.
3. El sistema principal de unidades es métrico: bar, m, m³/d, Sm³/d, °C, Pa y SI. Las unidades imperiales son referencias secundarias.
4. Los datos tabulares son la fuente primaria. Gráficos, planos y escenas 3D son representaciones derivadas.
5. Un cambio de geometría, fluido, catálogo, punzados, condición de borde o configuración invalida los resultados anteriores.
6. Los núcleos comunes se consumen mediante interfaces públicas versionadas; los equipos de banco no modifican sus implementaciones internas.
7. Los formatos nativos deben permanecer abiertos, auditables y compatibles con Octave. No se usan archivos `.mat` como fuente paralela de verdad.
8. Los módulos en roadmap permanecen visibles en el menú y en la futura cinta del frame.
9. AOS Viewer es el último banco visible y no reemplaza la preservación estructurada de los datos.
10. Ningún resultado beta, de desarrollo o no validado debe presentarse como aprobado por el solo hecho de que el solver ejecute.
11. AOS Environmental es un banco de trabajo propio e independiente. AOS Maintenance consume sus resultados y ejecuta acciones correctivas, pero no es propietario del modelo ambiental.
12. AOSCAD y AOS 3D Core son la autoridad de identidad, ubicación y topología física; ningún evento ambiental puede depender únicamente de una descripción libre cuando existe un activo identificable.
13. Los módulos consumidores de energía publican actividad energética; la conversión a emisiones indirectas y CO₂ equivalente se centraliza en AOS Environmental para evitar factores divergentes y doble conteo.

---

# 2. Identidad de AOS 0.2.0 DEV1

AOS 0.2.0 DEV1 es la primera baseline de la nueva línea de desarrollo distribuido. Se construyó sobre la rama real instalada y auditada `AOS 0.1.9 R2 HF3.4-CAD-R16`, no sobre una distribución genérica. Conserva las correcciones de gestión de casos, catálogos, galerías, geología, punzados, GF3 y AOSCAD R16, e integra el hotfix HF3.5 de composición transversal de tablas.

## Alcance de la transición

- Se cambia la identidad de la Suite a 0.2.0 DEV1.
- Se conserva la ubicación física actual del código para minimizar riesgo de regresión.
- Se formalizan manifests 0.2.0 para workbenches, servicios, solvers y roadmap.
- Se preservan los verificadores y el historial 0.1.9 para regresión.
- Se integra HF3.5 sobre el escritor AOSCAD R16 mediante una fusión explícita: R16 conserva recursos visuales y HF3.5 agrega metadatos de presentación de tablas.
- No se reescriben ecuaciones ni se trasladan masivamente solvers en esta primera baseline.
- ENV-01 aprobo la arquitectura de AOS Environmental y ENV-02 implementa su entrypoint independiente, registro runtime y compatibilidad heredada. Los contratos detallados y calculos cientificos se mantienen para la etapa siguiente.

## Estado de madurez

AOS 0.2.0 DEV1 es una versión de desarrollo. Sus bancos conservan estados independientes: operativo, beta, desarrollo, roadmap, alpha o conceptual. La versión de la Suite no promueve automáticamente la madurez de un módulo. ENV-02 registra quince bancos en runtime, incluido AOS Environmental en estado `ROADMAP_RUNTIME_SHELL`; esto no implica disponibilidad de sus cálculos científicos.

---

# 3. Arquitectura general

## 3.1 Capas

### A. Bancos de trabajo

Los bancos definen el problema de ingeniería, la navegación, la edición de datos y la presentación de resultados:

- AOS SLA
- AOS Wells
- AOS CAD
- AOS Networks
- AOS Electrical
- AOS Facilities
- AOS Geology
- AOS Fluids
- AOS SCADA
- AOS Environmental
- AOS Maintenance
- AOS Data
- AOS Solvers
- AOS Global
- AOS Viewer

### B. Servicios transversales

- Gestión universal y contextual de casos.
- AOS Data Contracts.
- Catálogos base, permanentes y embebidos.
- AOS Fluids.
- AOS 3D Core.
- AOSBCK.
- Unidades.
- Validación y semáforos.
- Reporting y composición de tablas.
- Interoperabilidad.

### C. Solvers científicos

Los solvers están separados conceptualmente de los menús y se registran por disciplina:

- hidráulicos;
- eléctricos;
- mecánicos;
- térmicos;
- geológicos;
- reservorio;
- producción y SLA;
- multifísicos;
- redes y grafos;
- optimización;
- económicos;
- confiabilidad y riesgo;
- fluidos.

### D. AOS Global

AOS Global será el orquestador futuro de reservorio, pozos, levantamiento, redes, energía, instalaciones, SCADA, ambiente, mantenimiento, economía y HSE. No debe duplicar física ni absorber solvers. AOS Environmental aportará inventarios, restricciones, riesgos, emisiones y escenarios de mitigación; AOS Global los consumirá sin reproducir los cálculos ambientales.

## 3.2 Frame previsto

La interfaz 0.2.x deberá tener:

- cinta superior de bancos de trabajo;
- árbol del proyecto a la izquierda;
- vista principal 2D, 3D, tablas o gráficos al centro;
- panel de propiedades a la derecha;
- estado, advertencias, solver, unidades y origen de datos en la parte inferior.

Los contratos de la cinta se encuentran en `src/roadmap/aos_frame_ribbon_contract_0_2_0.json`. ENV-02 materializa el orden `SCADA → ENVIRONMENTAL → MAINTENANCE` y conserva AOS Viewer como último banco visible.

---

# 4. Menú principal de AOS 0.2.0 DEV1

## 4.1 Menu runtime vigente en ENV-02

ENV-02 materializa el banco independiente en GNU Octave. El menu registra quince workbenches y conserva el alias historico:

```text
 1 - NUEVO / ABRIR / IMPORTAR / CONFIGURAR CASO [TRANSVERSAL]
 2 - AOS SLA
 3 - AOS WELLS
 4 - AOS CAD
 5 - AOS NETWORKS
 6 - AOS ELECTRICAL
 7 - AOS FACILITIES
 8 - AOS GEOLOGY
 9 - AOS FLUIDS
10 - AOS SCADA
11 - AOS ENVIRONMENTAL
12 - AOS MAINTENANCE
13 - AOS DATA
14 - AOS SOLVERS
15 - AOS GLOBAL
16 - ROADMAP GENERAL DE AOS
17 - Configuracion, versiones y diagnosticos
18 - AOS VIEWER
19 - Menu AOS 0.1.9 R1 anterior [COMPATIBILIDAD]
 0 - Salir
```

## 4.2 Estado del entrypoint

`AOS_menu_environmental` es el entrypoint independiente. En ENV-02 funciona como shell de navegacion y contratos: enlaza gestion de caso, AOSCAD, integridad, SCADA, Maintenance, Reporting y AOS Data, pero no publica todavia calculos, factores, importadores ni reportes ambientales especializados. `AOS_menu_gestion_ambiental` se conserva como alias de compatibilidad.

AOS Viewer continua siendo el ultimo banco visible.

---

# 5. Matriz de bancos de trabajo

| Banco | Estado en DEV1 | Responsabilidad central |
|---|---|---|
| AOS SLA | Operativo/Beta | Sistemas de levantamiento, producción y comparación |
| AOS Wells | Beta/Roadmap | Survey, completación, estado mecánico, integridad y componentes |
| AOS CAD | DEV1 R16 | DXF, STEP, topología, AOSCAD, 3D Core e ingeniería geométrica |
| AOS Networks | Beta | Redes hidráulicas, dominios, ramificaciones, lazos y recolección |
| AOS Electrical | Core activo/Roadmap | Motores, cables, VSD, potencia y futuras redes eléctricas |
| AOS Facilities | Roadmap | Instalaciones de superficie, procesos, balances y restricciones |
| AOS Geology | Beta/Roadmap | Geología, capas, punzados, estratigrafía y modelo espacial |
| AOS Fluids | Beta transversal | PVT, propiedades de fluidos y `fluid_id` |
| AOS SCADA | Beta | Historiales, tags, alarmas, validación y calibración |
| AOS Environmental | Roadmap runtime shell | Emisiones fugitivas y directas, derrames, H₂S, CO₂/CH₄, emisiones indirectas, riesgo, mitigación y trazabilidad espacial por `asset_id` |
| AOS Maintenance | Roadmap | Integridad, confiabilidad, pulling, economía y ejecución de acciones correctivas; consume resultados ambientales |
| AOS Data | Beta/Activo | Formatos, catálogos, contratos e interoperabilidad |
| AOS Solvers | Transversal | Registro, gobierno, benchmarks y regresiones de motores |
| AOS Global | Conceptual | Integración y optimización global futura |
| AOS Viewer | Alpha36 | Visualización, comparación y distribución de reportes |

---

# 6. Gestión transversal del caso

Todo banco y módulo de simulación debe poder crear, abrir, importar, editar, guardar y recalcular sin volver al menú inicial. La opción 1 de la Suite ofrece la puerta universal; cada banco contiene una apertura contextual.

## Jerarquía de configuración

```text
valores base de config/
        ↓
.aosdat activo
        ↓
edición manual efectiva del módulo
```

El `.aosdat` activo tiene prioridad y no puede ser sobrescrito silenciosamente por defaults.

## Estados recomendados

- `SIN_CASO`
- `CASO_CARGADO`
- `CASO_MODIFICADO`
- `LISTO_PARA_SIMULAR`
- `EJECUTADO`
- `EJECUTADO_CON_ADVERTENCIAS`
- `RESULTADOS_OBSOLETOS`
- `ERROR_DE_VALIDACION`

## Cambios que invalidan resultados

- Survey o geometría.
- Punzados.
- Geología.
- Fluido o PVT.
- Catálogo o selección de componente.
- Condiciones de borde.
- Configuración de solver.
- Diámetros, longitudes o propiedades físicas.

---

# 7. Formatos nativos y externos

## `.aosdat`

Modelo/configuración de entrada. Puede contener pozo, Survey, geología, punzados, estado mecánico, fluidos, parámetros de SLA, catálogos, galerías, condiciones y referencias de benchmark.

## `.aosrpt`

Reporte reproducible de AOS. Contiene entradas efectivas, resultados, tablas, convergencia, diagnósticos, advertencias y opcionalmente recursos visuales. Un reporte puede reconstruir un caso solo cuando contiene entradas suficientes.

## `.aoscad`

Equivalente funcional de `.aosrpt` para CAD, redes e instalaciones. Es JSON canónico, editable y recalculable. Conserva geometría, topología, condiciones de borde, tablas, resultados y composición de presentación.

## `.aosbck`

AOS Block Component. Contenedor abierto derivado de STEP que define una geometría reutilizable, número de parte, fabricante, proveedor, material, puertos y múltiples instancias/ubicaciones.

## DXF

Entrada 2D completa para geometría, capas, bloques, metadatos y topología. En instalaciones y galerías cumple un rol equivalente al `.aosdat` geométrico.

## STEP

Fuente geométrica 3D neutra. Se utiliza para inventario, visualización bajo demanda y creación de AOSBCK.

## Simple y enriquecido

- Simple: datos estructurados, tablas y resultados; ideal para usuarios con AOS Suite.
- Enriquecido: mismo modelo más gráficos, planos, perfiles, mapas o imágenes embebidas para Viewer.

---

# 8. AOS SLA

## Menú

```text
1 - Gas Lift / JGL
2 - BES
3 - Bombeo Mecánico
4 - PCP
5 - CGF - Compresión de Gas en Fondo
6 - EGF - Eductor Gas-Gas de Fondo
7 - Comparación de sistemas
8 - Herramientas comunes de SLA
9 - Abrir / importar / configurar caso SLA
0 - Volver
```

## GL y JGL

- GL convencional y JGL propietario AESIR.
- IPR lineal, Vogel y Fetkovich.
- VLP simplificado, Hagedorn-Brown y Duns & Ros.
- Diseño automático de mandriles V2.
- Sensibilidades con modos iterativo, directo e híbrido.
- Menú de inyección con valor por defecto, valor forzado incluido cero y automático.
- Los reportes deben preservar solver, iteraciones, convergencia, unidades y advertencias.

## BES

- BES V1 legado.
- BES V2 beta.
- BES3 en desarrollo no validado, con recirculación y capilar.
- Núcleo eléctrico común con motor, cable, VSD y térmica.
- Comparación BES1/BES2/BES3.
- Sensibilidades y tablas de frecuencia, etapas, recirculación, intake y potencia.

## Bombeo Mecánico

- Gibbs Foundation, Foundation 2 y GF3.
- Cartas de superficie y fondo.
- Diseño de sarta por secciones y materiales.
- Barras de peso.
- Espaciamiento.
- Tubería anclada o libre.
- Reporte de parámetros efectivos, origen, unidad y validación.

### Regresión crítica resuelta

En tubería libre, GF3 separa:

```text
elongación positiva del tubing
posición firmada del fondo del tubing, negativa hacia abajo
posición relativa pistón-barril
```

La pendiente elástica de la carta de fondo debe ser positiva y consistente con `E*A/L`. El espaciamiento utiliza la magnitud positiva de la elongación.

## PCP, LDL, CGF y EGF

- PCP y LDL permanecen en desarrollo.
- CGF es beta y propietario AESIR.
- EGF es planificado y propietario AESIR.
- Los núcleos eléctricos y de fluidos deben consumirse como servicios comunes.

---

# 9. AOS Wells y AOS Geology

AOS Wells administra Survey, punzados, completación, estado mecánico y componentes ubicados por MD. AOS Geology administra capas, propiedades, estratigrafía y contexto espacial.

## Gestor de punzados

El gestor transversal permite:

- crear conjuntos desde cero;
- agregar, editar, duplicar, activar/desactivar y eliminar intervalos;
- generar intervalos regulares;
- importar y exportar `.aosdat`;
- trabajar sin Survey ni geología;
- calcular TVD cuando existe Survey;
- conservar metadatos extendidos en `[PUNZADOS_META]`;
- invalidar resultados al confirmar cambios.

La sección histórica `[PUNZADOS]` se conserva para compatibilidad.

## Geología transaccional

La edición trabaja sobre una copia candidata. Reconfirmar una geología idéntica no invalida resultados, incluso con campos `NaN`, gracias a comparación idempotente. Editar, reemplazar, fusionar o eliminar son opciones numeradas; `s/n` solo confirma una acción definida.

---

# 10. AOS CAD R16 y AOS 3D Core

## Estado

```text
AOSCAD-0.0.1-DEV1-R16
ESTADO=PROTOTIPO_NO_VALIDADO
REVISION=CANDIDATO_REVISION_JEFE
PROMOCION=PENDIENTE_APROBACION_JEFE
```

No se debe presentar como beta hasta aprobación formal.

## Menú principal de AOS CAD

```text
1 - CAD 2D / DXF
2 - CAD 3D / STEP
3 - Topología, capas y datos técnicos
4 - Simulación hidráulica
5 - Reportes .aoscad y resultados
6 - Sincronización y recarga
7 - Plataforma y diagnósticos
8 - AOS 3D Core transversal
9 - Abrir / importar / configurar proyecto o caso
10 - Galerías CAD
0 - Volver
```

## Capacidades R16

- Conversión de unidades DXF.
- Identidad determinística `asset_id`.
- Topología audible y validaciones.
- Redes ramificadas.
- Condiciones presión/caudal en extremos.
- Solver de lazos Newton-Kirchhoff monofásico DEV1.
- Múltiples fuentes y flujo reverso.
- Índice geométrico STEP.
- Visor 3D integrado y headless.
- Puertos y conexiones 3D.
- Interferencias AABB.
- Escena federada.
- Overlay de resultados.
- Sincronización 2D/3D.
- Recursos visuales regenerables.

## Dominio hidráulico selectivo

El usuario puede seleccionar nodo inicial, nodo final y un camino o subred. Esto permite analizar únicamente un tramo crítico. En R16 los lazos monofásicos disponen de un solver DEV1; los casos multifásicos complejos siguen sujetos a validación y roadmap.

## Fusión R16 + HF3.5

El escritor `.aoscad` de DEV1 conserva dos comportamientos simultáneos:

1. R16 genera o regenera recursos visuales de la modalidad enriquecida.
2. HF3.5 inventaría tablas de entrada y resultados y registra su modo de presentación sin duplicar ni eliminar datos del JSON.

---

# 11. AOS Networks

AOS Networks reutiliza geometría y topología de AOS CAD, fluidos de AOS Fluids y solvers hidráulicos comunes.

## Alcance actual

- Redes abiertas y ramificadas.
- Dominios seleccionados.
- Darcy-Weisbach monofásico.
- Adaptadores Hagedorn-Brown, Duns & Ros y modelo simplificado.
- Condiciones de borde por presión y caudal.
- Lazos monofásicos Newton-Kirchhoff DEV1 en CAD R16.
- Tablas nodales y por tramo.
- Resultados preservados en `.aoscad`.

## Roadmap

- Validación exhaustiva de lazos.
- Redes multifásicas generales con cambio de régimen.
- Controles, bombas, compresores y válvulas activas.
- Acoplamiento pozo-red-planta.

---

# 12. AOS Electrical y Facilities

AOS Electrical consume el núcleo eléctrico de BES/CGF y evolucionará hacia redes de potencia, transformadores, tableros, VSD, cables, cargas y protecciones.

AOS Facilities administrará instalaciones de superficie, redes, balances de masa y energía, capacidad y restricciones. Ambos bancos utilizan AOSCAD, AOSBCK, AOS 3D Core y SCADA.

Su visibilidad en DEV1 no implica que todos los solvers estén disponibles o validados.

---

# 13. AOS Fluids

AOS Fluids debe ser la fuente oficial de propiedades para toda la Suite. El modelo se referencia mediante `fluid_id` y registra:

- tipo de modelo;
- API, water cut y GLR;
- gravedad específica de gas;
- PVT;
- viscosidad y densidades;
- correlación;
- rango de validez;
- calibración;
- origen;
- incertidumbre y advertencias.

Los bancos no deben mantener versiones divergentes de las mismas propiedades.

---

# 14. AOS SCADA, Environmental, Maintenance y Data

## SCADA

- importación manual de paquetes;
- bandejas automáticas;
- variables actuales;
- históricos;
- alarmas y eventos;
- mapeo de tags;
- validación;
- calibración y recomendaciones.

El roadmap exige generar `.aosrpt` históricos y, opcionalmente, `.aosdat` derivados para calibración.

## AOS Environmental

AOS Environmental es un banco independiente y transversal aprobado por `ADR-AOS-2026-001`. Su responsabilidad es registrar, localizar, cuantificar, evaluar y reportar impactos ambientales asociados a activos físicos y actividades operativas. No es una subsección de Maintenance ni queda reducido al score HSE de pulling.

### Alcance funcional aprobado

- derrames de petróleo, condensado, agua producida, combustibles, lubricantes y productos químicos;
- emisiones fugitivas de metano, CO₂, H₂S y otras especies que se incorporen al modelo de fluidos;
- venteos, flare, purgas, despresurizaciones y emisiones de combustión;
- inventario de fuentes, campañas LDAR, mediciones, estimaciones y eventos;
- emisiones indirectas de CO₂ equivalente por consumo de electricidad y otros portadores energéticos;
- riesgo ambiental/HSE, mitigaciones, cumplimiento, indicadores y reportes;
- trazabilidad por activo, instalación, componente, período, método, origen, validación e incertidumbre.

### Relación obligatoria con AOSCAD

AOSCAD, AOSBCK y AOS 3D Core son la autoridad de identidad, geometría, ubicación y topología. AOS Environmental referencia esa información mediante `asset_id`, `component_id`, `instance_id` y, cuando corresponda, nodo, puerto, tramo, estación sobre tubería, coordenadas XYZ, pozo, MD o TVD. Un texto como “pérdida en válvula” no constituye localización suficiente si la válvula puede identificarse de forma inequívoca.

AOS Environmental es la autoridad del evento, la medición, el cálculo, el riesgo y la acción ambiental. No duplica geometría ni modifica la topología de AOSCAD. Desde un evento se deberá poder resaltar el activo en 2D/3D; desde un activo se deberá poder consultar su historial ambiental.

### Relación con estado mecánico e integridad

AOS Wells, AOS Facilities, AOS Networks, AOS Electrical, SCADA y Maintenance publicarán condición, degradación, inspecciones o fallas. AOS Environmental utilizará esos estados para estimar probabilidad de pérdida y combinarla con inventario, composición, presión, caudal, duración, receptores, detección y contención. El estado mecánico alimenta la probabilidad; el banco ambiental calcula la consecuencia y la criticidad ambiental.

### Emisiones indirectas por energía

Los bancos consumidores de energía publicarán actividad energética medida, reconciliada, simulada o estimada. AOS Environmental aplicará factores versionados y centralizados para calcular emisiones indirectas y CO₂ equivalente. Esta separación evita que BES, BM, PCP, compresión, redes, instalaciones y Electrical utilicen factores distintos o contabilicen dos veces la misma energía.

### Estado de implementación en ENV-02

El entrypoint independiente, el orden de cinta, el registro runtime y el alias histórico están implementados. Los contratos detallados, catálogos de factores, cálculos, persistencia especializada, importadores y reportes ambientales continúan pendientes.

## Maintenance

AOS Maintenance conserva integridad, confiabilidad, pulling, economía de intervención y ejecución de acciones correctivas. El score ambiental/HSE utilizado por Pulling Intelligence será un resultado suministrado por AOS Environmental. Las reglas críticas deben prevalecer sobre promedios ponderados, pero Maintenance no mantendrá un modelo ambiental paralelo.

## Data

AOS Data gobierna:

- `.aosdat`, `.aosrpt`, `.aoscad`, `.aosbck`;
- catálogos;
- galerías;
- CSV/XLSX;
- Prosper, Pipesim y Wellflo;
- SCADA;
- contratos de workbenches, servicios y solvers.

---

# 15. AOS Solvers

El banco AOS Solvers es la biblioteca y gobierno científico. Cada solver debe declarar:

- `solver_id`;
- versión;
- disciplina;
- contrato de entrada y salida;
- unidades;
- dominio de aplicación;
- convergencia;
- advertencias;
- benchmark;
- regresión;
- estado de madurez.

Los bancos llaman interfaces públicas; no copian ecuaciones.

## Solvers notables en la baseline

- Hydraulic Tree/Domain y lazos R16.
- Hagedorn-Brown.
- Duns & Ros.
- Darcy-Weisbach.
- Taitel-Dukler y límites de flujo.
- GF3 mecánico.
- JGL iterativo/directo/híbrido.
- BES2/BES3.
- PVT.

---

# 16. Reportes y composición transversal de tablas HF3.5

## Principio

Los datos calculados siempre se conservan. La composición controla únicamente qué se renderiza en el cuerpo, anexo o Viewer.

```text
full_data_policy = ALWAYS_PRESERVE
```

## Perfiles

- `EXECUTIVE`: resultados, diagnósticos y tablas pequeñas.
- `TECHNICAL`: tablas técnicas principales y anexos moderados.
- `AUDIT`: tablas completas, con extensas en anexos.
- `CUSTOM`: decisión individual por tabla.

## Modos por tabla

- `FULL_BODY`
- `SUMMARY`
- `SAMPLED`
- `FULL_APPENDIX`
- `VIEWER_ONLY`
- `EXCLUDED_EXPORT`

`EXCLUDED_EXPORT` no borra los datos; solo los omite de esa exportación visible.

## Sensibilidades

La tabla de sensibilidad es el resultado técnico principal y se propone completa por defecto. El gráfico es secundario.

## Secciones de `.aosrpt`

- `[REPORT_COMPOSITION]`
- `[TABLE_PRESENTATION_<id>]`
- `[TABLE_INDEX]`
- `[TABLE_###]`
- `[TABLE_ARCHIVE_INDEX]`
- `[TABLE_ARCHIVE_###]`

## AOSCAD

En `.aoscad`, los datos completos permanecen en `tablas_entrada` y `tablas_resultados`; `report_composition` registra el modo de presentación.

## Viewer

El Viewer deberá interpretar tanto tablas visibles como archivadas `VIEWER_ONLY`, generar su menú dinámicamente y no renderizar automáticamente todas las filas al exportar PDF.

---

# 17. AOSBCK y modelo de activos

## Principio

```text
una geometría STEP
→ una definición AOSBCK
→ muchas instancias físicas livianas
```

## Identidades

- `part_number`: tipo comercial.
- `component_id`: objeto de catálogo.
- `instance_id`: ocurrencia física.
- `asset_id`: identidad transversal del activo.
- `geometry_id`: referencia geométrica.
- `environmental_source_id`: identificador futuro de una fuente ambiental asociada a un activo; su schema queda diferido.
- `environmental_event_id`: identificador futuro de un evento o detección ambiental; su schema queda diferido.

## Ubicación

- Survey + MD para pozos.
- Nodo AOSCAD o posición sobre tramo para superficie.
- Puerto, sello, brida, válvula, tanque, equipo o subcomponente cuando exista identidad propia.
- Estación o distancia sobre una tubería, además del `asset_id` del tramo.
- XYZ manual solo cuando no existe otra referencia, registrando el método y la incertidumbre.

La visualización actual es bajo demanda. El ensamblaje 3D completo continúa en roadmap. Para AOS Environmental, la descripción libre complementa la referencia espacial, pero no la reemplaza.

---

# 18. Gobierno de desarrollo distribuido

## Tipos de paquetes

### Aplicaciones/bancos editables por cada grupo

SLA, Wells, CAD, Networks, Electrical, Facilities, Geology, SCADA, Environmental, Maintenance y Viewer.

### Núcleos comunes protegidos

Runtime, Data Contracts, Fluids, Solvers, 3D Core, Reporting, Units, Validation y Catalogs.

### Integración

AOS Suite registra los bancos mediante manifests. AOS Global orquestará la integración futura.

## Regla de modificación

Un equipo puede cambiar su banco, tests, ejemplos y documentación. No puede modificar directamente un núcleo común. Una necesidad de cambio se eleva mediante RFC al propietario del núcleo, con caso, benchmark y criterio de aceptación.

## Pruebas mínimas por entrega

1. Pruebas internas del banco.
2. Pruebas de contrato.
3. Pruebas de integración.
4. Regresiones físicas.
5. Verificación de rutas y funciones duplicadas.
6. Integridad del paquete y hashes.

---

# 19. Estructura actual de carpetas

```text
src/
├── core/              física y motores históricos activos
├── menu/              interfaces públicas Octave
├── modulos/           implementación de bancos, incluido cad_topo
├── workbenches/       estructura objetivo y wrappers de bancos
├── services/          AOSBCK, fluids, geometry_3d, reporting, units...
├── solvers/           clasificación por disciplina y APIs en evolución
├── utilidades/        configuración, intercambio, reportes y validación
├── geologia/          geología y punzados
├── sensibilidad/      sensibilidades transversales
├── roadmap/           manifests de frame, bancos, servicios y solvers
└── tests/             selftests y regresiones
```

En DEV1 no se deben mover masivamente funciones desde `core/` hacia `solvers/` sin pruebas de contrato. La reorganización física se realizará gradualmente.

---

# 20. Verificación y arranque

## Inicio

```octave
cd('/ruta/AOS_0_2_0_DEV1')
clear functions
rehash
VERIFICAR_AOS_0_2_0_DEV1(false)
AOS
```

## Campaña profunda

```octave
VERIFICAR_AOS_0_2_0_DEV1(true)
```

La campaña profunda ejecuta:

- pruebas de composición de tablas HF3.5;
- regresiones heredadas 0.1.9;
- verificación completa AOSCAD R16.

## Limitación de esta construcción

La distribución fue auditada estáticamente en el entorno de generación, pero la validación dinámica final debe ejecutarse en la máquina GNU Octave del proyecto.

---

# 21. Línea histórica incorporada

## 0.1.9 R2

Restauración de gestión universal, prioridad `.aosdat`, catálogos, galerías, BES3 y path controlado.

## HF1

Conversión segura del nombre y estado del caso.

## HF2

Auditoría transversal, geología transaccional, parser seguro, vectores de catálogo, galería completa y aislamiento de selftests.

## HF3–HF3.2

Gestor completo de punzados y cierre de dependencias/contratos.

## HF3.3

Corrección del signo de tubing libre GF3.

## HF3.4

Idempotencia geológica y unificación del contrato de espaciamiento GF3.

## CAD R16

Sprints 1–7: hidráulica, lazos, 3D Core, puertos, interferencias, escena federada, sincronización y recursos visuales.

## HF3.5 integrado en DEV1

Composición transversal de tablas para todos los módulos, sensibilidades y AOSCAD.

---

# 22. Riesgos y limitaciones conocidas

1. AOSCAD R16 sigue siendo candidato a revisión y no está promovido a beta.
2. BES3 permanece `DESARROLLO_NO_VALIDADO`.
3. Varios bancos visibles contienen funciones roadmap.
4. El Viewer Alpha36 necesita completar la lectura dinámica de tablas archivadas y manifiestos HF3.5.
5. La física de redes multifásicas con lazos requiere validación adicional.
6. Los ensamblajes 3D completos no son alcance actual; se visualizan componentes bajo demanda y escenas parciales/federadas.
7. La reorganización física total de carpetas no se ejecutó para evitar regresiones.
8. ENV-02 implementa el shell runtime, pero los contratos ambientales detallados y la persistencia especializada aún no están congelados.
9. Los contratos ambientales detallados, factores de emisión, reglas de CO₂ equivalente y prevención de doble conteo aún no están congelados.
10. Toda promoción requiere pruebas dinámicas en GNU Octave y validación física externa.

---

# 23. Prioridades inmediatas de AOS 0.2.0

1. Formalizar el diseño de contratos de AOS Environmental: identidad espacial, fuentes, eventos, mediciones, actividad energética, factores, resultados, riesgo y acciones.
2. Implementar, una vez aprobados esos contratos, la persistencia, edición y validación del primer inventario ambiental sin romper el alias `AMBIENTAL`.
3. Distribuir bancos entre equipos con dependencias comunes de solo lectura.
4. Congelar contratos públicos de casos, fluidos, assets, solvers y reportes.
5. Integrar el frame gráfico con cinta y contexto compartido.
6. Adaptar Viewer al contrato HF3.5.
7. Auditar y validar cada solver por disciplina.
8. Construir paquetes independientes de banco sin duplicar cores.
9. Completar AOS Fluids como fuente oficial.
10. Validar AOSCAD R16 y decidir su promoción.
11. Ampliar SCADA, Environmental, Maintenance y Facilities.
12. Preparar el primer acoplamiento AOS Global.

---

# 24. Checklist para iniciar un chat nuevo

Adjuntar:

1. `AOS_0_2_0_DEV1_COMPLETO.zip`.
2. Este documento en Markdown o DOCX.
3. La salida de `VERIFICAR_AOS_0_2_0_DEV1(true)` cuando esté disponible.
4. El caso `.aosdat`, `.aosrpt`, `.aoscad` o `.aosbck` específico que se analizará.

Mensaje inicial sugerido:

> Continuamos AOS desde la baseline 0.2.0 DEV1 con revisión de arquitectura ENV-02. GNU Octave es el motor oficial. Antes de generar código debemos discutir la solución. El documento CONTEXTO_AOS_0_2_0_DEV1 y ADR-AOS-2026-001 son las fuentes de continuidad. AOS Environmental es un banco independiente, vinculado espacialmente a AOSCAD; Maintenance consume sus resultados y no lo absorbe. La baseline integra AOS 0.1.9 R2 HF3.4-CAD-R16 y composición transversal de tablas HF3.5. No se deben modificar núcleos comunes sin RFC, benchmark y regresión.

---

# 25. Archivos de referencia dentro de la distribución

- `AOS_VERSION.txt`
- `VERSION`
- `VERIFICAR_AOS_0_2_0_DEV1.m`
- `CHANGELOG_AOS_0_2_0_DEV1.md`
- `REGRESIONES_AOS_0_2_0_DEV1.md`
- `AUDITORIA_INTEGRACION_AOS_0_2_0_DEV1.md`
- `CONTEXTO_AOS_0_2_0_DEV1.md`
- `documentos/ARQUITECTURA_AOS_0_2_0_DEV1.md`
- `documentos/adr/ADR-AOS-2026-001_AOS_ENVIRONMENTAL_BANCO_INDEPENDIENTE.md`
- `documentos/ARQUITECTURA_AOS_ENVIRONMENTAL_0_2_0_DEV1.md`
- `src/roadmap/aos_environmental_workbench_0_2_0_dev1.json`
- `documentos/CONTRATO_REPORTES_TABLAS_AOS_HF3_5.md`
- `src/roadmap/aos_workbenches_0_2_0_dev1.json`
- `src/roadmap/aos_services_0_2_0_dev1.json`
- `src/roadmap/aos_solvers_0_2_0_dev1.json`
- `src/roadmap/aos_roadmap_0_2_0_dev1.json`
- `src/roadmap/aos_frame_ribbon_contract_0_2_0.json`

---

# 26. Cierre

AOS 0.2.0 DEV1 es la baseline para abandonar el desarrollo monolítico y comenzar el trabajo paralelo por bancos. Conserva la física y las funciones acumuladas, integra AOSCAD R16 y el subsistema de composición de tablas. ENV-01 incorporó AOS Environmental como banco independiente y ENV-02 materializa su shell runtime, manteniendo pendientes los schemas detallados y cálculos científicos.

# 27. Continuidad técnica por sistema de levantamiento

## 27.1 GL/JGL

### Filosofía de solver

JGL y GL conservan tres modos:

1. Iterativo: referencia física.
2. Directo/simple: exploración rápida.
3. Híbrido/automático: directo con verificación iterativa selectiva.

El modo iterativo define la física de referencia y debe registrar cantidad máxima de iteraciones, tolerancia, estado de convergencia y advertencias. Las sensibilidades deben permitir elegir aproximación y no ocultar puntos `NO_CONVERGE`.

### Inyección

La selección de caudal o presión de inyección debe distinguir:

- usar valor por defecto;
- forzar cualquier valor ingresado, incluido cero;
- determinar automáticamente.

Una entrada cero no puede ser reemplazada silenciosamente por el valor de configuración.

### Diseño de mandriles

La versión V2 utiliza descarga y perfiles compresibles. La galería `[MANDRILES_GALERIA]` puede viajar en `.aosdat`, y el catálogo completo conserva componentes deshabilitados o sin stock, aunque el selector físico los excluya.

### Sensibilidades

La tabla es el resultado principal. El gráfico es secundario. Deben registrarse método, iteraciones, estado y advertencias por punto. El modo abreviado transversal propone evaluación inicial simple, ajuste de envolvente y verificación iterativa fuera de tolerancia.

## 27.2 Bombeo Mecánico

### Física esperada

- Propagación de ondas en la sarta; no transmisión instantánea.
- Cinco ciclos, descartando el primero y promediando los restantes.
- Carta de superficie cerrada, apaisada y con oscilaciones.
- Carta de fondo casi rectangular, con transiciones en PMI/PMS.
- Transmisión de carrera, cargas y posición-tiempo.
- Tubería anclada o libre.

### Parámetros que deben quedar en `.aosrpt`

Todo parámetro físico usado debe registrar valor efectivo, unidad, origen, validación y advertencias. Incluye tubing, sarta, materiales, pistón, holguras, válvulas, viscosidad, fricción, gas, barras de peso y espaciamiento.

### GF3 y tubing libre

La convención obligatoria es:

```text
elongacion_tubing >= 0
u_fondo_tubing = -elongacion_tubing
u_piston_barril = u_varilla_fondo - u_fondo_tubing
```

La carta de fondo de tubing libre debe tener rigidez aparente positiva. El spacing utiliza la magnitud positiva de elongación.

### Sarta y espaciamiento

El roadmap acordado fue:

1. condición anclada/libre;
2. diseño de varillas por secciones;
3. barras de peso;
4. espaciamiento;
5. cartas finales.

Los resultados de spacing publican alias compatibles `valido`/`valido_calculo` y `validacion`/`mensaje_validacion`.

## 27.3 BES

### BES V2

Es el solver beta de Bombeo Electrosumergible y comparte núcleo eléctrico con CGF.

### BES3

Estado obligatorio: `DESARROLLO_NO_VALIDADO`.

Incluye:

- normalización de etapas y diámetros desde `.aosdat`;
- geometría respecto de punzados;
- recirculación y capilar;
- bomba a frecuencia cero;
- secciones y etapas;
- motor, cable y VSD;
- comparación V1/V2/V3;
- reportes y sensibilidades.

La ejecución satisfactoria de selftests no equivale a validación física de campo. Requiere datos OEM, comparación con software de referencia y caso real.

## 27.4 PCP/LDL, CGF y EGF

PCP y LDL permanecen en desarrollo. LDL es una tecnología propietaria AESIR dentro del ámbito PCP. CGF es beta, propietario AESIR y prioritario para pruebas. EGF permanece planificado. Todos deben consumir servicios comunes de fluidos, electricidad y reporting.

---

# 28. Contratos de datos detallados

## 28.1 `.aosdat`

El archivo puede contener secciones de:

- configuración general;
- reservorio e IPR;
- VLP;
- Survey;
- geología;
- punzados y metadatos;
- estado mecánico;
- GL/JGL;
- BES/BES3;
- BM/GF3;
- catálogos;
- galerías;
- referencias SCADA;
- origen y validación.

Los lectores deben conservar secciones desconocidas y campos adicionales para compatibilidad futura.

## 28.2 `.aosrpt`

Debe diferenciar:

- parámetros efectivos;
- resultados;
- diagnósticos;
- advertencias;
- tablas nativas;
- tablas archivadas;
- gráficos;
- Survey/geología/punzados;
- versión de Suite, banco, módulo, solver y generador;
- composición del reporte.

Abrir un `.aosrpt` debe permitir visualizar, abrir en el módulo de origen, reconstruir un `.aosdat` cuando la información sea suficiente o informar explícitamente que el reporte no permite recálculo.

## 28.3 `.aoscad`

El JSON canónico conserva:

- información del proyecto;
- fuente DXF/STEP;
- geometría y coordenadas;
- topología;
- nodos y tramos;
- equipos;
- condiciones de borde;
- fluidos;
- configuración de solver;
- tablas de entrada y resultados;
- validaciones;
- composición de tablas;
- recursos visuales en modalidad enriquecida.

## 28.4 `.aosbck`

El contenedor maestro no debe mezclar ubicaciones de proyectos diferentes. Las instancias viven normalmente en `.aosdat` o `.aoscad`; una exportación AOSBCK de proyecto puede incluirlas para transporte.

---

## 28.5 AOS Environmental — requisitos previos al diseño de contratos

ENV-01 no congela todavía schemas de datos. Sí establece condiciones obligatorias para la etapa siguiente:

- toda fuente o evento debe vincularse a un `asset_id` cuando el activo exista en AOSCAD, AOSBCK, Wells o Facilities;
- debe poder expresarse una localización más precisa mediante `component_id`, `instance_id`, puerto, subcomponente, nodo, tramo, estación, XYZ, MD o TVD;
- CH₄, CO₂ y H₂S se conservan como especies separadas; CO₂ equivalente es un resultado derivado y no sustituye la masa por especie;
- medición, estimación, balance, factor de emisión y simulación deben registrar método, origen, fecha, validación e incertidumbre;
- los módulos energéticos publican actividad; AOS Environmental selecciona factores y calcula emisiones indirectas;
- el modelo debe impedir o advertir doble conteo entre energía medida, reconciliada, simulada y estimada;
- las acciones correctivas se vinculan con Maintenance, pero el cierre ambiental exige verificación posterior;
- tablas, AOSCAD 2D/3D, reportes y Viewer consumen el mismo resultado estructurado;
- los formatos nativos permanecen abiertos, auditables y compatibles con GNU Octave.

Las entidades candidatas para el diseño posterior son `ENVIRONMENTAL_SOURCE`, `ENVIRONMENTAL_EVENT`, `ENVIRONMENTAL_MEASUREMENT`, `ENERGY_ACTIVITY`, `EMISSION_FACTOR`, `ENVIRONMENTAL_RESULT`, `ENVIRONMENTAL_RISK` y `ENVIRONMENTAL_ACTION`. Sus campos, cardinalidades, unidades y reglas de precedencia requieren una revisión específica antes de escribir código.

---

# 29. AOS Viewer y política de visualización

El Viewer debe construir su menú lateral únicamente con contenido existente y no vacío. Cada tabla, gráfico, Survey, geología, plano, topología, topografía o bloque técnico tiene una pantalla propia.

## Reglas

- Una tabla no se reemplaza por un gráfico.
- Las tablas `VIEWER_ONLY` deben seguir accesibles.
- Una sección ausente no genera un botón vacío.
- Los objetos desconocidos se muestran con una vista genérica.
- La selección de una fila puede vincularse con un punto, nodo, tramo o componente 3D.
- `NaN`, `Inf`, `NO_CONVERGE`, `FUERA_DE_RANGO`, `DATO_ASUMIDO` y `NO_VALIDADO` no se ocultan.

## Problemas históricos que no deben reaparecer

- Manifest con cero tablas pese a que el reporte contiene tablas.
- Resumen ejecutivo leyendo campos legacy y contradiciendo GF3.
- Punzados presentes en una sección, pero declarados ausentes en otra.
- Versión del generador hardcodeada.
- Impresión automática de cientos de páginas de puntos sin preguntar.

HF3.5 resuelve el lado AOS de composición; el equipo Viewer debe completar la lectura del nuevo contrato.

---

# 30. Casos de pozo usados como continuidad

## MB01

Valores históricos de referencia:

- presión de reservorio: 183,7 bar;
- presión de burbuja: 100 bar;
- IP: 12,141 m³/d/bar;
- WC: 0,45;
- GLR: 117,06 Sm³/m³;
- presión de cabeza: 11,8 bar;
- presión de inyección superficial: 91,3 bar;
- profundidad de inyección: 1903,7 m;
- profundidad de reservorio: 2631,1 m;
- caudal de inyección: 16486 Sm³/d;
- IPR lineal;
- VLP Duns & Ros;
- Survey de siete puntos;
- cinco tramos de punzados.

Este caso fue importante para detectar inconsistencias de flujo natural y override de inyección.

## MX01b

- presión de reservorio: 137,3 bar;
- IP: 8,737 m³/d/bar;
- WC: 0,53;
- GLR: 155,10 Sm³/m³;
- presión de cabeza: 11,8 bar;
- presión de inyección superficial: 86,7 bar;
- profundidad de inyección: 2035,6 m;
- reservorio: 2499,3 m;
- caudal de inyección: 18113 Sm³/d.

## Supati X1 / SUP-X1 ST

Caso recurrente para Survey, estado mecánico, punzados y BM. El Survey puede reducirse a uno de cada diez puntos para intercambio, siempre preservando geometría suficiente. La simulación debe partir del packer cuando corresponda. Los reportes BM recientes sirvieron para detectar:

- regresión de signo en tubing libre;
- exceso de páginas por tablas de 721 puntos;
- inconsistencias de resumen/manifest del Viewer;
- necesidad de gestionar punzados y reportes de forma transversal.

Estos valores son referencias de continuidad, no defaults universales.

---

# 31. Menús operativos clave

## AOS SLA

```text
1 Gas Lift/JGL
2 BES
3 Bombeo Mecánico
4 PCP
5 CGF
6 EGF
7 Comparación de sistemas
8 Herramientas comunes
9 Abrir/importar/configurar caso
```

## Bombeo Mecánico

```text
1 Simulación BM/Gibbs
2 Sensibilidades
3 Diseño de sarta
4 Cartas
5 Diagnóstico
6 Energía y economía
7 Catálogos
8 Reportes y Viewer
9 Exportar última corrida
10 Abrir/importar/configurar caso
```

## AOS CAD

```text
1 CAD 2D/DXF
2 CAD 3D/STEP
3 Topología y datos
4 Simulación hidráulica
5 Reportes .aoscad
6 Sincronización
7 Diagnósticos
8 AOS 3D Core
9 Abrir/importar/configurar
10 Galerías
```

## AOS Solvers

```text
1 Hidráulicos
2 Eléctricos
3 Mecánicos
4 Térmicos
5 Geológicos
6 Reservorio
7 Producción y SLA
8 Multifísicos
9 Redes y grafos
10 Optimización
11 Económicos
12 Confiabilidad
13 Fluidos
14 Registro general
15 Benchmarks
16 Validación y regresiones
17 Configuración numérica
18 Roadmap
```

---

# 32. Reglas de empaquetado y baselines

Cada distribución debe incluir:

- versión semántica;
- manifest de archivos;
- SHA-256;
- changelog;
- regresiones;
- verificador;
- documentación de contratos;
- ejemplos mínimos;
- estado de madurez.

Un instalador no debe usar únicamente el hash de `AOS_VERSION.txt` para decidir compatibilidad. Debe validar versión semántica y archivos funcionales críticos, porque ramas integradas pueden modificar legítimamente los metadatos.

Los respaldos se crean fuera de la raíz de AOS. Ningún verificador debe rechazar su propio backup.

---

# 33. Desarrollo por equipos

## Equipo Suite/Frame

Responsable de menú, cinta, proyecto compartido, versiones, plugins, navegación y contexto.

## Equipo SLA

Responsable de GL/JGL, BES, BM, PCP, CGF/EGF, comparación y sensibilidades.

## Equipo Wells/Geology

Responsable de Survey, punzados, completación, estado mecánico, capas y geometría del pozo.

## Equipo CAD/3D

Responsable de DXF, STEP, AOSCAD, AOSBCK, topología, escena y sincronización.

## Equipo Networks

Responsable de solver de red, condiciones de borde, dominios, lazos y resultados nodales.

## Equipo Electrical/Facilities

Responsable de redes eléctricas e instalaciones de superficie.

## Equipo Fluids

Responsable de PVT y propiedades oficiales.

## Equipo Environmental/HSE

Responsable de inventarios y eventos ambientales, emisiones directas y fugitivas, derrames, energía y CO₂ indirecto, riesgo, mitigación, cumplimiento, integración espacial con AOSCAD y trazabilidad de resultados. No es un subequipo de Maintenance.

## Equipo Maintenance/Reliability

Responsable de integridad, confiabilidad, pulling, priorización y ejecución de acciones correctivas. Consume criticidad y recomendaciones ambientales mediante contratos públicos.

## Equipo Data/Reporting

Responsable de contratos, importación/exportación, catálogos, HF3.5 y Viewer contract.

## Equipo Core/Solvers

Responsable exclusivo de núcleos científicos protegidos.

## QA/Validation

Responsable de benchmarks, regresiones, casos dorados, integridad de paquetes y aprobación de madurez.

---

# 34. Do-not-regress list

1. No perder importación desde el menú principal ni desde cada módulo.
2. No perder prioridad del `.aosdat`.
3. No eliminar catálogos embebidos ni galerías.
4. No esconder BES3 del menú.
5. No volver a usar `genpath` indiscriminado.
6. No introducir `.mat`.
7. No usar preguntas `s/n` para seleccionar entre acciones distintas.
8. No intentar `num2str` o `char` sobre tipos no validados.
9. No eliminar punzados inactivos ni metadatos durante round-trip.
10. No invertir el signo de tubing libre GF3.
11. No imprimir automáticamente tablas masivas sin composición.
12. No perder recursos visuales R16 al escribir `.aoscad` enriquecido.
13. No duplicar geometrías STEP para cada instancia AOSBCK.
14. No promover un módulo sin aprobación, benchmark y evidencia.
15. No modificar un core desde un banco de trabajo.
16. No volver a clasificar AOS Environmental como una función interna de Maintenance.
17. No registrar un evento ambiental únicamente con texto libre cuando existe identidad física disponible.
18. No calcular CO₂ indirecto de forma divergente dentro de cada banco consumidor de energía.
19. No mezclar H₂S, CH₄ y CO₂ en un único valor sin preservar la masa y el método por especie.

---

# 35. Criterio de aceptación de DEV1 y de la revisión ENV-02

La baseline se considera lista para distribución interna cuando en GNU Octave:

```text
VERIFICAR_AOS_0_2_0_DEV1(false) = aprobado
VERIFICAR_AOS_0_2_0_DEV1(true)  = aprobado
```

Además:

- el menú runtime abre 15 bancos;
- AOS Environmental aparece entre SCADA y Maintenance;
- AOS Environmental figura como `ROADMAP_RUNTIME_SHELL` y `runtime_available=true`;
- Viewer está último;
- AOSCAD mantiene R16 y su estado candidato;
- los tests HF3.5 pasan;
- no existen `.mat`;
- no hay nombres `.m` duplicados en `src`;
- el escritor AOSCAD conserva recursos R16 y composición de tablas;
- los contratos JSON son válidos y el ZIP y sus hashes son reproducibles.


# Enmienda de runtime ENV-02

ENV-02 implementa el entrypoint independiente `AOS_menu_environmental` y registra quince workbenches en GNU Octave. AOS Environmental aparece después de SCADA y antes de Maintenance. El alcance runtime actual es un shell de navegación y contratos; las ecuaciones, schemas detallados, factores, importadores y reportes ambientales especializados permanecen pendientes. `AOS_menu_gestion_ambiental` se conserva como alias histórico.
