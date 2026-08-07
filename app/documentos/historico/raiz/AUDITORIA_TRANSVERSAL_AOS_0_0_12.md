# Auditoria transversal AOS 0.0.12 — GNU Octave

**Fecha:** 13 de julio de 2026  
**Arbol revisado:** `AOS_0_0_12_ESTABILIZACION`  
**Alcance:** configuracion, GL, JGL, BES, BM, mandriles, calibracion, importacion/exportacion, reportes y todas las sensibilidades publicadas en los menus.  
**Inventario:** 256 archivos fuente `.m`; 0 nombres de funcion duplicados por archivo.

## Conclusion ejecutiva

El defecto observado no era unicamente de `Qiny`: la causa comun era la reaplicacion de aliases del `.aosdat` sobre valores canonicos modificados durante el runtime. Esa clase de fallo podia afectar IP, presiones, profundidad, geometria JGL, frecuencia/etapas BES y variables BM, y tambien podia hacer que solver, grafico, semaforo o reporte mostraran estados distintos.

La estabilizacion corrige la causa en un solo punto arquitectonico:

1. los aliases se interpretan al importar;
2. una configuracion ya activa captura sus campos canonicos;
3. toda normalizacion posterior restaura esos canonicos;
4. los aliases y estructuras anidadas se publican desde los canonicos, nunca al reves;
5. los solvers devuelven campos `audit` solicitados/efectivos;
6. los reportes serializan un snapshot inmutable de la corrida.

La igualdad o cercania de `Ql` entre dos valores de gas ya no se usa como prueba de que Qiny fue ignorado. Para distinguir un bug de propagacion de una insensibilidad fisica/numerica, GL ahora registra el Qiny que entra realmente en la VLP, el gas de formacion, el gas total, `Ps`, `P_req` y el residuo nodal.

## Resultados por area

### Configuracion transversal — corregida

- `aos_normalizar_config` preserva campos canonicos de una configuracion runtime.
- `aos_set_qiny` admite cualquier valor fijo mayor o igual a cero y un modo automatico separado.
- `D_iny` de GL/JGL no pisa `D_bomba` de BES/BM.
- Presiones, IP, Pb, GLR, WC, geometria JGL, frecuencia/etapas BES y variables BM se sincronizan canonico -> alias.
- Cada pozo importado por CSV parte de una estructura nueva; no hereda valores del pozo anterior.

### Gas Lift — corregido y trazable

- Qiny se pasa como argumento explicito hasta `aos_nodal_balance_gl`.
- El balance VLP guarda `Qg_inyectado_std`, `Qg_formacion_std` y `Qg_total_std`.
- La pantalla imprime `Qiny usado dentro VLP`.
- El `.aosrpt` incluye una seccion de auditoria GL con el valor realmente usado.
- El factor de declinacion se aplica a la IPR canonica, no solo a una estructura secundaria.
- Graficos y diagnosticos consumen el resultado canonico del solver.

### Jet Gas Lift — corregido en arquitectura; calibracion fisica pendiente

- Modos `iterativo`, `directo` y `automatico/hibrido` comparten la misma interfaz y se propagan de verdad.
- `Qiny=0` produce `DeltaP=0` y degenera a la base GL sin piso artificial.
- El modo hibrido ejecuta directo en toda la malla y confirma selectivamente extremos, optimos, baja confianza, estados anormales, saltos y curvatura.
- El CFD gas-gas fue eliminado del runtime y no condiciona calculo, convergencia ni confianza.
- `A_n` y `d_t` recalculan los coeficientes geometricos en cada punto cuando el modo es derivado.
- Reporte y grafico usan el mismo `DeltaP`, `Ps`, `Pd`, `Pm` y estado energetico.

La ecuacion continua del eductor sigue siendo una primera formulacion calibrable. Esto es una limitacion del modelo, no un fallo de propagacion de parametros.

### BES — corregido

