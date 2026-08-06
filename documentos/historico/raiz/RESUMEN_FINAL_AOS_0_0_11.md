# AOS 0.0.11 — Versión final para archivo

**Proyecto:** AOS — AESIR Oilfield Simulation  
**Estado:** versión consolidada y congelada para benchmark  
**Fecha de archivo:** 11 de julio de 2026  
**Siguiente rama:** AOS 0.0.12 — solver JGL continuo y acoplado GL–eductor

---

## 1. Propósito de esta versión

AOS 0.0.11 consolida la arquitectura desarrollada hasta el cierre del motor Gas Lift de benchmark. Esta copia se entrega limpia, sin carpetas de respaldo de parches y con los cambios de las revisiones 0.0.11c, 0.0.11d, 0.0.11e y 0.0.11f integrados directamente en el código base.

La versión queda destinada a:

- archivo histórico del proyecto;
- ejecución de benchmarks GL;
- comparación contra PROSPER;
- punto de partida reproducible para AOS 0.0.12;
- recuperación del proyecto si una rama futura introduce regresiones.

---

## 2. Convención de unidades

AOS usa unidades métricas como sistema principal de interacción:

- presión: **bar**;
- profundidad y longitud: **m**;
- caudal líquido, petróleo y agua: **m³/d**;
- gas producido e inyectado: **Sm³/d**;
- diámetro: **mm** o **m**, según el bloque de cálculo;
- temperatura: **°C**.

Las unidades imperiales aparecen entre paréntesis como referencia secundaria:

- psi;
- ft;
- bpd / bopd / bwpd;
- MMscf/d.

El núcleo conserva conversiones internas a SI cuando una ecuación lo requiere, pero el usuario no debe ingresar presiones en Pa.

---

## 3. Importación y administración de `.aosdat`

Se consolidó la carga automática de:

- parámetros de reservorio;
- fluidos;
- IPR y VLP;
- survey;
- profundidad efectiva de inyección/levantamiento;
- geometría de tubing y casing;
- geología;
- intervalos de punzados;
- parámetros de sistemas de levantamiento;
- valores de benchmark y referencias operativas.

Cuando un `.aosdat` contiene geología y punzados, AOS los activa directamente sin exigir una segunda carga desde el menú.

Se separaron conceptualmente las profundidades usadas por cada SLA:

- GL/JGL: profundidad de inyección o levantamiento;
- BM: profundidad de bomba;
- BES: profundidad de intake/bomba según el módulo.

La profundidad editada en el menú se propaga al solver, gráficos, diagnóstico y reportes.

---

## 4. Survey y punzados

El visor de survey incorpora:

- trayectoria MD–TVD;
- inclinación y azimut;
- trayectoria 3D;
- geometría hidráulica;
- intervalos de punzados;
- track específico de tiros por metro;
- zoom automático de la zona punzada.

El zoom evita que los intervalos queden comprimidos por la escala total del pozo.

---

## 5. Geología distribuida y operativa

La producción ya no se concentra en `midperf` como un único punto. El caudal se distribuye entre todos los intervalos y tiros activos.

Para cada intervalo se calculan, según la información disponible:

- cantidad de tiros;
- fracción de aporte;
- Ql, Qo y Qw;
- caudal por tiro;
- transmisibilidad relativa;
- presión y riesgo local.

Si no existen propiedades diferentes por intervalo, el reparto se realiza proporcionalmente a los tiros. Si existen permeabilidad, skin, espesor neto u otros datos locales, se utiliza una ponderación de transmisibilidad.

La geología puede operar con tres niveles:

1. **Específica:** datos medidos o interpretados suficientes.
2. **Mixta:** combinación de datos reales, correlaciones y analogías.
3. **Genérica:** modelo representativo construido con la información disponible.

Cuando faltan datos, AOS no bloquea el análisis. Genera escenarios conservador, probable y favorable, indica las hipótesis y asigna un nivel de confianza.

La conificación genérica se presenta como screening y no como límite operativo vinculante cuando faltan datos fundamentales. Un mecanismo no evaluable no se convierte en cero ni participa automáticamente del mínimo de caudal seguro.

Los gráficos geológicos quedan reservados para `.aosrpt` enriquecido. El `.aosrpt` liviano conserva únicamente datos y resultados numéricos.

---

## 6. Auditoría matemática del motor GL

La revisión 0.0.11f consolidó las principales correcciones matemáticas y numéricas:

### IPR

- corrección de la inversión de Vogel compuesto debajo de presión de burbuja;
- uso coherente del caudal incremental debajo de Pb;
- unidades explícitas y trazables;
- soporte de modelos Linear, Vogel y Fetkovich.

### Tramo reservorio–inyección

- hidrostática calculada con TVD, no con diferencia de MD;
- propiedades locales del gas;
- separación entre gas disuelto y gas libre;
- respeto de la profundidad efectiva del nodo de levantamiento.

