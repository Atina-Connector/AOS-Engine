# AOS Suite 0.2.0 DEV1

## Primera baseline de desarrollo distribuido

AOS 0.2.0 DEV1 se construye sobre la copia real auditada:

- AOS 0.1.9 R2 HF3.4-CAD-R16;
- AOSCAD 0.0.1 DEV1 R16, candidato a revision del jefe;
- AOSBCK R1;
- GF3 con signo de tuberia libre corregido;
- geologia idempotente;
- gestor transaccional de punzados;
- gestion universal y contextual de casos;
- catalogos y galerias por `.aosdat`.

Se integra ademas el hotfix HF3.5 que no pudo instalarse sobre la rama CAD-R16:

- inventario transversal de tablas;
- perfiles Ejecutivo, Tecnico, Auditoria y Personalizado;
- modos FULL_BODY, SUMMARY, SAMPLED, FULL_APPENDIX, VIEWER_ONLY y EXCLUDED_EXPORT;
- preservacion obligatoria de datos completos;
- tablas de sensibilidad completas por defecto;
- contrato de composicion en `.aosrpt` y `.aoscad`;
- compatibilidad con recursos visuales AOSCAD R16.

## Cambios de version

- Suite: `0.2.0-DEV1`.
- Los bancos mantienen versionado independiente.
- AOSCAD permanece `0.0.1-DEV1-R16` y no se promociona a BETA.
- BES3 permanece `DESARROLLO_NO_VALIDADO`.
- Viewer permanece Alpha36 y requiere incorporar lectura completa del contrato HF3.5.

## Regla de desarrollo

Los bancos pueden evolucionar como programas independientes. Los servicios, contratos y solvers comunes se consumen mediante interfaces publicas y no deben modificarse desde un banco sin RFC, benchmark y regresion.

## Enmienda de arquitectura ENV-01 — AOS Environmental

Se aprueba `ADR-AOS-2026-001` y se corrige la clasificación de Gestión Ambiental:

- AOS Environmental pasa a ser banco de trabajo independiente y transversal.
- El orden objetivo de cinta es SCADA, Environmental, Maintenance.
- AOSCAD, AOSBCK y AOS 3D Core quedan definidos como autoridad de identidad, ubicación y topología física.
- AOS Environmental es propietario de fuentes, eventos, mediciones, inventarios, emisiones, derrames, riesgo y cierre ambiental.
- Maintenance conserva integridad, confiabilidad, pulling y ejecución de acciones correctivas; no mantiene un modelo ambiental paralelo.
- Los bancos consumidores publicarán actividad energética y AOS Environmental centralizará factores y emisiones indirectas.
- Se preservan `AMBIENTAL` y `AOS_menu_gestion_ambiental` como alias heredados.
- No se modifican solvers, menús ejecutables ni física en ENV-01.
- El diseño de contratos y el scaffold runtime quedan como siguiente etapa obligatoria.


## Enmienda runtime ENV-02 — AOS Environmental

- AOS Environmental se incorpora al menú principal entre SCADA y Maintenance.
- Se crea `AOS_menu_environmental` como entrypoint independiente.
- El registro runtime pasa de 14 a 15 workbenches.
- Maintenance conserva solamente un acceso cruzado al banco independiente.
- `AOS_menu_gestion_ambiental` continúa como alias histórico.
- Se agrega `test_aos_environmental_runtime_shell_env02`.
- No se implementan todavía ecuaciones, factores, schemas detallados ni reportes ambientales especializados.

## Hotfix cientifico SENS-GLJGL-01 - Sensibilidades GL/JGL

Se corrige una regresion de la capa de sensibilidades sin reescribir las ecuaciones del solver puntual GL:

- la ultima simulacion compatible GL o JGL pasa a ser la fuente recomendada del barrido;
- una simulacion de otro sistema nunca queda como opcion por defecto;
- el IPR faltante vuelve a `linear`, igual que el solver GL puntual;
- la configuracion fisica se congela y firma antes del barrido;
- GL usa un evaluador canonico que llama a `GL_sim` con la misma configuracion efectiva;
- JGL usa un unico metodo y una unica resolucion en toda la curva;
- el modo automatico/hibrido JGL deja de mezclar puntos directos e iterativos;
- se propagan los estados reales, residuos, convergencia y motivos de rechazo;
- `NO_CONVERGE`, `SIN_CRUCE`, `SIN_CAMBIO_SIGNO` y estados no fisicos conservan el valor raw, pero publican `NaN`;
- `WC` fuera de `[0,1]`, caudales negativos, `Qo > Ql` y `Qiny` no propagado bloquean el punto;
- los modos reducidos se identifican como preliminares y no habilitan optimo;
- reportes y CSV conservan valores raw, valores publicados, mascaras de validez y firmas de configuracion;
- se agregan verificadores de contrato, rechazo de estados, paridad GL y metodo uniforme JGL.

Identificador del hotfix: `SENS-GLJGL-01`.


## Hotfix cientifico SENS-GLJGL-02 - Polinomio explicito

- restaura el polinomio de grado 5 historico como opcion visible;
- incorpora modos discreto, polinomico informativo y polinomico verificado;
- el modo discreto no ejecuta `polyfit`;
- el modo verificado recalcula el maximo de derivada cero con el solver fisico;
- conserva puntos del solver y curva derivada en series diferentes;
- bloquea extrapolacion, discontinuidades, limites fisicos y sobreoscilacion;
- agrega contratos y secciones `.aosrpt` para grado, R2, RMSE, dominio y
  verificacion;
- no modifica los nucleos GL/JGL protegidos.

Identificador del hotfix: `SENS-GLJGL-02`.

## Hotfix cientifico SENS-GLJGL-03 - Condicion motriz y curva de presiones JGL

- agrega una seleccion visible de condicion motriz JGL;
- aplica la misma seleccion a la simulacion puntual JGL con `Qiny` fijo;
- conserva `P_iny_sup = 0` como dato importado y evita reemplazos ocultos;
- conserva por separado la presion importada, configurada, disponible, requerida y efectiva;
- permite derivar la presion minima requerida cuando `Qiny` se fuerza;
- permite ingresar o utilizar una presion disponible y verificar la factibilidad;
- distingue presion de succion, diferencial motriz, presion de fondo requerida,
  aporte de la columna de gas, perdida por friccion y presion superficial requerida;
- calcula margen de presion y `Qiny_max_por_presion` dentro del barrido, sin extrapolar;
- agrega tabla, grafica y seccion `.aosrpt` `JGL_MOTIVE_PRESSURE`;
- mantiene SENS02 completo, incluido el polinomio grado 5 explicito;
- no modifica `GL_sim`, el balance nodal ni los archivos de los solvers JGL
  directo e iterativo.

Identificador del hotfix: `SENS-GLJGL-03`.
