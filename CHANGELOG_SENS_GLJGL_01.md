# Changelog SENS-GLJGL-01

## Defecto corregido

Las simulaciones puntuales GL entregaban valores coherentes, pero el mismo
`Qiny` dentro de una sensibilidad podia devolver cero, valores negativos o
curvas lineales y quebradas. La causa estaba en la capa de orquestacion:
configuracion no congelada, IPR por defecto inconsistente, mallas reducidas,
mezcla de metodos JGL, estados GL forzados a `OK` y aceptacion de cualquier
numero finito aunque no hubiera convergencia.

## Cambios funcionales

1. **Fuente efectiva del caso**
   - La ultima simulacion GL es la fuente recomendada para sensibilidad GL.
   - La ultima simulacion JGL es la fuente recomendada para sensibilidad JGL.
   - Una simulacion incompatible queda como alternativa explicita, nunca como
     opcion por defecto.

2. **Paridad puntual-barrido**
   - Se crea `sens_gl_evaluar_punto` como evaluador canonico de GL.
   - El barrido llama a `GL_sim` con una fotografia inmutable del caso.
   - Se conserva el IPR y VLP efectivos del punto base.

3. **Metodo uniforme JGL**
   - Iterativo, automatico e hibrido producen una curva iterativa uniforme.
   - Directo produce una curva directa uniforme preliminar.
   - Abreviado produce una curva directa reducida preliminar.
   - No se mezclan puntos vecinos calculados con metodos o resoluciones distintos.

4. **Publicacion estricta**
   - Se separan `Ql_raw/Qo_raw` de `Ql/Qo` publicables.
   - Un punto rechazado publica `NaN`, no cero ni el ultimo iterado.
   - Se propagan estado, convergencia, residuo, advertencias y motivos.

5. **Validacion fisica**
   - `WC` debe estar en `[0,1]`.
   - `Ql >= 0`, `0 <= Qo <= Ql`.
   - `Qiny` efectivo debe coincidir con el solicitado.
   - El caudal no puede superar el maximo IPR fuera de tolerancia.
   - La potencia transferida JGL no puede superar la disponible.

6. **Curva y optimo**
   - `valido_para_curva` y `valido_para_optimo` son contratos distintos.
   - Los puntos de frontera pueden mostrarse, pero no forman un optimo interior.
   - Los modos preliminares no habilitan optimizacion tecnica ni economica.

7. **Trazabilidad**
   - Firma SHA-256 de configuracion fisica por punto.
   - Valores raw/publicados, residuos y mascaras en `.aosrpt` y CSV.

## Archivos principales

- `src/sensibilidad/sens_gl_evaluar_punto.m`
- `src/sensibilidad/sens_jgl_evaluar_punto.m`
- `src/sensibilidad/sens_validar_base_gl_jgl.m`
- `src/sensibilidad/sens_validar_punto_gl.m`
- `src/sensibilidad/sens_validar_punto_jgl.m`
- `src/core/JGL/jgl_sensibilidad_parametrica.m`
- `src/sensibilidad/sens_jgl_gl_malla.m`
- `src/sensibilidad/sens_Qiny_GL.m`
- `src/sensibilidad/sens_Qiny_JGL.m`
- `src/sensibilidad/sens_Qiny.m`

## Limite de esta entrega

La entrega fue auditada estaticamente en el entorno de construccion. La
validacion dinamica final debe ejecutarse en GNU Octave con el caso real que
reproduce la regresion.
