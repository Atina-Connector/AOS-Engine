# AOS - Reporte de trabajo y arquitectura final alcanzada

Fecha: 2026-07-07  
Proyecto: AOS - AESIR Oilfield Simulation  
Plataforma objetivo actual: GNU Octave  
Estado: versión limpia integrada, pendiente de validación completa en Octave local

---

## 1. Contexto general

AOS nació como un desarrollo inicial orientado a correr casos de Jet Gas Lift y Gas Lift puro sobre un pozo de prueba. El nombre original de carpeta, `AOS KONA12D`, quedó heredado de esa etapa temprana. Durante la limpieza previa se renombró el proyecto a `AOS`, porque el alcance real ya no es un caso de pozo sino una plataforma de ingeniería de producción.

La visión consolidada al día de hoy es que AOS no sea solo un simulador de escritorio, sino un ecosistema liviano para operación y análisis en campo. El ingeniero debe poder correr una simulación en PC, tablet o celular, compartir el caso o el reporte por medios de baja conectividad, y permitir que otro colega lo abra, revise, modifique parámetros y vuelva a correrlo.

El objetivo de diseño queda resumido así:

```text
AOS Core + .aosdat + .aosrpt + Viewer/App = ecosistema portátil de ingeniería de producción
```

AOS debe ser usable desde abajo hacia arriba en la organización: bajo costo, baja fricción, sin licencias por workstation, y con intercambio de información apto para zonas con conectividad limitada.

---

## 2. Trabajo realizado hasta hoy

### 2.1 Limpieza inicial del proyecto

Se generó una base limpia llamada `AOS/`, eliminando la dependencia del nombre heredado `AOS KONA12D`.

Cambios principales:

- Se normalizó la carpeta raíz como `AOS/`.
- Se eliminó el historial extenso de `avance/`, dejando solo documentación de contexto y el presente reporte.
- Se corrigieron rutas heredadas que apuntaban a `config/GL_JGL/` y se unificaron hacia `config/GL/`.
- Se corrigieron rutas raíz mal calculadas en scripts ubicados dentro de `src/menu/`, `src/sensibilidad/` y utilidades.
- Se removió la duplicación `src/src/`, interpretada como residuo de migración.
- Se agregó `aos_starts_with.m` para evitar dependencia de `startsWith` y mantener compatibilidad con GNU Octave.
- Se regeneró `mapa_actual.txt`.

### 2.2 Corrección de gráficos GL/JGL

Se detectó que al correr Gas Lift convencional solo aparecía el gráfico nodal y no el gráfico de erosión/Taitel. Se creó una primera solución y luego se evolucionó hacia un módulo común.

Cambios incorporados:

- Se agregó `plot_erosion_taitel.m`.
- Se agregó el diagnóstico gráfico de tubería a Gas Lift convencional.
- Se incorporó `drawnow` en flujos gráficos para forzar renderizado en Octave.
- Se corrigieron casos donde el survey era pobre o sintético.

### 2.3 Survey y `.aosdat`

Se detectó que un `.aosdat` con survey de solo dos puntos generaba una visualización no representativa del pozo. Se comprobó que Taitel salía plano porque la trayectoria era una recta definida solo por superficie y fondo.

Se generó un archivo de caso con 15 puntos:

```text
MB01_15pts_2tercios_vertical.aosdat
```

Criterio usado:

- Primeros 2/3 de la tubería: vertical, con `MD = TVD` e inclinación 0°.
- Último 1/3: desvío aplicado proporcionalmente hasta el fondo.
- Fondo conservado del caso base: `MD = 3299 m`, `TVD = 2613 m`, inclinación final 37.6°.

Ese archivo produjo una visualización más realista y confirmó que el problema no era solo gráfico sino de calidad del survey de entrada.

También se generó:

```text
MB01_calibracion_factor1.aosdat
```

con `factor_VLP=1.0`, dejando el resto del caso igual al survey de 15 puntos.

Ambos archivos quedaron incluidos como ejemplos en:

