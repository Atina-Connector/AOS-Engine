# Parche v18.2 - BM Gibbs: promedio, cargas y diametro bomba

Parche chico instalable sobre v18.1. No contiene el programa completo.

## Instalacion

Copiar el contenido de la carpeta `AOS/` del ZIP sobre la carpeta `AOS/` existente, aceptando reemplazar los archivos indicados.

## Archivos incluidos

- `src/core/BM/gibbs_foundation/gibbs18_menu.m`
- `src/core/BM/gibbs_foundation/gibbs18_defaults.m`
- `src/core/BM/gibbs_foundation/gibbs18_solver_forward.m`
- `src/core/BM/gibbs_foundation/gibbs18_postprocess.m`
- `src/core/BM/gibbs_foundation/gibbs18_plot.m`
- `src/core/BM/gibbs_foundation/gibbs18_print.m`
- `src/core/BM/gibbs_foundation/gibbs18_static_surface_load.m`

## Cambios

1. Promedio punto a punto de cartas:
   - simula N ciclos;
   - descarta los ciclos iniciales configurados;
   - promedia punto a punto los ciclos restantes usando fase normalizada del ciclo;
   - grafica una sola carta promedio cerrada de superficie y una de fondo.

2. Revision de cargas negativas en superficie:
   - conserva `F_superficie_dinamica_N` como fuerza relativa del resorte;
   - crea `F_superficie_N` corregida con offset estatico;
   - reporta peso flotado estimado de varillas, carga media de bomba y offset aplicado.

3. Menu nuevo para diametro de bomba:
   - opcion 5: cambiar solo diametro de bomba;
   - el diametro afecta area de piston, carga de bomba y caudal teorico.

4. Menu nuevo de cargas:
   - opcion 6: activar/desactivar offset estatico o ingresar offset manual.

## Nota tecnica

Las cargas negativas de superficie aparecian porque el solver foundation calculaba la fuerza dinamica `k*(u_PR-u_2)` respecto de una sarta sin pre-estiramiento estatico. Esa magnitud puede ser negativa aunque la carga real en polished rod no lo sea. En v18.2 se guarda esa fuerza como `F_superficie_dinamica_N` y se genera una carta operativa con offset estatico estimado en `F_superficie_N`.

Este offset todavia es preliminar y debe validarse contra SROD/QROD/casos reales.
