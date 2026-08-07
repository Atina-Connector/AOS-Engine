# SENS-GLJGL-03 - Condicion motriz y presiones requeridas JGL

**Suite:** AOS 0.2.0 DEV1 ENV-02  
**Base cientifica:** SENS-GLJGL-02  
**Estado:** candidato a validacion dinamica  
**Motor objetivo:** GNU Octave

## Problema corregido

La sensibilidad JGL devolvia `NaN` para todos los puntos cuando el caso contenia `P_iny_sup = 0`, aun cuando el usuario forzaba `Qiny`. El retorno `SIN_PRESION_MOTRIZ` se ejecutaba antes de que la formulacion historica pudiera derivar el diferencial cinetico minimo asociado al caudal y a la tobera.

## Cambios

- Se incorpora un menu visible de condicion motriz JGL.
- La simulacion puntual JGL con `Qiny` fijo utiliza el mismo menu explicito; el contrato no queda limitado al barrido.
- `P_iny_sup = 0` no se reemplaza silenciosamente.
- Se preservan por separado la presion importada, la configurada, la disponible, la requerida y la efectiva.
- Se agregan tres modos: `DERIVADA_DESDE_QINY`, `PRESION_DISPONIBLE` y `SIN_PRESION_MOTRIZ`.
- La ruta derivada calcula, para cada punto:
  - presion de succion del eductor;
  - diferencial motriz minimo por Qiny/tobera;
  - presion motriz requerida en fondo;
  - contribucion de la columna de gas;
  - perdida del conducto de inyeccion;
  - presion superficial minima requerida.
- La ruta con presion disponible verifica la factibilidad de cada `Qiny`.
- Se calcula el margen de presion y el limite interpolado `Qiny_max_por_presion` sin extrapolacion.
- Se agrega una grafica con presiones absolutas y componentes de la presion requerida.
- La grafica absoluta incorpora tambien la presion motriz disponible en fondo cuando puede calcularse.
- Las sensibilidades JGL y comparativa JGL/GL publican las nuevas columnas en tabla, CSV y `.aosrpt`.
- Se agrega una regresion profunda de barrido JGL derivado con dos puntos para comprobar que `P_iny_sup = 0` ya no provoca `SIN_PRESION_MOTRIZ`.
- El modo derivado puede mostrar una curva de diseno sin presion disponible; si una presion disponible conocida resulta insuficiente, el punto no se habilita para el optimo.

## Ecuaciones de contrato

```text
Pm_req = Ps + DeltaP_motriz_req
P_sup_req = (Pm_req + DeltaP_friccion) / factor_columna
```

La segunda ecuacion invierte exactamente el mismo modelo utilizado por `jgl_presion_motriz_fondo`.

## Compatibilidad

SENS03 incluye las correcciones de SENS01 y el tratamiento polinomico explicito de SENS02. La distribucion completa no requiere instalar versiones intermedias.

## Nucleos preservados

No se modifican `GL_sim`, `aos_nodal_balance_gl`, `aos_buscar_cruce_nodal`, `jgl_solver_directo` ni `jgl_solver_iterativo`. Se actualiza el contrato comun del eductor JGL y la orquestacion de sensibilidades.
