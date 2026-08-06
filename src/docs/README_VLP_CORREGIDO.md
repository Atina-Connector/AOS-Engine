# AOS - Bloque VLP corregido para GNU Octave

Auditor técnico externo: ChatGPT.

Este paquete no modifica el proyecto original. Contiene scripts nuevos y reemplazos propuestos para el bloque VLP de AOS.

## Objetivo

Corregir los errores físicos detectados en la auditoría VLP:

1. Gas calculado como metano fijo (`M_g = 0.016`) en lugar de usar `gamma_g`.
2. Hidrostática y fricción integradas con una única distancia `dz`.
3. Inclinación aplicada de forma ambigua.
4. Caudal local de petróleo sin `Bo`.
5. Transición Duns & Ros sin acotar.
6. Holdup slug/bajo gas no garantizaba `HL -> 1` cuando `vsg -> 0`.
7. Régimen niebla con `HL = 0.005` fijo.
8. Fricción sin usar rugosidad real del survey.

## Archivos de reemplazo directo

Copiar en el proyecto AOS original:

```txt
src/core/common/vlp/vlp_HB_full.m
src/core/common/vlp/vlp_duns_ros.m
src/core/common/vlp/calcular_holdup.m
src/utilidades/nodal/compute_P_req.m
```

## Archivos nuevos necesarios

Copiar también en:

```txt
src/core/common/vlp/
```

los siguientes archivos:

```txt
aos_vlp_clamp.m
aos_vlp_getfield.m
aos_vlp_parametros.m
aos_vlp_normalizar_survey.m
aos_vlp_temperatura.m
aos_vlp_z_factor.m
aos_vlp_propiedades_locales.m
aos_vlp_friccion.m
aos_vlp_holdup_drift_flux.m
aos_vlp_holdup_HB.m
aos_vlp_holdup_duns_ros.m
aos_vlp_integrar.m
vlp_simplified_corregida.m
```

## Qué se mantiene

- Firmas originales de `vlp_HB_full`, `vlp_duns_ros`, `compute_P_req` y `calcular_holdup`.
- Compatibilidad con `modelo_VLP = 'HB'`, `'DR'` y `'simplified'`.
- Uso de `pvt_calcular.m` y `pvt_tension_superficial.m` existentes.
- Convención del survey de AOS: `inclinacion` medida desde vertical.

## Cambio físico central

Antes se integraba aproximadamente:

```txt
ΔP = gradiente_total * ΔTVD
```

Ahora se separa:

```txt
ΔP_hidro = rho_m * g * ΔTVD
ΔP_fric  = f * rho_m * vm^2 / (2*d) * ΔMD
ΔP_total = ΔP_hidro + ΔP_fric
```

Esto es clave para pozos desviados.

## Nota sobre Hagedorn-Brown

La función sigue siendo un **HB simplificado**, no una reproducción completa de las cartas originales. La mejora principal es estabilizar el holdup, corregir gas local y corregir la integración geométrica.

## Nota sobre Duns & Ros

Duns & Ros queda como modelo principal recomendado para desarrollo futuro. Esta versión corrige la transición y evita el holdup fijo en niebla, pero sigue siendo una implementación simplificada. Debe calibrarse contra datos de campo o simuladores comerciales antes de tomar decisiones operativas.

## Prueba rápida

Copiar `test_vlp_corregido.m` a la raíz de AOS y ejecutar:

```octave
test_vlp_corregido
```

El test usa el survey de `config/GL/survey.txt` si existe.