```text
datos/ejemplos/
```

### 2.4 Módulo común de tubería de producción

Se consolidó la idea de que erosión, carga de líquido y régimen Taitel no pertenecen a un sistema artificial específico. Aguas arriba del sistema de levantamiento, todos los métodos comparten fenómenos de tubería.

Se creó un módulo común:

```text
src/utilidades/diagnostico/diagnostico_tuberia_produccion.m
src/utilidades/diagnostico/calcular_perfil_tuberia_produccion.m
src/utilidades/graficos/plot_erosion_taitel.m
```

Este módulo es utilizado por:

- JGL.
- Gas Lift convencional.
- BES.
- Bombeo Mecánico.

Y queda preparado para futuros sistemas artificiales.

El gráfico común incluye:

1. Trayectoria MD/TVD.
2. Velocidades de gas, líquido y mezcla.
3. Límite erosivo simplificado.
4. Criterio de carga de líquido tipo Turner simplificado.
5. Régimen Taitel-Dukler simplificado/orientativo.
6. Perfil de gas de formación, gas inyectado y gas total.
7. Resumen numérico del diagnóstico.

Se adoptó explícitamente la convención de survey petrolero:

```text
0°  = vertical
90° = horizontal
```

### 2.5 Corrección de inconsistencia JGL / VLP

Se detectó una inconsistencia en JGL: el solver encontraba producción, pero el gráfico nodal mostraba que la VLP requerida era mayor que la presión entregada por el eductor.

El problema conceptual era que el solver y el gráfico no estaban usando exactamente el mismo balance.

Se creó una función común:

```text
src/utilidades/nodal/jgl_nodal_presiones.m
```

Ahora solver y gráfico usan el mismo residuo:

```text
residuo = P_d_eductor - P_req_VLP
```

Criterio:

```text
residuo > 0  : el eductor tiene presión suficiente
residuo = 0  : cruce nodal exacto
residuo < 0  : el eductor no alcanza la VLP requerida
```

En la corrida posterior se verificó que el cruce quedó consistente:

```text
P_entrega_sol = P_req_sol
Margen ≈ 0 bar
```

Esto cerró la advertencia heredada de inconsistencia VLP.

### 2.6 Revisión de Taitel

El clasificador Taitel fue revisado para evitar que todo el trayecto quedara marcado como slug sin diferenciación.

Estado actual:

- Sigue siendo un criterio simplificado y orientativo.
- No reemplaza la correlación VLP de cálculo.
- No debe actuar como restricción de caudal.
- Debe presentarse como diagnóstico de régimen/carga, no como verdad absoluta.

En el caso MB01 con survey de 15 puntos se observó una separación más razonable:

- Transición en la zona superior con gas inyectado.
- Slug en la zona inferior donde solo actúa gas de formación.

### 2.7 Sensibilidades

Se detectó que los módulos de sensibilidad podían usar una base distinta de la última simulación, generando diferencias entre “Simular JGL” y “Sensibilidad JGL vs GL”.

Se revisaron los módulos de sensibilidad:

```text
sens_Qiny.m
sens_Qiny_JGL.m
sens_Qiny_GL.m
sens_P_iny.m
sens_P_wh.m
sens_D_bomba.m
sens_A_n.m
sens_d_t.m
sens_balance_energetico.m
sens_etapas_BES.m
sens_sumergencia_BES.m
```

Se descartó la prioridad automática silenciosa porque podía parecer hardcodeo. Se reemplazó por una fuente explícita elegida por el usuario.

Ahora las sensibilidades pueden preguntar:

```text
1 - configuración importada (.aosdat)
2 - última simulación ejecutada
3 - configuración por defecto del proyecto
```

Esto evita ambigüedades y deja claro sobre qué base se hace cada barrido.

También se agregó el punto de referencia de Qiny cuando corresponde, para comparar directamente contra la corrida o configuración elegida.

### 2.8 Nueva función de configuración base

Se formalizó el rol de `config/` dentro de la arquitectura.

