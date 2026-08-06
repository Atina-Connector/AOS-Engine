# AOS 0.0.11 - Cambios de fisica y arquitectura

## Objetivo

AOS 0.0.11 consolida una regla central de la plataforma:

> El solver calcula. El diagnostico informa. El postproceso solo repara discontinuidades numericas locales de forma trazable.

Esta version elimina correcciones de software que modificaban resultados fisicos y refuerza la formulacion de Jet Gas Lift como Gas Lift convencional mas trabajo transferido por el eductor.

---

## 1. Jet Gas Lift

### Criterio fisico

Para un mismo pozo, mismo fluido, mismo survey y mismo caudal de gas inyectado:

```text
JGL = GL convencional + trabajo del eductor
```

El Gas Lift convencional aliviana la columna. El Jet Gas Lift, ademas de alivianar la columna, transfiere trabajo desde el gas motriz al fluido producido mediante el eductor.

### Invariante INV-JGL-001

```text
Q_JGL >= Q_GL
```

Si AOS calcula `Q_JGL < Q_GL`, no corrige el valor con un piso numerico. Lo reporta como violacion del invariante fisico, porque eso indica revisar el modelo, datos de entrada, presion motriz, eficiencia, geometria del eductor, VLP o unidades.

### Eliminado

Se elimina la logica de tipo:

```octave
Ql_JGL = max(Ql_JGL, Ql_GL)
```

---

## 2. Trabajo del eductor

El eductor calcula una presion de descarga:

```text
P_d = P_s + DeltaP_eductor
```

Con:

```text
DeltaP_eductor >= 0
```

Para `Qiny = 0`, el trabajo del eductor es nulo y JGL degenera al comportamiento base sin energia motriz adicional.

---

## 3. Sensibilidades

Las sensibilidades conservan dos conjuntos de datos:

```text
curva cruda
curva procesada
```

La curva procesada puede reparar discontinuidades numericas locales aisladas mediante interpolacion polinomica local de grado 4. Si el polinomio sobreoscila o rompe la monotonia local, se usa una aproximacion lineal local.

La reparacion no se aplica a:

- bordes del barrido;
- `Qiny = 0`;
- varios puntos consecutivos;
- cambios fisicos sostenidos.

---

## 4. SLA Intake Guard

Se agrega/normaliza un criterio comun para Sistemas de Levantamiento Artificial:

```text
JGL
GL
BES
BM
PCP futuro
Jet Lift futuro
```

Si el reservorio no puede sostener el nivel de intake requerido por el SLA, AOS lo informa como diagnostico operacional. No debe maquillar el resultado.

---

## 5. Diagnosticos operativos

Turner, velocidad de garganta, erosion, carga liquida y limites de intake son diagnosticos. No deben apagar automaticamente la produccion ni modificar el caudal calculado salvo que el usuario active en el futuro un modo explicito de restricciones operativas.

---

## 6. Presion de burbuja

La presion de burbuja se ingresa en bar en los menus operativos y se normaliza internamente a Pa. Se mantiene compatibilidad defensiva con valores antiguos en Pa.

---

## 7. VLP efectiva

El solver y el grafico nodal deben informar la VLP seleccionada y la VLP efectiva usada. Si hay fallback al modelo simplificado, AOS debe informarlo explicitamente.

---

## 8. Punzados

Los punzados cargados desde `.aosdat` deben quedar disponibles para geologia, reportes y futuros modulos:

```text
CONFIG_ACTIVA.punzados
CONFIG_ACTIVA.geologia.intervalos
geologia.intervalos
```

---

## Estado

AOS 0.0.11 es una version completa de desarrollo. El objetivo principal no es agregar funcionalidades de interfaz, sino corregir la base fisica y evitar que el software acomode resultados que deben surgir del modelo.
