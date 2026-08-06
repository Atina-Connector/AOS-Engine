function P = sens_jgl_construir_presiones(R, Qiny_Sm3_d)
% SENS_JGL_CONSTRUIR_PRESIONES Convierte el contrato JGL a unidades visibles.

  if nargin < 1 || ~isstruct(R), R = struct(); endif
  if nargin < 2 || ~isnumeric(Qiny_Sm3_d), Qiny_Sm3_d = []; endif
  x = double(Qiny_Sm3_d(:)');
  n = numel(x);

  P = struct();
  P.schema = 'AOS_JGL_PRESSURE_SENSITIVITY_1.0';
  P.hotfix = 'SENS-GLJGL-03';
  P.Qiny_Sm3_d = x;
  P.P_succion_eductor_bar = vec_bar_local(R,'P_succion_eductor',n);
  P.DeltaP_motriz_requerida_bar = vec_bar_local(R,'deltaP_motriz_requerida',n);
  P.P_motriz_fondo_requerida_bar = vec_bar_local(R,'P_motriz_fondo_requerida',n);
  P.P_motriz_fondo_disponible_bar = vec_bar_local(R,'P_motriz_fondo_disponible',n);
  P.P_motriz_fondo_efectiva_bar = vec_bar_local(R,'P_motriz_fondo_efectiva',n);
  P.P_iny_sup_requerida_bar = vec_bar_local(R,'P_iny_sup_requerida',n);
  P.P_iny_sup_disponible_bar = vec_bar_local(R,'P_iny_sup_disponible',n);
  P.P_iny_sup_efectiva_bar = vec_bar_local(R,'P_iny_sup_efectiva',n);
  P.DeltaP_columna_gas_bar = vec_bar_local(R,'deltaP_columna_gas_requerida',n);
  P.DeltaP_friccion_inyeccion_bar = vec_bar_local(R,'deltaP_friccion_inyeccion',n);
  P.Margen_presion_superficie_bar = vec_bar_local(R,'margen_presion_superficie',n);
  P.presion_requerida_valida = vec_log_local(R,'presion_requerida_valida',n);
  P.factibilidad_presion_evaluada = vec_log_local(R,'factibilidad_presion_evaluada',n);
  P.factible_por_presion = vec_num_local(R,'factible_por_presion',n);
  P.estado_presion_motriz = vec_cell_local(R,'estado_presion_motriz',n,'NO_EVALUADO');
  P.modo_condicion_motriz = vec_cell_local(R,'modo_condicion_motriz',n,'NO_INFORMADO');
  P.origen_presion_motriz = vec_cell_local(R,'origen_presion_motriz',n,'NO_DEFINIDO');
  P.limite_presion = sens_jgl_limite_presion(x,P.P_iny_sup_requerida_bar,P.P_iny_sup_disponible_bar);

  P.modo_global = primer_texto_local(P.modo_condicion_motriz,'NO_INFORMADO');
  P.origen_global = primer_texto_local(P.origen_presion_motriz,'NO_DEFINIDO');
  disp = P.P_iny_sup_disponible_bar(isfinite(P.P_iny_sup_disponible_bar));
  if isempty(disp), P.P_iny_sup_disponible_global_bar = NaN;
  else, P.P_iny_sup_disponible_global_bar = disp(1); endif
endfunction

function v = vec_bar_local(R,c,n)
  v = vec_num_local(R,c,n) / 1e5;
endfunction

function v = vec_num_local(R,c,n)
  v = NaN(1,n);
  if isstruct(R) && isfield(R,c) && isnumeric(R.(c))
    x = double(R.(c)(:)');
    m = min(n,numel(x));
    v(1:m) = x(1:m);
  endif
endfunction

function v = vec_log_local(R,c,n)
  v = false(1,n);
  if isstruct(R) && isfield(R,c)
    x = R.(c);
    if islogical(x) || isnumeric(x)
      x = logical(x(:)');
      m = min(n,numel(x)); v(1:m) = x(1:m);
    endif
  endif
endfunction

function v = vec_cell_local(R,c,n,defecto)
  v = repmat({defecto},1,n);
  if isstruct(R) && isfield(R,c) && iscell(R.(c))
    x = R.(c); m = min(n,numel(x));
    for i = 1:m
      if ischar(x{i}) && ~isempty(x{i}), v{i} = x{i}; endif
    endfor
  endif
endfunction

function t = primer_texto_local(c,d)
  t = d;
  if ~iscell(c), return; endif
  for i = 1:numel(c)
    if ischar(c{i}) && ~isempty(c{i}) && ~strcmp(c{i},'NO_INFORMADO') && ~strcmp(c{i},'NO_DEFINIDO')
      t = c{i}; return;
    endif
  endfor
endfunction
