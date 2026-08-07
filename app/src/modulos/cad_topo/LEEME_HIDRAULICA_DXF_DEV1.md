# AOSCAD Hidráulica DXF 0.0.1 DEV1

## Estado

Primera versión funcional de desarrollo para GNU Octave.

- Motor: `AOSCAD-HIDRAULICA-0.0.1-DEV1`
- Estado: `DESARROLLO_NO_VALIDADO`
- Fuente geométrica: DXF
- Salida: `.aoscad` simple o enriquecido
- Fuente de verdad: tablas abiertas dentro del `.aoscad`

## Alcance de esta versión

Resuelve redes hidráulicas que cumplen simultáneamente:

1. un único nodo con presión conocida;
2. una o más demandas de caudal positivas;
3. red conectada;
4. topología de árbol, sin lazos;
5. flujo desde el nodo de presión hacia las demandas;
6. tuberías representadas por LINE, LWPOLYLINE o POLYLINE.

No resuelve todavía:

- lazos hidráulicos;
- múltiples fuentes de presión;
- flujo reverso o fuentes internas de caudal;
- bombas o compresores con curva activa;
- controles automáticos;
- mezcla de fluidos en nodos;
- redes transitorias.

Los equipos activos detectados se conservan en las tablas, pero en DEV1 no aportan
head. El resultado incluye la advertencia `EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1`.

## Modelos de tramo

### MONOFASICO_DARCY

Darcy-Weisbach, gravedad, accesorios y válvulas con Kv.

### MULTIFASICO_HB

Usa el motor común `aos_vlp_integrar(..., 'HB')` de AOS. No duplica ecuaciones.

### MULTIFASICO_DR

Usa el motor común `aos_vlp_integrar(..., 'DR')` de AOS.

### MULTIFASICO_SIMPLIFICADO

Usa `vlp_simplified_corregida` como fallback.

### AUTOMATICO

- sin gas: `MONOFASICO_DARCY`;
- con gas: modelo configurado en `modelo_multifasico`, inicialmente HB.

## Convenciones de condiciones de borde

- `P`: presión en Pa;
- `Q`: demanda de líquido en m³/s;
- `Q > 0`: consumo o salida de la red;
- `Q < 0`: no soportado en DEV1;
- `QG`: caudal de gas estándar en Sm³/s, cuando se declare explícitamente;
- si no existe `QG` y `GLR > 0`, se usa `QG = QL × GLR`.

## Metadatos DXF admitidos

Ejemplo monofásico:

```text
AOS D=0.1016 EPS=4.5e-5 MAT=ACERO MODELO=MONOFASICO_DARCY
AOS P=2000000
AOS Q=0.001
AOS TIPO=FLUIDO RHO_O=850 RHO_W=1000 WC=0.5 MU=0.001
```

Ejemplo multifásico:

```text
AOS D=0.062 EPS=1.5e-5 MODELO=MULTIFASICO_HB
AOS TIPO=FLUIDO API=35 WC=0.45 GLR=117 GAMMA_G=0.70
AOS P=5000000
AOS Q=0.0015
```

Claves hidráulicas adicionales:

- `MODELO`, `MODEL` o `VLP`;
- `MODELO_MULTIFASICO`;
- `API`;
- `WC` o `WATER_CUT`;
- `GLR` o `GOR`;
- `GAMMA_G` o `SG_GAS`;
- `RHO_O`, `RHO_W`, `RHO_G_STD`;
- `MU`, `MU_L`, `MU_G`;
- `T_K`, `TEMP_K`, `T_SUP_K`, `T_FONDO_K`.

## Tablas de salida

### `tablas_resultados.nodos`

- ID;
- coordenadas X, Y, Z;
- presión en Pa y bar;
- demanda de líquido;
- demanda de gas;
- identificación del nodo de referencia;
- estado.

### `tablas_resultados.tramos`

- ID del tramo;
- nodo de entrada y salida;
- sentido hidráulico;
- modelo utilizado;
- caudal líquido y gas;
- presión de entrada y salida;
- pérdida total;
- gravedad;
- fricción;
- pérdidas menores;
- velocidad;
- Reynolds;
- factor de fricción;
- holdup;
- régimen;
- convergencia y advertencias.

## Ejecución

Desde el menú AOSCAD:

```text
16 - Ejecutar hidráulica DXF DEV1 + guardar .aoscad
```

Desde la consola:

```octave
aos_cad_importar_dxf('datos/ejemplos/cad/demo_aos_hidraulica_dev1.dxf');
aos_cad_construir_topologia(0.05, false);
resultados = aos_cad_hidraulica_ejecutar(false);
aos_aoscad_escribir([], 'SIMPLE', false);
```

## Prueba

```octave
test_aos_cad_hidraulica_dxf
```

La prueba recorre DXF → tablas → topología → hidráulica → `.aoscad` → lectura.
