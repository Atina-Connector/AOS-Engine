AOS - Parche v05 - Modulo comun de tuberia
================================================

Este parche convierte el diagnostico de erosion, carga liquida y regimen Taitel
en un modulo comun para todos los sistemas de levantamiento artificial.

No reemplaza config/, datos/ ni archivos .aosdat.
Solo actualiza archivos dentro de src/ y agrega esta documentacion.

Que agrega
----------

1. Modulo comun:

   src/utilidades/diagnostico/diagnostico_tuberia_produccion.m

   Es la puerta de entrada recomendada. Cualquier sistema actual o futuro puede
   llamarla despues de resolver el caudal.

2. Motor de calculo sin grafico:

   src/utilidades/diagnostico/calcular_perfil_tuberia_produccion.m

   Calcula MD/TVD, presion, temperatura, gas local, velocidades, limites de
   erosion, carga liquida y regimen Taitel simplificado.

3. Grafico unico y detallado:

   src/utilidades/graficos/plot_erosion_taitel.m

   El grafico muestra 6 paneles:
   - trayectoria usada,
   - velocidades Vsg/Vsl/Vmix y limites,
   - margenes Vmix/Veros y Vsg/Vcarga,
   - banda de regimen Taitel,
   - perfil de gas usado,
   - resumen numerico.

4. Integracion en sistemas actuales:

   - Jet Gas Lift: src/menu/JGL_menu.m
   - Gas Lift convencional: src/menu/GL_puro_menu.m
   - BES: src/menu/BES_app.m
   - Bombeo Mecanico: src/menu/BM_menu.m

5. Compatibilidad con funciones anteriores:

   src/utilidades/diagnostico/velocidad_critica.m

   Sigue existiendo, pero ahora usa el motor comun.

Como debe usarlo un sistema futuro
----------------------------------

Despues de simular, el sistema nuevo solo necesita llamar:

   opciones = struct();
   opciones.Qgas_total_std = Qgas_total;   % m3/s std, si el sistema lo conoce
   opciones.D_inyeccion = D_sistema;       % m MD, opcional
   diagnostico_tuberia_produccion(param, 'NOMBRE_SISTEMA', Ql, Qiny, opciones);

Para un sistema sin inyeccion de gas:

   opciones = struct();
   opciones.Qgas_total_std = Qg_total;     % opcional
   diagnostico_tuberia_produccion(param, 'BES', Ql, 0, opciones);

Criterios usados
----------------

- Erosion: API RP 14E simplificado, usando velocidad de mezcla y densidad de mezcla.
- Carga liquida: Turner simplificado, usando velocidad superficial de gas.
- Regimen: Taitel simplificado, usando inclinacion petrolera del survey:
  0 grados = vertical, 90 grados = horizontal.

Nota de ingenieria
------------------

El modulo evalua la tuberia de produccion como fenomeno comun, independiente del
sistema de levantamiento. En sistemas con inyeccion de gas, el gas inyectado se
aplica solamente por encima de la profundidad de valvula/eductor/levantamiento.
Por debajo de ese punto se considera gas de formacion.
