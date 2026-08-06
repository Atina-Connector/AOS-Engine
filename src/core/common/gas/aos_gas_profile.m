function [P_end, perfil] = aos_gas_profile(P_start, Qstd, md_start, md_end, diametro, param, sentido)
% Integra presión de gas real a lo largo de un tramo.
% Qstd [m3/s estándar]. sentido:
%   'FOLLOW'  : el recorrido md_start->md_end sigue al flujo.
%   'OPPOSE'  : el recorrido se hace contra el flujo (presión requerida).

  if nargin < 7 || isempty(sentido), sentido = 'FOLLOW'; endif
  if nargin < 6 || ~isstruct(param), param = struct(); endif
  if nargin < 5 || ~isfinite(diametro) || diametro <= 0, diametro = 0.062; endif
  P_start = max(P_start, 1.0e4);
  Qstd = max(Qstd, 0);
  L = abs(md_end - md_start);
  paso = getnum_local(param, {'gas_profile_step_m','paso_perfil_gas_m'}, 10.0);
  n = max(2, ceil(L ./ max(paso,1)) + 1);
  md = linspace(md_start, md_end, n)';
  tvd = zeros(n,1); T = zeros(n,1); P = zeros(n,1);
  rho = zeros(n,1); vel = zeros(n,1); Re = zeros(n,1); f = zeros(n,1);
  tvd(1) = aos_gas_tvd_at_md(param,md(1));
  T(1) = aos_temperatura_at_md(param,md(1));
  P(1) = P_start;
  A = pi .* diametro.^2 ./ 4.0;
  if isfield(param,'gas_profile_area_m2') && isnumeric(param.gas_profile_area_m2) && isscalar(param.gas_profile_area_m2) && isfinite(param.gas_profile_area_m2) && param.gas_profile_area_m2>0
    A = param.gas_profile_area_m2;
  endif
  epsr = getnum_local(param, {'rugosidad','roughness'}, 4.6e-5);
  seguir = strcmpi(sentido,'FOLLOW');

  for i = 1:n-1
    tvd(i+1) = aos_gas_tvd_at_md(param,md(i+1));
    T(i+1) = aos_temperatura_at_md(param,md(i+1));
    pgas = aos_gas_props(P(i),0.5*(T(i)+T(i+1)),param);
    rho(i) = pgas.rho;
    qloc = Qstd .* (pgas.Pstd ./ P(i)) .* ...
           (0.5*(T(i)+T(i+1)) ./ pgas.Tstd) .* pgas.Z;
    vel(i) = qloc ./ max(A,1e-12);
    Re(i) = pgas.rho .* abs(vel(i)) .* diametro ./ max(pgas.mu,1e-12);
    f(i) = factor_friccion_local(Re(i),epsr./diametro);
    dmd = abs(md(i+1)-md(i));
    dtvd = tvd(i+1)-tvd(i);
    dP_h = pgas.rho .* 9.80665 .* dtvd;
    dP_f = f(i) .* dmd ./ diametro .* 0.5 .* pgas.rho .* vel(i).^2;
    if seguir
      P(i+1) = P(i) + dP_h - dP_f;
    else
      P(i+1) = P(i) + dP_h + dP_f;
    endif
    P(i+1) = max(P(i+1),1.0e4);
  endfor
  pg = aos_gas_props(P(end),T(end),param);
  rho(end)=pg.rho;
  qloc=Qstd*(pg.Pstd/P(end))*(T(end)/pg.Tstd)*pg.Z;
  vel(end)=qloc/max(A,1e-12);
  Re(end)=pg.rho*abs(vel(end))*diametro/max(pg.mu,1e-12);
  f(end)=factor_friccion_local(Re(end),epsr/diametro);

  P_end = P(end);
  perfil = struct('MD',md,'TVD',tvd,'T',T,'P',P,'rho',rho, ...
                  'velocidad',vel,'Re',Re,'f',f,'Qstd',Qstd, ...
                  'diametro',diametro,'sentido',upper(sentido));
endfunction

function ff = factor_friccion_local(Re,rr)
  if ~isfinite(Re) || Re <= 0
    ff = 0;
  elseif Re < 2300
    ff = 64 ./ max(Re,1);
  else
    ff = 0.25 ./ (log10(max(rr./3.7 + 5.74./Re.^0.9,1e-12))).^2;
  endif
  ff = min(max(ff,0),0.2);
endfunction

function v=getnum_local(s,campos,defecto)
  v=defecto;
  for k=1:numel(campos)
    if isfield(s,campos{k})&&isnumeric(s.(campos{k}))&&~isempty(s.(campos{k}))&&isfinite(s.(campos{k})(1))
      v=s.(campos{k})(1);return;
    endif
  endfor
endfunction
