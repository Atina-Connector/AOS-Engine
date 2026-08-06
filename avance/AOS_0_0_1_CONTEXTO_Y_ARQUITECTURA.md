# AOS 0.0.1 - Contexto y arquitectura

## Estado de la version

AOS 0.0.1 es una version de trabajo orientada a uso tecnico controlado con cliente. El objetivo de esta version no es declarar el software como producto terminado, sino congelar un punto de avance estable para correr casos reales junto con Prosper y comparar resultados.

La plataforma objetivo es GNU Octave. MATLAB puede servir como referencia de compatibilidad parcial, pero no es la plataforma principal. Todo desarrollo nuevo debe ser Octave-first y evitar dependencias de toolboxes propietarios.

## Principio rector

AOS se desarrolla bajo la secuencia:

Fisica -> Matematica -> Documento -> Codigo -> Validacion

Una decision fisica relevante debe estar justificada en la documentacion antes de consolidarse como codigo operativo.

## Vision funcional

AOS es una herramienta offline, modular y portable para simulacion de produccion de pozos. La filosofia de la version 0.0.1 es permitir que el ingeniero cargue o edite una configuracion de pozo, ejecute distintos metodos de levantamiento artificial y exporte o compare resultados.

Componentes principales:

- AOS: aplicacion principal en GNU Octave.
- .aosdat: archivo portable de configuracion del pozo.
- .aosrpt: archivo portable de reporte de resultados.
- Modulos fisicos: JGL, Gas Lift, BES, Bombeo Mecanico.
- Utilidades comunes: survey, geologia, punzados, diagnosticos, semaforos, reportes, sensibilidad.

## Arquitectura de carpetas

```text
AOS/
  AOS.m                         Lanzador principal
  README.md                     Nota general del proyecto
  config/                       Configuraciones base y catalogos
  datos/                        Datos de ejemplo y entradas
  intercambio/                  Archivos .aosdat/.aosrpt
  avance/                       Documentacion activa de version
  src/
    menu/                       Menus principales por modulo
    core/                       Nucleos de calculo por sistema
      GL/                       Jet Gas Lift y Gas Lift convencional
      BES/                      Bombeo electrosumergible
      BM/                       Bombeo Mecanico
        gibbs_foundation/       Gibbs Solver Foundation v18.x
    lab/gibbs/                  Laboratorio Gibbs experimental
    sensibilidad/               Analisis de sensibilidad
    geologia/                   Geologia, punzados y reportes asociados
    utilidades/                 Funciones transversales
      config/                   Configuracion, normalizacion y validacion
      intercambio/              Importacion/exportacion .aosdat/.aosrpt
      nodal/                    Nodal, VLP, eductor, presiones
      graficos/                 Visualizacion tecnica
      diagnostico/              Diagnosticos de tuberia/flujo
      semaforos/                Indicadores operativos
      bombeo_mecanico/          Utilidades BM clasicas
```

## Flujo de ejecucion

1. El usuario ejecuta `AOS.m` desde Octave.
2. `AOS.m` agrega `src/` y `src/menu/` al path.
3. `AOS_app.m` carga el entorno mediante `iniciar_aos.m`.
4. El menu principal permite importar `.aosdat`, simular modulos o trabajar con configuracion por defecto.
5. Antes de entrar a modulos principales, AOS 0.0.1 llama al guard de configuracion para normalizar y validar la configuracion activa.

## Config Guard v18.3B

La version 0.0.1 incorpora un guard transversal de configuracion. Su objetivo es evitar errores de Octave cuando un modulo espera una estructura y recibe un texto, por ejemplo:

```text
sq_string cannot be indexed with .
```

Funciones principales:

- `aos_normalizar_config.m`
- `aos_validar_config_modulo.m`
- `aos_preparar_config_activa.m`
- `aos_config_base.m` actualizado
- `importar_aosdat.m` actualizado
- `AOS_app.m` actualizado para preparar la configuracion antes de JGL, GL, BES, BM y sensibilidad.

Este guard no cambia la fisica de los modelos. Solo hace mas robusto el consumo de configuraciones importadas.

## Modulos incluidos

### Jet Gas Lift

Modulo operativo para simulacion de Jet Gas Lift, con calculo nodal, eductor, sensibilidad y exportacion de resultados.

### Gas Lift convencional

Modulo operativo para simulacion de Gas Lift convencional. En 0.0.1 queda protegido por Config Guard para reducir fallas por configuraciones importadas parcialmente incompatibles.

### BES

Modulo de bombeo electrosumergible con simulacion base, sensibilidad por diametro/etapas/sumergencia y reportes.

### Bombeo Mecanico

Incluye tres caminos:

1. Bombeo Mecanico operativo clasico.
2. Laboratorio Gibbs experimental.
3. BM Gibbs Solver Foundation v18.x.

El foco de desarrollo inmediato es BM/Gibbs. La Foundation v18.x es un solver en construccion, no validado aun contra SROD/QROD/Prosper.

## Gibbs Solver Foundation v18.x

Objetivo de ingenieria:

- polished rod como movimiento impuesto;
- sarta como medio elastico distribuido;
- bomba como condicion de borde inferior;
- simulacion de multiples ciclos;
- descarte del primer ciclo;
- promedio punto a punto de cartas de superficie y fondo;
- opcion de ciclos configurables;
- diametro de bomba editable;
- modo cuasiestatico automatico para casos lentos donde debe aparecer una carta tipo paralelogramo.

Estado actual:

- util para pruebas de arquitectura y exploracion;
- no debe considerarse calibrado aun;
- las cargas y carrera de fondo deben compararse contra software comercial y casos reales;
- la forma de carta cerrada carga-posicion es intencional.

## Formatos portables

### .aosdat

Archivo de configuracion de pozo. Puede incluir parametros de pozo, survey y datos auxiliares. En 0.0.1, al importarse, se normaliza para que los modulos puedan consumirlo con menor riesgo de error.

### .aosrpt

Archivo de reporte de resultados. Puede usarse para conservar resultados reproducibles y revisar una corrida posterior.

## Criterio de uso con cliente

AOS 0.0.1 debe presentarse como version de desarrollo controlada:

- correr casos reales junto con Prosper;
- registrar diferencias;
- no ocultar limitaciones;
- usar Prosper/SROD/QROD como referencia externa cuando aplique;
- documentar cada ajuste antes de convertirlo en cambio permanente.

## Limitaciones conocidas

- BM Gibbs Foundation no esta validado comercialmente.
- Algunas correlaciones pueden requerir calibracion por cuenca/campo.
- La robustez de `.aosdat` mejoro, pero configuraciones antiguas pueden requerir normalizacion adicional.
- La geologia y punzados estan disponibles como apoyo, no como modelo geologico completo.
- La version 0.0.1 no implementa aun API externa ni Viewer independiente.

## Proximos pasos sugeridos

1. Congelar AOS 0.0.1 como baseline.
2. Correr pozo cliente junto con Prosper.
3. Comparar JGL/GL/BES/BM segun corresponda.
4. Para BM/Gibbs, validar primero casos simples: baja velocidad, bomba llena, pozo vertical o survey suave.
5. Ajustar cargas absolutas, signos y offset estatico con trazabilidad.
6. Documentar resultados en una hoja de validacion por caso.
