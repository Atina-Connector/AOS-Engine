# AOS - Modulo BM Gibbs Solver Foundation v18

## Estado
Experimental, Octave-first. No reemplaza al BM operativo ni al Gibbs Lab v17.

## Objetivo del parche
Crear una tercera opcion dentro del menu de Bombeo Mecanico para probar la fundacion del solver Gibbs de BM:

- movimiento impuesto en polished rod;
- sarta como medio elastico distribuido;
- bomba como condicion de borde inferior;
- simulacion de cinco ciclos;
- descarte del primer ciclo;
- promedio/postproceso sobre ciclos estables;
- generacion de carta de superficie y carta de fondo sin hardcodear oscilaciones.

## Menu
En `BM_menu` se agrega:

```text
3 - BM Gibbs Solver Foundation v18 (Octave)
```

## Carpeta nueva

```text
src/core/BM/gibbs_foundation/
```

Archivos principales:

- `gibbs18_menu.m`
- `gibbs18_defaults.m`
- `gibbs18_run_case.m`
- `gibbs18_build_rod_mesh.m`
- `gibbs18_surface_motion.m`
- `gibbs18_bottom_boundary.m`
- `gibbs18_solver_forward.m`
- `gibbs18_postprocess.m`
- `gibbs18_print.m`
- `gibbs18_plot.m`

## Criterio de ingenieria
Este parche es una fundacion numerica, no una afirmacion de equivalencia con QROD/SROD ni con un caso comercial. La validacion queda para v19.

## Compatibilidad
Codigo escrito para GNU Octave. No requiere toolboxes propietarios.

