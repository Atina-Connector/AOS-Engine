function h = sens_jgl_graficar_presiones(P, titulo)
% SENS_JGL_GRAFICAR_PRESIONES Grafica requerida por SENS-GLJGL-03.
% Arriba: presiones absolutas. Abajo: componentes de la presion requerida.
  if nargin < 2 || isempty(titulo), titulo = 'JGL'; endif
  if nargin < 1 || ~isstruct(P), P = struct(); endif
  h = figure;
  x = P.Qiny_Sm3_d;

  subplot(2,1,1);
  leg = {};
  plot(x,P.P_succion_eductor_bar,'-o','LineWidth',2); hold on;
  leg{end+1} = 'Ps succion eductor';
  plot(x,P.P_motriz_fondo_requerida_bar,'-s','LineWidth',2);
  leg{end+1} = 'Pm fondo requerida = Ps + dP motriz';
  if any(isfinite(P.P_motriz_fondo_disponible_bar))
    plot(x,P.P_motriz_fondo_disponible_bar,'--','LineWidth',2);
    leg{end+1} = 'Pm fondo disponible';
  endif
  plot(x,P.P_iny_sup_requerida_bar,'-^','LineWidth',2);
  leg{end+1} = 'P superficie requerida';
  if any(isfinite(P.P_iny_sup_disponible_bar))
    plot(x,P.P_iny_sup_disponible_bar,'--','LineWidth',2);
    leg{end+1} = 'P superficie disponible';
  endif
  grid on;
  xlabel('Qiny (Sm3/d)'); ylabel('Presion (bar)');
  title([titulo ': presiones necesarias para operacion del eductor']);
  legend(leg,'Location','northeast');

  if isfield(P,'limite_presion') && isstruct(P.limite_presion) && ...
      P.limite_presion.evaluado && isfinite(P.limite_presion.Qiny_max_presion_Sm3_d)
    yl = ylim(); qlim = P.limite_presion.Qiny_max_presion_Sm3_d;
    plot([qlim qlim],yl,':','LineWidth',1.5);
    ylim(yl);
  endif

  subplot(2,1,2);
  leg2 = {};
  plot(x,P.DeltaP_motriz_requerida_bar,'-o','LineWidth',2); hold on;
  leg2{end+1} = 'dP motriz requerido';
  plot(x,P.DeltaP_columna_gas_bar,'-s','LineWidth',2);
  leg2{end+1} = 'Aporte columna de gas';
  plot(x,P.DeltaP_friccion_inyeccion_bar,'-^','LineWidth',2);
  leg2{end+1} = 'Perdida conducto inyeccion';
  if any(isfinite(P.Margen_presion_superficie_bar))
    plot(x,P.Margen_presion_superficie_bar,'--','LineWidth',2);
    leg2{end+1} = 'Margen superficie';
  endif
  grid on;
  xlabel('Qiny (Sm3/d)'); ylabel('Diferencial / margen (bar)');
  title('Descomposicion: Pm requerida = Ps + dP motriz');
  legend(leg2,'Location','northeast');
endfunction
