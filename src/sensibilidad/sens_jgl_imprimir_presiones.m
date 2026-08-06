function sens_jgl_imprimir_presiones(P, titulo)
% SENS_JGL_IMPRIMIR_PRESIONES Tabla de diseno motriz por Qiny.
  if nargin < 2 || isempty(titulo), titulo = 'JGL'; endif
  if nargin < 1 || ~isstruct(P), return; endif
  n = numel(P.Qiny_Sm3_d);
  fprintf('\n=== PRESIONES REQUERIDAS DEL EDUCTOR - %s - SENS-GLJGL-03 ===\n',titulo);
  fprintf('Qiny | Ps | dP motriz req | Pm fondo req | dP columna | dP fric | P sup req | P sup disp | Margen | Estado\n');
  fprintf('(Sm3/d)|(bar)|    (bar)     |    (bar)     |   (bar)    |  (bar)  |   (bar)   |   (bar)    | (bar)  |\n');
  for i = 1:n
    fprintf('%7.0f | %7.2f | %13.3f | %12.3f | %10.3f | %8.3f | %9.3f | %10.3f | %7.3f | %s\n', ...
      P.Qiny_Sm3_d(i),P.P_succion_eductor_bar(i),P.DeltaP_motriz_requerida_bar(i), ...
      P.P_motriz_fondo_requerida_bar(i),P.DeltaP_columna_gas_bar(i), ...
      P.DeltaP_friccion_inyeccion_bar(i),P.P_iny_sup_requerida_bar(i), ...
      P.P_iny_sup_disponible_bar(i),P.Margen_presion_superficie_bar(i), ...
      P.estado_presion_motriz{i});
  endfor
  L = P.limite_presion;
  fprintf('Modo motriz: %s | Origen: %s\n',P.modo_global,P.origen_global);
  if L.evaluado && isfinite(L.Qiny_max_presion_Sm3_d)
    fprintf('Qiny maximo por presion disponible: %.0f Sm3/d (%s)\n', ...
      L.Qiny_max_presion_Sm3_d,L.estado);
  else
    fprintf('Limite por presion: %s\n',L.estado);
  endif
  fprintf('================================================================\n');
endfunction