Antes, `config/` mezclaba defaults, catálogos y casos importados. Ahora se adopta esta filosofía:

```text
config/       = defaults generales y catálogos
.aosdat       = caso real de simulación
ajustes       = cambios temporales hechos durante la corrida de cualquier módulo
.aosrpt       = resultado reproducible de lo efectivamente usado
```

Se agregó:

```text
src/utilidades/config/aos_config_base.m
```

Su función es resolver la configuración base de cualquier módulo con este criterio:

1. Cargar defaults generales desde `config/`.
2. Si hay `.aosdat` activo, pisar esos defaults con el caso importado.
3. Completar campos mínimos para el módulo.
4. No modificar automáticamente el `.aosdat` original.
5. Dejar trazabilidad de la fuente usada.

Los menús principales de simulación ahora usan esta resolución común:

```text
JGL
GL convencional
BES
BM
```

### 2.9 Limpieza de `config/`

Para reforzar la filosofía anterior, los casos importados heredados fueron retirados de `config/importados/` y movidos a:

```text
datos/ejemplos/importados_legacy/
```

El importador `.aosdat` mantiene compatibilidad con `config/importados/` como ruta legacy, pero las rutas preferidas pasan a ser:

```text
intercambio/pozos/recibidos/
datos/ejemplos/
datos/ejemplos/importados_legacy/
```

El importador CSV también fue actualizado para buscar archivos operativos fuera de `config/`.

### 2.10 Renombrado definitivo de `corrida` a `JGL`

Se eliminó el nombre heredado `corrida` para el módulo Jet Gas Lift.

Cambios de nombre:

```text
src/menu/corrida_menu.m      -> src/menu/JGL_menu.m
src/core/GL/corrida_core.m   -> src/core/GL/JGL_core.m
```

Y se actualizaron las llamadas internas:

```text
AOS_app.m          llama JGL_menu
JGL_menu.m         llama JGL_core
JGLsim.m           llama JGL_core
JGLsim_fixedQ.m    llama JGL_core
```

Los archivos heredados `JGLsimold.m` y `JGLsim_fixedQold.m` fueron removidos de la ruta principal.

---

## 3. Arquitectura final acordada

La arquitectura conceptual queda separada en capas.

### 3.1 AOS Core

Contiene los modelos físicos y numéricos:

```text
IPR
VLP
PVT
JGL
GL
BES
BM
Diagnóstico común de tubería
Sensibilidades
```

El Core no debería depender de pantallas, WhatsApp, Viewer ni almacenamiento externo. Debe poder correr localmente y sin conexión.

### 3.2 AOS Data

Capa de datos del caso:

```text
.aosdat
config/
catálogos
importadores SCADA
importadores CSV
survey
geología
punzados
```

Regla principal:

```text
config/ nunca debe pisar un .aosdat cargado
```

Flujo recomendado:

```text
1. AOS carga defaults desde config/
2. Si hay .aosdat, el caso pisa los defaults
3. El usuario ajusta parámetros en cualquier módulo
4. La simulación corre con la estructura efectiva en memoria
5. El .aosrpt guarda lo efectivamente usado
6. Si corresponde, se exporta un nuevo .aosdat calibrado
```

### 3.3 AOS Report

Capa de reportes e intercambio.

Se consolidan dos tipos de `.aosrpt`:

#### `.aosrpt` común

Reporte liviano, plano y reproducible. Debe poder viajar con conectividad baja.

Debe contener:

```text
caso
versión AOS
modelo usado
parámetros efectivos
resultados principales
advertencias
instrucciones mínimas para reproducir
```

#### `.aosrpt` enriquecido

Reporte para Viewer y presentaciones. Puede incluir gráficos embebidos, layouts, comentarios y exportación PDF.

Debe seguir siendo opcional porque, si se tiene la app, los gráficos pueden regenerarse.

### 3.4 AOS Apps / Viewer

Capa de interacción:

