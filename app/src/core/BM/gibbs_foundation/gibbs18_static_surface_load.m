function diag = gibbs18_static_surface_load(param, malla, Fb)
% Estima el offset estatico que debe sumarse a la fuerza dinamica de superficie.
% La fuerza del solver Ftop = k*(u_PR-u_2) es una fuerza dinamica relativa a
% una sarta sin pre-estiramiento gravitatorio. Por eso puede quedar negativa.
% Para carta operativa de superficie se agrega una carga media estatica estimada.
  if nargin < 1 || ~isstruct(param), param = struct(); end
  if nargin < 2 || ~isstruct(malla), malla = struct(); end
  if nargin < 3 || isempty(Fb), Fb = 0; end

  Drod = leer_num(param,'gibbs18_diam_varilla_mm',22.2)/1000;
  Arod = pi*(max(Drod,1e-6)/2)^2;
  L = leer_num(malla,'L',leer_num(param,'D_bomba',1500));
  rho_rod = leer_num(param,'gibbs18_rho_rod',7850);
  bf = leer_num(param,'gibbs18_buoyancy_factor_rods',0.87);
  Wrod = rho_rod*9.81*Arod*max(L,0)*bf;

  Fb_mean = mean(Fb(:));
  if ~isfinite(Fb_mean), Fb_mean = 0; end

  manual = leer_num(param,'gibbs18_surface_offset_manual_N',NaN);
  if isfinite(manual)
      offset = manual;
      modo = 'manual';
  else
      % Primer criterio conservador: peso flotado de varillas + carga media de bomba.
      % No pretende ser calibracion final; evita graficar cargas negativas por falta
      % de pre-estiramiento estatico en el modelo foundation.
      offset = Wrod + max(Fb_mean,0);
      modo = 'estimado';
  end

  diag = struct();
  diag.modo = modo;
  diag.peso_varillas_flotado_N = Wrod;
  diag.carga_bomba_media_N = Fb_mean;
  diag.offset_superficie_N = offset;
  diag.nota = ['F_superficie_dinamica_N puede ser negativa porque esta referida ' ...
               'a la deformacion dinamica. F_superficie_N incluye offset estatico.'];
end

function v = leer_num(s,campo,def)
  v = def;
  if isstruct(s) && isfield(s,campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1)), v = tmp(1); end
  end
end
