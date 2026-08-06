function malla = gibbs3_build_rod_mesh(param)
% GIBBS3_BUILD_ROD_MESH Construye una sarta axial uniforme o combinada.

  n = param.gibbs3_n_nodos;
  L = param.D_bomba;
  x = linspace(0, L, n)';
  dx = diff(x);
  xm = 0.5 * (x(1:end-1) + x(2:end));

  [E_e, rho_e, d_e] = propiedades_elementos(param, xm);
  A_e = pi .* (d_e ./ 2).^2;
  k_e = E_e .* A_e ./ dx;
  c_e = sqrt(E_e ./ rho_e);

  % Masa consistente lumped en nodos.
  masa_elemento = rho_e .* A_e .* dx;
  m_node = zeros(n,1);
  for e = 1:n-1
    m_node(e) = m_node(e) + 0.5 * masa_elemento(e);
    m_node(e+1) = m_node(e+1) + 0.5 * masa_elemento(e);
  end

  rho_l = densidad_liquido(param);
  if strcmpi(param.gibbs3_modelo_flotacion, 'factor_explicito')
    if ~isfinite(param.gibbs3_factor_flotacion_explicito)
      error('Se selecciono factor_explicito pero no se definio un factor valido.');
    end
    bf_e = repmat(param.gibbs3_factor_flotacion_explicito, n-1, 1);
  elseif strcmpi(param.gibbs3_modelo_flotacion, 'por_densidades')
    bf_e = 1.0 - rho_l ./ rho_e;
  else
    error('Modelo de flotacion no reconocido: %s', param.gibbs3_modelo_flotacion);
  end

  vf_e = factores_verticales(param, x);

  malla = struct();
  malla.n = n;
  malla.L_m = L;
  malla.x_m = x;
  malla.dx_m = dx;
  malla.E_Pa = E_e;
  malla.rho_kg_m3 = rho_e;
  malla.diametro_m = d_e;
  malla.area_m2 = A_e;
  malla.k_e_N_m = k_e;
  malla.c_onda_m_s = c_e;
  malla.masa_elemento_kg = masa_elemento;
  malla.masa_nodal_kg = m_node;
  malla.factor_flotacion_e = bf_e;
  malla.factor_vertical_e = vf_e;
  malla.rho_liquido_kg_m3 = rho_l;
  malla.k_equivalente_N_m = 1.0 / sum(1.0 ./ k_e);
end

function [E_e, rho_e, d_e] = propiedades_elementos(param, xm)
  ne = numel(xm);
  if isempty(param.gibbs3_secciones_varillas)
    E_e = repmat(param.gibbs3_E_Pa, ne, 1);
    rho_e = repmat(param.gibbs3_rho_varilla_kg_m3, ne, 1);
    d_e = repmat(param.gibbs3_diam_varilla_mm/1000.0, ne, 1);
    return;
  end

  sec = param.gibbs3_secciones_varillas;
  limites = cumsum([sec.longitud_m]);
  E_e = zeros(ne,1); rho_e = zeros(ne,1); d_e = zeros(ne,1);
  for e = 1:ne
    idx = find(xm(e) <= limites, 1, 'first');
    if isempty(idx), idx = numel(sec); end
    E_e(e) = sec(idx).E_Pa;
    rho_e(e) = sec(idx).rho_kg_m3;
    d_e(e) = sec(idx).diametro_mm / 1000.0;
  end
end

function rho_l = densidad_liquido(param)
  rho_l = param.rho_o * (1-param.WC) + param.rho_w * param.WC;
end

function vf_e = factores_verticales(param, x)
  ne = numel(x)-1;
  vf_e = ones(ne,1);
  if ~isfield(param,'survey')
    return;
  end
  [md, tvd, ok] = leer_survey(param.survey);
  if ~ok
    return;
  end
  tvd_x = interp1(md, tvd, min(max(x,md(1)),md(end)), 'linear');
  vf_e = diff(tvd_x) ./ diff(x);
  if any(~isfinite(vf_e))
    error('El survey produjo factores verticales no finitos.');
  end
end

function [md,tvd,ok] = leer_survey(s)
  md=[]; tvd=[]; ok=false;
  if isnumeric(s) && size(s,2)>=2
    md=s(:,1); tvd=s(:,2);
  elseif isstruct(s) && isfield(s,'MD_m') && isfield(s,'TVD_m')
    md=s.MD_m(:); tvd=s.TVD_m(:);
  elseif isstruct(s) && isfield(s,'MD') && isfield(s,'TVD')
    md=s.MD(:); tvd=s.TVD(:);
  else
    return;
  end
  mask=isfinite(md)&isfinite(tvd);
  md=md(mask); tvd=tvd(mask);
  [md,idx]=sort(md); tvd=tvd(idx);
  [md,iu]=unique(md); tvd=tvd(iu);
  ok=numel(md)>=2;
end
