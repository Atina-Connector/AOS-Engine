# AOS 0.1.1-alpha1 — BES V2, CGF y EGF

Rama funcional para comenzar pruebas físicas y numéricas en GNU Octave.

## Módulos nuevos

- **BES V2**: solver único, intake específico, curva con BEP, gas libre, separador, potencia de eje, motor PM, cable, VSD y térmica.
- **CGF V1**: compresor axial de fondo con mapa corregido, surge/choke, compresión politrópica y motor PM.
- **EGF V1**: eyector gas-gas cuasi-1D con tobera primaria/secundaria, choking, mezcla y recuperación en difusor.

Los tres módulos son versiones de **screening y evaluación física inicial**. Los catálogos genéricos no sustituyen curvas OEM ni datos de prueba.

## Arranque

```octave
AOS
```

## Verificación

```octave
VERIFICAR_AOS_0_1_1_ALPHA
```

## Regla de validación

No modificar GL/JGL, Mandriles o BM durante la evaluación de esta rama. BES V1 permanece disponible como legado y comparación.