- La corrida principal conserva IP, Pwh, profundidad de bomba, frecuencia y etapas efectivos.
- Estan presentes las cinco sensibilidades anunciadas: Pwh, frecuencia, sumergencia, run life/potencia y etapas.
- Cada sensibilidad registra valor solicitado y efectivo.
- `D_bomba` se usa de manera independiente de `D_iny`.

### Bombeo mecanico — corregido en la corrida principal

- Profundidad, diametro de bomba, carrera, SPM y eficiencias se conservan hasta `BM_core` y se devuelven en `detalle.audit`.
- El ajuste posterior de SPM vuelve a sincronizar antes de recalcular.
- No existe un menu de sensibilidades BM en esta rama; por lo tanto no se presenta como funcionalidad auditada ni disponible.

### Mandriles y calibracion — corregidos

- Se eliminaron caudales de gas hardcodeados en diseño de mandriles y evaluacion por profundidad.
- Calibracion GL/JGL usa una base comun, Qiny explicito y los solvers actuales.

### Reportes e intercambio — corregidos

- Reporte ligero y enriquecido se construyen desde el mismo snapshot efectivo.
- El nombre solicitado se conserva.
- `.aosdat` exporta `D_iny_m` y `D_bomba_m` por separado.
- Importar `.aosrpt` usa setters canonicos para Qiny y profundidad.
- El menu diferencia configuracion base importada de ultima corrida efectiva.

## Sensibilidades JGL auditadas

Todas las sensibilidades que involucran JGL muestran y propagan el menu:

```text
1 - Preciso iterativo en todos los puntos
2 - Simple/directo en todos los puntos
3 - Hibrido: directo + verificacion iterativa selectiva
```

Cobertura:

- Qiny JGL;
- Qiny JGL vs GL;
- presion de inyeccion;
- profundidad de inyeccion/eductor;
- area de tobera;
- diametro de garganta;
- presion de cabeza;
- balance energetico.

No se reparan ni suavizan curvas silenciosamente. Los puntos sospechosos se recalculan o se conservan con su estado. Las curvas planas no declaran un optimo artificial y los extremos de rango no se presentan como optimo interior.

## Chequeos estaticos realizados

- 256 archivos `.m` inventariados.
- 0 nombres de archivo/funcion duplicados en `src`.
- Todos los destinos publicados por los menus existen.
- 8 de 8 sensibilidades JGL tienen menu de aproximacion y reenvian el modo al ejecutor.
- 5 de 5 sensibilidades BES anunciadas existen.
- 0 referencias a `jgl_cfd_*`, `FUERA_DE_RANGO_CFD` o archivos CFD en el runtime.
- 0 llamadas activas a reparacion silenciosa de discontinuidades en sensibilidades.
- 0 valores operativos hardcodeados de 18113 o 16486 Sm3/d en `src`.
- Los dos exportadores `.aosrpt` usan `aos_preparar_snapshot_reporte`.

## Verificacion obligatoria en GNU Octave

El entorno de construccion no dispone de GNU Octave. Se incluyen tres pruebas no interactivas para ejecutar en la raiz:

```octave
VERIFICAR_ESTABILIZACION_AOS_0_0_12
VERIFICAR_QINY_HIDRAULICA_GL
VERIFICAR_SENSIBILIDADES_AOS_0_0_12
```

La segunda prueba corre MB01 con Qiny 0, 8000, referencia y 30000 Sm3/d y exige que cada valor solicitado llegue identico al balance VLP. Si Ql resulta casi plano pero el Qiny interno cambia, la salida lo clasifica explicitamente como insensibilidad del modelo/VLP, no como sobrescritura.

## Estado de entrega

- **Propagacion/configuracion:** auditada y corregida transversalmente.
- **Menus y mallas:** auditados estaticamente.
- **Runtime numerico Octave:** pendiente de ejecutar con los verificadores incluidos.
- **Fidelidad fisica JGL:** pendiente de calibracion y benchmark; CFD fuera de AOS.
