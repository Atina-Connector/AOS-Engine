# AOS 0.0.12 — JGL completo, primera versión de pruebas

Esta rama reemplaza por completo el JGL preliminar 0.0.11.

## Arquitectura

- `iterativo`: referencia física, 3 a 10 iteraciones, relajación 0.50.
- `directo`: una pasada rápida de la misma física común.
- `automatico`: ejecuta directo y obliga verificación iterativa cuando la confianza no es alta.
- sensibilidades híbridas: directo en toda la malla e iterativo en óptimo, extremos, cambios bruscos y puntos de confianza media/baja.
- indicador de confianza `ALTA/MEDIA/BAJA`, puntaje 0–100 y motivos.

## Convergencia

- error relativo de caudal menor que 0.5 %;
- cambio de Ps menor que 0.25 bar;
- cambio de DeltaP menor que 0.25 bar;
- mínimo 3 y máximo 10 iteraciones.

## CFD

La tabla gas–gas V2 se conserva en `data/CFD`. Solo se usa el dominio con resultados completos: 5–40 bar y 5.000–30.000 Sm3/d. No se extrapola silenciosamente.

## Estado físico

La conversión gas–líquido es todavía una primera formulación limitada por energía y debe calibrarse con pruebas. El programa informa dominio, potencia, eficiencia, convergencia y confianza; no oculta resultados fuera de rango.