```text
PC
Tablet
Celular
Viewer
Exportación PDF
Compartir por WhatsApp/mail/otros medios
```

El Viewer debe permitir abrir `.aosrpt` enriquecidos, armar presentaciones y exportar a PDF. Si el receptor no tiene la app instalada, el flujo ideal es redireccionarlo al store correspondiente.

### 3.5 AOS Low Connectivity

AOS debe poder operar sin Internet.

Niveles propuestos de intercambio:

```text
Nivel 1 - SMS / texto ultra compacto
Nivel 2 - .aosrpt común liviano
Nivel 3 - .aosrpt enriquecido
Nivel 4 - .aosdat completo editable
```

Nada crítico debe depender de gráficos embebidos.

Ejemplo conceptual de mensaje mínimo:

```text
AOS1|MB01|JGL|QL=158|QO=87|QG=0.582|PWF=33.4|PD=39.5|VLP=DR|WARN=CARGA
```

---

## 4. Estructura funcional actual

### Módulos principales

```text
src/menu/JGL_menu.m
src/menu/GL_puro_menu.m
src/menu/BES_app.m
src/menu/BM_menu.m
```

### Motores principales

```text
src/core/GL/JGL_core.m
src/core/GL/GL_puro_core.m
src/core/BES/BES_sim.m
src/core/BM/BM_core.m
```

### VLP/IPR/PVT comunes

```text
src/core/common/vlp/
src/core/common/ipr/
src/core/common/pvt/
```

### Diagnóstico común de tubería

```text
src/utilidades/diagnostico/diagnostico_tuberia_produccion.m
src/utilidades/diagnostico/calcular_perfil_tuberia_produccion.m
src/utilidades/graficos/plot_erosion_taitel.m
```

### Nodal JGL consistente

```text
src/utilidades/nodal/jgl_nodal_presiones.m
src/utilidades/nodal/eductor_jgl.m
src/utilidades/nodal/plot_nodal.m
```

### Configuración común

```text
src/utilidades/config/aos_config_base.m
```

### Sensibilidades

```text
src/sensibilidad/
```

---

## 5. Estado técnico y pendientes

### Cerrado o encaminado

- Limpieza de nombre de proyecto.
- Corrección de rutas `config/GL_JGL`.
- Survey de 15 puntos para MB01.
- Módulo común de tubería.
- Gráfico erosión/carga/Taitel común.
- Inconsistencia JGL/VLP corregida a nivel de balance nodal.
- Sensibilidades con fuente explícita.
- Configuración base común para módulos.
- Renombrado de `corrida` a `JGL`.

### Pendiente de validación numérica

- Comparación fina AOS vs Prosper para MB01.
- Calibración del modelo de eductor JGL.
- Equivalencia exacta de IPR/VLP con el caso Prosper.
- Ajuste de factores de calibración (`factor_VLP`, posibles factores de eductor/IPR).
- Validación de BES y BM con casos reales.
- Formalización definitiva del formato `.aosrpt` común y enriquecido.
- Diseño futuro del mensaje compacto tipo SMS.

### Advertencia de validación

La integración del ZIP limpio fue validada de forma estática en este entorno: rutas, referencias internas, nombres de archivos, estructura y consistencia lógica. No se ejecutó GNU Octave aquí, porque este entorno no lo tiene instalado. La prueba funcional final debe hacerse en tu Octave local.

---

## 6. Filosofía final resumida

AOS debe permanecer:

```text
liviano
portable
Octave-compatible en esta etapa
offline-first
apto para baja conectividad
orientado al ingeniero de producción
barato o casi gratis para adopción amplia
```

El núcleo del sistema no es solo el solver. El verdadero valor está en el ecosistema:

```text
.aosdat  -> define el caso
AOS Core -> calcula
.aosrpt  -> comunica y reproduce
Viewer   -> interpreta, presenta y exporta
```

La arquitectura lograda hoy deja a AOS mejor preparado para crecer desde una herramienta de campo hacia una plataforma de ingeniería de producción usada por equipos completos.
