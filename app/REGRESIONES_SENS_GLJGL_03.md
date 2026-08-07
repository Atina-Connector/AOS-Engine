# Regresiones obligatorias SENS-GLJGL-03

## Gate rapido

```octave
VERIFICAR_SENS_GLJGL_03(false)
```

Debe aprobar:

1. Contrato estatico de menu, ruta motriz, grafica y reporting.
2. Derivacion de presion con `Qiny > 0` y `P_iny_sup = 0`.
3. Factibilidad con presion disponible suficiente e insuficiente.
4. Acceso real a la ruta cinetica del eductor sin retorno prematuro.
5. Inversion exacta de columna y perdidas.
6. Interpolacion del limite de inyeccion por presion.
7. Regresiones heredadas SENS02 y SENS01.
8. Simulacion puntual JGL con `Qiny` fijo usando la misma seleccion motriz explicita.

## Gate profundo

```octave
VERIFICAR_SENS_GLJGL_03(true)
VERIFICAR_AOS_0_2_0_DEV1(true)
```

El gate profundo agrega `test_sens_gljgl03_barrido_derivado_jgl`, que ejecuta un barrido corto real del motor JGL.

## Benchmark MDM-2064

Con el caso `MDM-2064.aosdat`, que importa `P_iny_sup = 0 bar`:

1. Abrir sensibilidad JGL o comparacion JGL/GL.
2. Seleccionar `Derivar la presion minima requerida desde Qiny y la tobera`.
3. Ejecutar el mismo barrido de `Qiny` utilizado en la corrida defectuosa.
4. Confirmar que JGL ya no se rechace por `SIN_PRESION_MOTRIZ` exclusivamente debido al cero importado.
5. Revisar para cada punto:
   - `P_succion_eductor_JGL_bar`;
   - `DeltaP_motriz_requerida_JGL_bar`;
   - `P_motriz_fondo_requerida_JGL_bar`;
   - `P_iny_sup_requerida_JGL_bar`;
   - estado de presion y motivos de rechazo.
6. Confirmar la nueva grafica de presiones.
7. Con una presion disponible informada, comprobar el margen y el limite de `Qiny`.
8. Comparar puntos JGL individuales y de sensibilidad usando la misma configuracion congelada.

## Criterios de rechazo

- Presion derivada no finita o negativa.
- `Pm_req` distinto de `Ps + DeltaP_motriz_req` fuera de tolerancia.
- La inversion superficial no reproduce `Pm_req` con el modelo de columna.
- Un punto en modo `PRESION_DISPONIBLE` se publica pese a ser no factible.
- El modo derivado modifica silenciosamente el valor importado de `P_iny_sup`.
- La presion importada y la configurada no pueden distinguirse en la auditoria despues de una edicion manual.
- La grafica o el reporte ocultan los puntos del solver.
- SENS02 discreto/polinomico o la paridad SENS01 sufren regresion.
