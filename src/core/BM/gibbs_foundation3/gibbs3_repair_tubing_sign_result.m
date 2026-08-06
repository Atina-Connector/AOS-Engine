function [res, cambios, fisica_modificada] = gibbs3_repair_tubing_sign_result(res, recalcular_derivados)
% GIBBS3_REPAIR_TUBING_SIGN_RESULT Repara resultados GF3 residentes.
%
% No vuelve a integrar la sarta ni cambia cargas. Reconstruye la elongacion
% positiva del tubing, la posicion firmada del barril y la posicion relativa
% piston-barril a partir de F_bomba_N y u_varilla_fondo_m.

  if nargin < 2, recalcular_derivados = true; endif
  cambios = {};
  fisica_modificada = false;

  if nargin < 1 || ~isstruct(res) || ~isfield(res, 'param') || ...
      ~isstruct(res.param) || ~isfield(res, 'promedio') || ...
      ~isstruct(res.promedio)
    error('Resultado GF3 incompleto para reparar el signo de tubing.');
  endif

  version_origen = '';
  if isfield(res, 'version') && ischar(res.version)
    version_origen = res.version;
  elseif isfield(res.param, 'gibbs3_version') && ...
      ischar(res.param.gibbs3_version)
    version_origen = res.param.gibbs3_version;
  endif

  p = gibbs3_defaults(res.param);
  prom = res.promedio;

  if ~isfield(prom, 'F_bomba_N') || isempty(prom.F_bomba_N)
    error('Resultado GF3 sin F_bomba_N promedio.');
  endif
  F = prom.F_bomba_N(:);

  if isfield(prom, 'u_varilla_fondo_m') && ...
      numel(prom.u_varilla_fondo_m) == numel(F)
    urod = prom.u_varilla_fondo_m(:);
  elseif isfield(prom, 'U_m') && size(prom.U_m,1) == numel(F)
    urod = prom.U_m(:,end);
    cambios{end+1} = 'promedio.u_varilla_fondo_m_reconstruido';
  else
    error('Resultado GF3 sin posicion compatible de varilla de fondo.');
  endif

  tub_nuevo = gibbs3_tubing_motion(p, F);
  utub_nuevo = tub_nuevo.u_fondo_m(:);
  elong_nueva = tub_nuevo.elongacion_m(:);
  urel_nuevo = urod - utub_nuevo;

  tol = 1e-10 * max([max(abs(urod)), max(abs(utub_nuevo)), ...
    max(abs(urel_nuevo)), 1]);

  if ~campo_vector_igual_local(prom, 'u_tuberia_fondo_m', utub_nuevo, tol)
    fisica_modificada = true;
    cambios{end+1} = 'promedio.u_tuberia_fondo_m_signo_corregido';
  endif
  if ~campo_vector_igual_local(prom, 'u_piston_relativo_m', urel_nuevo, tol)
    fisica_modificada = true;
    cambios{end+1} = 'promedio.u_piston_relativo_m_recalculado';
  endif
  if ~isfield(res, 'tuberia') || ~isstruct(res.tuberia) || ...
      ~isfield(res.tuberia, 'elongacion_m') || ...
      ~isfield(res.tuberia, 'u_fondo_m')
    fisica_modificada = true;
    cambios{end+1} = 'tuberia.campos_signo_agregados';
  endif

  res.param = p;
  if ~isempty(version_origen) && ~strcmp(version_origen, p.gibbs3_version)
    res.gf3_version_origen_antes_signo = version_origen;
  endif
  res.version = p.gibbs3_version;
  res.modelo = p.gibbs3_modelo;
  res.tuberia = tub_nuevo;
  prom.u_varilla_fondo_m = urod;
  prom.u_tuberia_fondo_m = utub_nuevo;
  prom.elongacion_tuberia_m = elong_nueva;
  prom.u_piston_relativo_m = urel_nuevo;
  prom.u_bomba_m = urel_nuevo;
  prom.tuberia = tub_nuevo;

  if isfield(p, 'gibbs3_normalizar_posiciones_grafico') && ...
      logical(p.gibbs3_normalizar_posiciones_grafico)
    if isfield(prom, 'u_superficie_m')
      prom.u_superficie_plot_m = normalizar_local(prom.u_superficie_m);
    endif
    prom.u_varilla_fondo_plot_m = normalizar_local(urod);
    prom.u_tuberia_fondo_plot_m = normalizar_local(utub_nuevo);
    prom.u_piston_relativo_plot_m = normalizar_local(urel_nuevo);
    prom.u_bomba_plot_m = prom.u_piston_relativo_plot_m;
  else
    if isfield(prom, 'u_superficie_m')
      prom.u_superficie_plot_m = prom.u_superficie_m;
    endif
    prom.u_varilla_fondo_plot_m = urod;
    prom.u_tuberia_fondo_plot_m = utub_nuevo;
    prom.u_piston_relativo_plot_m = urel_nuevo;
    prom.u_bomba_plot_m = urel_nuevo;
  endif

  res.promedio = prom;
  res.gf3_tubing_sign_schema = 'GF3_TUBING_SIGN_1_8';

  if fisica_modificada
    if ~isfield(res, 'advertencias') || ~iscell(res.advertencias)
      res.advertencias = {};
    endif
    aviso = ['Resultado GF3 residente actualizado a la convencion fisica ' ...
      'de signo de tubing libre v1.8; cargas del solver no modificadas.'];
    if ~any(strcmp(res.advertencias, aviso))
      res.advertencias{end+1} = aviso;
    endif
  endif

  if recalcular_derivados
    if isfield(res, 'bomba') && isstruct(res.bomba)
      res.metricas = gibbs3_metrics(res);
    endif
    if puede_recalcular_spacing_local(res)
      res.diseno_sarta_espaciamiento = gibbs3_rod_spacing_design(res);
    endif
  endif
endfunction

function tf = campo_vector_igual_local(s, campo, esperado, tol)
  tf = false;
  if ~isstruct(s) || ~isfield(s, campo) || ~isnumeric(s.(campo))
    return;
  endif
  valor = s.(campo);
  tf = numel(valor) == numel(esperado) && ...
    all(isfinite(valor(:))) && ...
    max(abs(valor(:) - esperado(:))) <= tol;
endfunction

function tf = puede_recalcular_spacing_local(res)
  req = {'param','malla','promedio','equilibrio','tuberia'};
  tf = true;
  for i = 1:numel(req)
    if ~isfield(res, req{i}) || ~isstruct(res.(req{i}))
      tf = false;
      return;
    endif
  endfor
  tf = isfield(res.promedio, 'U_m') && ~isempty(res.promedio.U_m);
endfunction

function y = normalizar_local(x)
  y = x - min(x);
endfunction
