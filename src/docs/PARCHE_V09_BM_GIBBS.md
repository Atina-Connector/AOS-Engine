# AOS parche v09 - Revisión preliminar BM / Gibbs

Fecha: 2026-07-08  
Alcance: revisión estática del módulo de Bombeo Mecánico (BM) y del bloque Gibbs/cartas dinamométricas.

## Objetivo

Dejar el módulo BM en una condición más ordenada para trabajar mañana sobre la física y la calibración, corrigiendo errores evidentes de ejecución, rutas, consistencia interna y generación de cartas.

## Cambios principales

### 1. `BM_menu.m`

Se reordenó el flujo interactivo de Bombeo Mecánico:

- Se eliminó una función local dentro del script, porque en Octave puede causar problemas de ejecución según la versión.
- Se aclaró que la velocidad `N_velocidad` representa **golpes por minuto**, no galones por minuto.
- Se agregó manejo explícito de:
  - eficiencia mecánica `eta_mec_bm`;
  - presión mínima de succión `P_succion_min`;
  - tubería anclada/libre;
  - fuente de configuración según `aos_config_base('BM')`.
- Se integró la generación de cartas BM/Gibbs mediante una función común: `diagnostico_cartas_bm.m`.
- Se conserva el diagnóstico común de tubería para BM.

### 2. `BM_core.m`

Se corrigió el motor básico de BM para que sea más robusto:

- Calcula el caudal por desplazamiento de bomba.
- Limita el caudal por IPR cuando la presión de succión cae por debajo de `P_succion_min`.
- Evita depender de `fzero` en rangos mal condicionados; usa una bisección interna simple y estable.
- Devuelve una estructura opcional `detalles` para diagnóstico y reporte.
- Distingue la limitante principal:
  - desplazamiento de bomba;
  - IPR / succión mínima;
  - no operación.

### 3. Gibbs / cartas dinamométricas

Se reemplazó la lógica de Gibbs por un modelo orientativo más estable:

- `ecuacion_onda_gibbs.m` ahora acepta 3 o 4 argumentos sin fallar.
- Se eliminó el salto artificial de cierre de ciclo que tenía la versión anterior.
- Se usa:
  - rigidez equivalente del tren de varillas;
  - velocidad de onda aproximada;
  - carga de fluido durante carrera ascendente;
  - retardo temporal por propagación de onda;
  - inercia y amortiguamiento livianos;
  - filtrado de picos compatible con cartas cerradas.
- `generar_tabla_cartas.m` queda como envoltorio del mismo modelo, para evitar dos criterios distintos.
- `diagnostico_gibbs.m` y `diagnostico_gibbs_v2.m` ahora usan la configuración AOS activa y no vuelven a cargar `config/GL/config_jgl.txt`.

> Nota: este Gibbs sigue siendo orientativo. No debe presentarse como solver completo API/QRod. Sirve para diagnóstico inicial, visualización y estructura modular.

### 4. Diseño de varillas

Se revisó `diseno_varillas.m`:

- Se conserva un tren preliminar de 1", 7/8" y 3/4".
- Se calcula peso flotado, carga de fluido y carga dinámica.
- La tensión mínima ahora puede detectar compresión potencial. La versión previa casi nunca disparaba barras de peso porque usaba siempre `0.9 * peso_flotado`.
- Se mantiene Goodman simplificado para factor de seguridad a fatiga.

### 5. Catálogos y rutas

Se corrigieron los cargadores:

- `cargar_materiales_varillas.m`
- `cargar_catalogo_bm.m`

Ahora resuelven `config/BM/...` desde cualquier carpeta de trabajo dentro de AOS, no solo si Octave está parado en la raíz.

### 6. `.aosdat` y `.aosrpt`

Se agregó soporte de exportación `.aosdat` para parámetros BM adicionales:

- `eta_mec_bm`
- `P_succion_min`
- `bm_puntos_carta`

También se permite importar `P_succion_min_bar` y convertirlo automáticamente a Pa.

En `.aosrpt` liviano se agregan secciones BM cuando corresponde:

- `[BOMBEO_MECANICO]`
- `[GIBBS]`
- `[CARTA_SUPERFICIE]`
- `[CARTA_FONDO]`

En `.aosrpt` enriquecido, si el sistema es BM y existen cartas, el gráfico embebido principal pasa a ser `bm_cartas` en lugar de un nodal genérico.

## Archivos modificados/agregados

```text
src/menu/BM_menu.m
src/core/BM/BM_core.m
src/utilidades/bombeo_mecanico/cargar_catalogo_bm.m
src/utilidades/bombeo_mecanico/cargar_materiales_varillas.m
src/utilidades/bombeo_mecanico/cinematica_superficie.m
src/utilidades/bombeo_mecanico/diagnostico_cartas_bm.m
src/utilidades/bombeo_mecanico/diseno_varillas.m
src/utilidades/bombeo_mecanico/ecuacion_onda_gibbs.m
src/utilidades/bombeo_mecanico/filtrar_picos_carta.m
src/utilidades/bombeo_mecanico/generar_tabla_cartas.m
src/diagnosticos/diagnostico_gibbs.m
src/diagnosticos/diagnostico_gibbs_v2.m
src/utilidades/config/aos_config_base.m
src/utilidades/intercambio/exportar_aosdat.m
src/utilidades/intercambio/importar_aosdat.m
src/utilidades/intercambio/exportar_aosrpt.m
src/utilidades/intercambio/exportar_aosrpt_enriquecido.m
src/utilidades/varios/ternario_txt.m
```

## Pendientes para revisar mañana

1. Validar numéricamente BM con un caso conocido.
2. Revisar si `D_bomba` debe interpretarse siempre como profundidad de bomba o si conviene separar:
   - `D_bomba` = profundidad;
   - `D_piston_mm` = diámetro del pistón.
3. Definir nomenclatura definitiva para velocidad:
   - `N_velocidad` queda como golpes/min;
   - evitar confusión con `gpm` de caudal.
4. Comparar carta Gibbs generada contra una carta esperada o medida.
5. Definir si el módulo LDL compartirá parte de la lógica BM:
   - tracción de sarta;
   - torque;
   - eficiencia de bomba;
   - diagnóstico mecánico de cabezal.

## Validación realizada

No se ejecutó GNU Octave en este entorno porque no está instalado. La validación fue estática:

- rutas;
- nombres de funciones;
- compatibilidad de llamadas;
- errores evidentes por número de argumentos;
- eliminación de dependencias frágiles como funciones locales dentro de scripts;
- revisión de flujo BM/Gibbs.
