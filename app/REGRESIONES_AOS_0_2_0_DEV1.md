# Regresiones obligatorias AOS 0.2.0 DEV1

1. Gestión universal y contextual del caso.
2. Prioridad del `.aosdat` sobre defaults.
3. Catálogos y galerías.
4. CRUD y round-trip de punzados.
5. Geología idempotente con NaN.
6. Tubing libre GF3 con rigidez positiva.
7. Contrato de espaciamiento GF3.
8. BES3 y comparación V1/V2/V3.
9. AOSCAD R16: DXF, STEP, topología, hidráulica, lazos, 3D y recursos visuales.
10. Composición de tablas HF3.5 en `.aosrpt` y `.aoscad`.
11. Sensibilidades con tabla completa por defecto.
12. Viewer como último banco.
13. Ausencia de `.mat` y de nombres `.m` duplicados.

Comando oficial:

```octave
VERIFICAR_AOS_0_2_0_DEV1(true)
```

## Controles manuales de arquitectura ENV-01

14. `aos_workbenches_0_2_0_dev1.json` enumera 15 bancos objetivo.
15. `ENVIRONMENTAL` aparece después de `SCADA` y antes de `MAINTENANCE`.
16. AOS Environmental declara `runtime_available=false` en ENV-01.
17. Viewer continúa último.
18. AOSCAD / AOS 3D Core figuran como autoridad espacial de eventos ambientales.
19. Maintenance no figura como propietario del modelo ambiental.
20. Se preservan los alias `AMBIENTAL` y `AOS_menu_gestion_ambiental`.
21. La actividad energética se separa del cálculo de emisiones indirectas.
22. No se incorporaron cambios de física ni nuevos archivos `.m` en ENV-01.


## Controles runtime ENV-02

23. El registro runtime contiene 15 workbenches.
24. `ENVIRONMENTAL` aparece despues de `SCADA` y antes de `MAINTENANCE`.
25. `AOS_menu_environmental` existe, esta visible y es despachado por `AOS_app`.
26. AOS Viewer permanece como ultimo workbench.
27. Maintenance contiene un enlace al banco independiente y no lo declara como modelo interno.
28. `AOS_menu_gestion_ambiental` redirige al entrypoint nuevo.
29. `test_aos_environmental_runtime_shell_env02` aprueba.

## Controles cientificos SENS-GLJGL-01

30. La sensibilidad GL utiliza la ultima simulacion GL compatible como fuente recomendada.
31. Una ultima simulacion JGL no queda por defecto en una sensibilidad GL, ni viceversa.
32. El fallback de `modelo_IPR` es `linear`, consistente con GL puntual.
33. Cada punto GL del barrido se evalua mediante `sens_gl_evaluar_punto` y reproduce `GL_sim` para el mismo Qiny.
34. Una curva JGL usa un unico metodo y una unica resolucion.
35. El modo automatico/hibrido JGL no mezcla resultados directos e iterativos.
36. El estado GL no se etiqueta `OK` de forma fija; se propaga el estado real del solver.
37. `NO_CONVERGE`, `SIN_CRUCE`, `SIN_CAMBIO_SIGNO`, valores negativos y WC fuera de dominio no se publican.
38. Los valores rechazados se conservan en campos `raw`, mientras el valor publicable es `NaN`.
39. El optimizador utiliza exclusivamente `valido_para_optimo=true`.
40. La firma fisica permanece constante cuando solo cambian Qiny o la resolucion de malla.
41. El reporte conserva estados, residuos, motivos, mascaras de validez y firma por punto.
42. `VERIFICAR_SENS_GLJGL_01(false)` aprueba antes de utilizar las sensibilidades.


## Controles cientificos SENS-GLJGL-02

43. El menu ofrece DISCRETO, POLINOMICO_INFORMATIVO y POLINOMICO_VERIFICADO.
44. El modo DISCRETO no ejecuta una llamada a `polyfit`.
45. El grado 5 historico es seleccionable de forma explicita.
46. El modo informativo no cambia la recomendacion discreta.
47. El modo verificado recalcula el candidato mediante el evaluador canonico.
48. Un candidato no convergido o fuera de tolerancia restaura el optimo discreto.
49. Los puntos fisicos no son reemplazados por la curva polinomica.
50. No existe extrapolacion fuera del rango validado.
51. Las discontinuidades bloquean el optimo polinomico global.
52. El `.aosrpt` conserva tratamiento, ajuste, curva y verificacion en secciones separadas.
53. `VERIFICAR_SENS_GLJGL_02(false)` aprueba antes de utilizar la opcion.

## Controles cientificos SENS-GLJGL-03

54. La condicion motriz JGL se selecciona mediante un menu visible antes de congelar el snapshot.
55. `P_iny_sup = 0` no se reemplaza silenciosamente por una presion arbitraria.
56. En modo `DERIVADA_DESDE_QINY`, un Qiny positivo calcula la presion motriz minima requerida y no se bloquea por el cero importado.
57. Se cumple `Pm_req = Ps + DeltaP_motriz_req` para cada punto.
58. La presion superficial requerida invierte el mismo modelo de columna y perdidas utilizado por `jgl_presion_motriz_fondo`.
59. En modo `PRESION_DISPONIBLE`, un punto insuficiente no se publica como factible ni entra al optimo.
60. La tabla y la grafica conservan Ps, diferencial motriz, Pm de fondo, columna de gas, friccion, P superficial requerida, disponible y margen.
61. El limite `Qiny_max_por_presion` se interpola dentro del barrido y no extrapola.
62. El reporte conserva el valor importado, el modo seleccionado, las presiones requeridas y `sobrescritura_oculta=NO`.
63. `VERIFICAR_SENS_GLJGL_03(false)` aprueba antes de utilizar la nueva ruta.
64. La simulacion puntual JGL con `Qiny` fijo presenta la misma seleccion motriz explicita.
65. El gate profundo ejecuta `test_sens_gljgl03_barrido_derivado_jgl`.
