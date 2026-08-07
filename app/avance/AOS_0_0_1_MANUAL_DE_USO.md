# AOS 0.0.1 - Manual de uso de funcionalidades existentes

## 1. Como iniciar AOS

1. Abrir GNU Octave.
2. Ir a la carpeta raiz de AOS 0.0.1.
3. Ejecutar:

```octave
AOS
```

AOS abre el menu principal y configura automaticamente las rutas internas.

## 2. Menu principal

```text
1  - Simular Jet Gas Lift
2  - Simular Gas Lift convencional
3  - Simular BES
4  - Simular Bombeo Mecanico
5  - Analisis de sensibilidad JGL/GL
6  - Analisis de sensibilidad BES
7  - Diseno de mandriles
8  - Calibracion
9  - Visualizar survey
10 - Cargar geologia
11 - Importar pozos CSV
12 - Exportar / Importar .aosdat / .aosrpt
13 - Usar configuracion por defecto
14 - Visualizar reporte .aosrpt
0  - Salir
```

## 3. Importar un pozo .aosdat

Desde el menu principal seleccionar:

```text
12 - Exportar / Importar .aosdat / .aosrpt
1  - Importar configuracion desde .aosdat
```

Luego elegir:

- busqueda en carpetas estandar; o
- navegacion manual.

Una vez importado, AOS muestra la configuracion activa al inicio del menu principal. Si el archivo contiene survey, queda disponible para los modulos y para visualizacion.

## 4. Volver a configuracion por defecto

Seleccionar:

```text
13 - Usar configuracion por defecto
```

Esto descarta la configuracion importada activa y vuelve a los valores base de AOS.

## 5. Jet Gas Lift

Seleccionar:

```text
1 - Simular Jet Gas Lift
```

Uso tipico:

1. Importar `.aosdat` o usar defaults.
2. Revisar parametros actuales.
3. Modificar parametros si corresponde.
4. Ejecutar simulacion.
5. Revisar caudal, presiones y diagnosticos.
6. Exportar reporte si se desea.

Parametros de interes:

- IP
- WC
- GLR
- P_wh
- P_iny_sup
- profundidad de bomba / punto de evaluacion
- parametros de eductor

## 6. Gas Lift convencional

Seleccionar:

```text
2 - Simular Gas Lift convencional
```

Uso tipico:

1. Cargar configuracion del pozo.
2. Revisar parametros actuales.
3. Conservar o editar parametros.
4. Ejecutar simulacion.
5. Comparar resultado con Prosper cuando se este validando.

Nota de version 0.0.1:

El modulo queda protegido por Config Guard para reducir errores por `.aosdat` importados. Si una configuracion es insuficiente, AOS debe advertirlo en lugar de romper la sesion de Octave.

## 7. BES

Seleccionar:

```text
3 - Simular BES
```

Uso tipico:

1. Revisar o cargar configuracion.
2. Definir profundidad, presiones y parametros de bomba.
3. Ejecutar simulacion.
4. Revisar caudal, potencia, sumergencia y diagnosticos.

Tambien existe sensibilidad BES desde el menu principal:

```text
6 - Analisis de sensibilidad BES
```

Sensibilidades disponibles segun codigo actual:

- diametro de bomba;
- etapas;
- sumergencia.

## 8. Bombeo Mecanico

Seleccionar:

```text
4 - Simular Bombeo Mecanico
```

AOS abre el submenu:

```text
1 - Simular Bombeo Mecanico operativo
2 - Laboratorio Gibbs experimental
3 - BM Gibbs Solver Foundation v18 (Octave)
0 - Volver
```

### 8.1 BM operativo

Camino historico operativo del modulo BM.

Permite:

- seleccionar material de varillas;
- seleccionar unidad de bombeo si hay catalogo disponible;
- definir tuberia anclada/libre;
- revisar y editar parametros BM;
- elegir modelo IPR;
- ejecutar BM_core;
- imprimir resultados y varillas;
- ajustar golpes por minuto;
- exportar reporte.

Parametros principales:

- IP
- WC
- P_wh
- D_bomba
- GLR
- diametro de bomba
- carrera
- golpes/min
- eficiencia volumetrica
- eficiencia mecanica
- presion intake minima
- tipo de unidad
- material de varillas

### 8.2 Laboratorio Gibbs experimental

Camino de laboratorio para estudiar comportamiento de Gibbs sin comprometer el BM operativo.

Usar para:

- pruebas fisicas;
- analisis de cartas;
- comparar evolucion entre parches;
- revisar diagnosticos del solver.

### 8.3 BM Gibbs Solver Foundation v18

Camino nuevo y prioritario de desarrollo.

Uso recomendado para pruebas:

