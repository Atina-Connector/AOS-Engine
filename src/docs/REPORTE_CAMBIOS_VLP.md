# Reporte de cambios VLP - AOS

**Rol:** auditor técnico externo.  
**Estado:** scripts generados para revisión e integración manual.  
**Compatibilidad:** GNU Octave.

## 1. Correcciones comunes HB / Duns & Ros

### Gas local

Se reemplaza la masa molar fija:

```octave
M_g = 0.016;
```

por:

```octave
M_g = gamma_g * 0.028967;
```

Además, el gas local usa presión, temperatura y factor Z del segmento.

### Geometría MD/TVD

Se elimina la integración única con `dz` para todo. Ahora:

- hidrostática se integra con `ΔTVD`;
- fricción se integra con `ΔMD`.

### Caudal líquido local

El petróleo local se calcula con `Bo`:

```octave
Qo_local = Qo_std * Bo;
Qw_local = Qw_std;
Ql_local = Qo_local + Qw_local;
```

### Rugosidad

La fricción usa `survey.rugosidad` cuando está disponible.

### Convención angular

Se conserva la convención AOS:

```txt
0° = vertical
90° = horizontal
```

El ángulo ya no se usa para multiplicar hidrostática cuando ya se está usando `ΔTVD`.

## 2. Correcciones HB

- Nuevo helper: `aos_vlp_holdup_HB.m`.
- `calcular_holdup.m` queda como compatibilidad y redirige al helper nuevo.
- Se estabiliza bajo gas con `aos_vlp_holdup_drift_flux.m`.
- Se mantiene el carácter HB simplificado.

## 3. Correcciones Duns & Ros

- Nuevo helper: `aos_vlp_holdup_duns_ros.m`.
- Transición de régimen acotada con `clamp`.
- Slug/bajo gas con drift-flux.
- Niebla sin `HL = 0.005` fijo.
- Se evita que `HL` caiga por debajo de la fracción no-slip salvo límites controlados.

## 4. Archivos generados

Ver `README_VLP_CORREGIDO.md`.

## 5. Recomendación de integración

1. Hacer backup de los archivos originales.
2. Copiar primero los helpers nuevos en `src/core/common/vlp/`.
3. Reemplazar `vlp_HB_full.m`, `vlp_duns_ros.m`, `calcular_holdup.m`.
4. Reemplazar `compute_P_req.m`.
5. Ejecutar `test_vlp_corregido.m`.
6. Comparar presión perfil HB/DR contra una corrida vieja.
7. Recién después integrar en JGL/GL/BES.

## 6. Advertencia técnica

Estos scripts corrigen errores físicos estructurales, pero no equivalen todavía a una validación de campo. La próxima etapa debería ser calibración contra datos medidos o contra un simulador de referencia.