### Solver nodal

- barrido completo del dominio de caudal;
- detección de cambios de signo;
- refinamiento por bisección robusta;
- detección del cruce aunque el muestreo inicial no caiga exactamente sobre la raíz;
- eliminación del falso resultado `Ql = 0` cuando existe un cruce visible;
- gráfico y solver alimentados por el mismo balance nodal.

### VLP

- selección y trazabilidad del modelo efectivo;
- reporte de fallback;
- identificación explícita de las implementaciones actuales de Duns & Ros y Hagedorn–Brown como versiones AOS estabilizadas/simplificadas, pendientes de desarrollo canónico completo.

---

## 7. Diagnósticos operativos

Se estableció la regla:

> El solver calcula. El diagnóstico advierte. El usuario decide.

Turner, erosión, régimen de flujo, límites de garganta y otras restricciones operativas no deben modificar silenciosamente el resultado físico. Se reportan mediante semáforos y mensajes de estado.

Estados típicos:

- verde: condición aceptable;
- amarillo: precaución o incertidumbre;
- rojo: riesgo operativo o resultado no factible.

---

## 8. Formatos de reporte

### `.aosrpt`

Formato ultraliviano para:

- parámetros;
- resultados;
- diagnósticos;
- tablas numéricas;
- trazabilidad del modelo.

### `.aosrpt` enriquecido

Previsto para:

- gráficos;
- comentarios;
- conclusiones;
- fotografías;
- notas de voz;
- documentos asociados;
- evidencia de campo.

Los archivos pesados deben mantenerse por referencia para conservar la filosofía de archivos livianos.

---

## 9. Benchmarks GL alcanzados

### Supati X1 ST

Caso principal de referencia contra PROSPER. Se corrigieron:

- Pwh;
- Pb y sus unidades;
- GOR convertido a GLR sobre líquido total;
- profundidad efectiva de inyección;
- survey y punzados;
- geología distribuida.

El caso queda aprobado como benchmark preliminar, con el requisito de mantener separadas las configuraciones de 1945,4 m y aproximadamente 3600 m de profundidad de inyección.

### Familia MB

Resultados finales aproximados frente a PROSPER:

| Pozo | Error AOS vs PROSPER |
|---|---:|
| MB01 | +5,6 % |
| MB02 | −1,7 % |
| MB03 | −5,6 % |

La familia MB queda dentro de una banda aproximada de ±6 %, con MB02 por debajo del 2 %.

### Familia MX

El parche 0.0.11f resolvió el falso `Ql = 0` cuando existía cruce nodal. Los casos MX siguen condicionados por datos reconstruidos e hipótesis de tubing/IPR/PVT:

- MX01b: cruce detectado, pero capacidad superior a la referencia;
- MX02b: mejora importante al usar tubing 2 3/8, aunque todavía sobreestima el caudal.

Estos casos se conservan como benchmarks de investigación, no como base para modificar el solver general sin confirmar datos originales.

---

## 10. Módulos incluidos en AOS 0.0.11

- Jet Gas Lift — foundation, pendiente del nuevo solver 0.0.12;
- Gas Lift convencional;
- BES;
- Bombeo Mecánico / Gibbs foundation;
- sensibilidad JGL/GL;
- sensibilidad BES;
- diseño de mandriles;
- calibración;
- survey y punzados;
- geología operativa;
- importación/exportación `.aosdat` y `.aosrpt`;
- reportes y semáforos operativos.

---

## 11. Límites conocidos

- JGL todavía no posee el solver continuo y acoplado GL–eductor definido para 0.0.12.
- Las correlaciones DR/HB actuales no son implementaciones canónicas completas.
- La geología genérica es orientativa y debe mostrar siempre su nivel de confianza.
- Algunos casos reconstruidos desde informes parciales dependen de supuestos de tubing, PVT, IPR, survey y profundidad.
- La ejecución final debe realizarse en GNU Octave.

---

## 12. Inicio de AOS 0.0.12

La siguiente versión se enfocará en Jet Gas Lift mediante un modelo continuo, no discreto:

- GL como base hidráulica;
- eductor de fondo como transferencia de energía y cantidad de movimiento;
- interacción gas–líquido;
- balance energético limitado por potencia motriz disponible;
- acoplamiento iterativo GL ↔ eductor;
- convergencia asintótica;
- transición continua desde comportamiento similar a GL hasta comportamiento similar a Jet Lift;
- ausencia de pisos hardcodeados o resultados físicamente imposibles.

---

## 13. Regla de archivo

Esta versión debe conservarse sin modificaciones bajo el nombre:

```text
AOS_0_0_11_FINAL_ARCHIVO
```

Todo desarrollo posterior debe realizarse en una copia o rama separada.