1. Entrar a BM.
2. Elegir opcion 3.
3. Definir carrera polished rod.
4. Definir velocidad en golpes/min.
5. Definir profundidad de bomba.
6. Definir diametro de bomba.
7. Definir nodos de sarta.
8. Definir ciclos de simulacion.
9. Definir ciclos iniciales a descartar.
10. Definir amortiguamiento.
11. Definir llenado de bomba.
12. Revisar cargas y cartas.

Criterio de ciclos:

- default historico: 5 ciclos;
- si hay 2 o mas ciclos, normalmente se descarta el primero;
- las cartas operativas se promedian punto a punto con fase de ciclo normalizada;
- el resultado esperado es una sola carta promedio cerrada, no cuatro ciclos dibujados por separado.

Variables importantes:

- carrera de superficie;
- carrera de fondo;
- carga superficie maxima/minima;
- carga dinamica relativa;
- offset estatico estimado;
- carga de bomba;
- caudal teorico de fondo.

Advertencia:

BM Gibbs Foundation es preliminar. Para cliente, usarlo como comparacion tecnica controlada y no como resultado comercial cerrado hasta validar contra Prosper/SROD/QROD o datos reales.

## 9. Analisis de sensibilidad JGL/GL

Seleccionar:

```text
5 - Analisis de sensibilidad JGL/GL
```

Funciones disponibles segun codigo actual:

- sensibilidad a P_iny;
- sensibilidad a P_wh;
- sensibilidad a Qiny;
- sensibilidad a Qiny para GL;
- sensibilidad a Qiny para JGL;
- sensibilidad por parametros de eductor;
- busqueda de optimo;
- balance energetico;
- preparacion/carga de base de sensibilidad.

Uso recomendado:

1. Correr caso base.
2. Ejecutar sensibilidad de un parametro por vez.
3. Exportar o guardar resultados relevantes.
4. Comparar tendencias con Prosper.

## 10. Diseno de mandriles

Seleccionar:

```text
7 - Diseno de mandriles
```

Uso:

- estimar ubicaciones o condiciones de mandriles de Gas Lift;
- revisar graficos asociados si estan disponibles;
- usar como herramienta de diseno preliminar.

## 11. Calibracion

Seleccionar:

```text
8 - Calibracion
```

Uso:

- ajustar parametros de modelo contra un caso conocido;
- revisar diferencias entre resultado AOS y dato de referencia;
- documentar cualquier ajuste que luego se quiera transformar en cambio permanente.

## 12. Visualizar survey

Seleccionar:

```text
9 - Visualizar survey
```

Si hay `.aosdat` importado con survey, AOS usa ese survey. Si no, intenta cargar el survey por defecto.

Uso recomendado:

- verificar que la trayectoria cargada sea razonable;
- confirmar profundidad medida y vertical;
- revisar antes de simular pozos desviados.

## 13. Cargar geologia y punzados

Seleccionar:

```text
10 - Cargar geologia
```

Funciones relacionadas:

- carga de geologia;
- carga de intervalos punzados;
- calculo de caudales criticos;
- erosion de punzados;
- reporte de alerta.

En AOS 0.0.1 se considera funcionalidad de apoyo. No reemplaza aun un modelo geologico completo.

## 14. Importar pozos CSV

Seleccionar:

```text
11 - Importar pozos CSV
```

Uso:

- cargar datos tabulares de pozos;
- preparar configuraciones o catalogos;
- revisar que columnas y unidades sean consistentes antes de simular.

## 15. Exportar reporte .aosrpt

Desde el menu principal:

```text
12 - Exportar / Importar .aosdat / .aosrpt
2  - Exportar ultimo resultado como .aosrpt
```

Requisito:

- haber ejecutado una simulacion antes.

Si no hay resultado reciente, AOS informa que no hay datos para exportar.

## 16. Visualizar reporte .aosrpt

Seleccionar:

```text
14 - Visualizar reporte .aosrpt
```

Uso:

- abrir resultados guardados;
- revisar una corrida anterior;
- compartir resultados reproducibles.

## 17. Recomendacion para corrida con cliente

Flujo sugerido:

1. Importar `.aosdat` del pozo.
2. Visualizar survey.
3. Correr el modulo correspondiente en AOS.
4. Correr el mismo caso en Prosper.
5. Comparar: caudal, presiones, profundidades, cargas y diagnosticos.
6. Registrar diferencias y no modificar codigo durante la reunion salvo que sea necesario.
7. Si aparece un error, guardar:
   - archivo `.aosdat` usado;
   - opcion de menu elegida;
   - parametros modificados;
   - mensaje completo de Octave;
   - captura del grafico.

## 18. Reglas practicas de version 0.0.1

- No instalar parches durante una corrida con cliente salvo que se haya probado antes.
- No cambiar varias variables al mismo tiempo durante validacion.
- Para BM/Gibbs, empezar con casos simples y luego agregar complejidad.
- Tomar Prosper como referencia comparativa, no como verdad absoluta sin revisar supuestos.
- Documentar cada caso validado.
