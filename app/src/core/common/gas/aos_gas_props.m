function props = aos_gas_props(P, T, param)
% Propiedades de gas real para screening AOS 0.1.1.
% P [Pa], T [K]. Usa Sutton + Papay para Z y Lee para viscosidad.

  if nargin < 3 || ~isstruct(param), param = struct(); endif
  P = max(P, 1.0e4);
  T = max(T, 150.0);
  gg = getnum_local(param, {'gamma_g','gravedad_especifica_gas'}, 0.70);
  gg = min(max(gg, 0.50), 1.50);

  if isfield(param, 'Z_gas') && isnumeric(param.Z_gas) && isscalar(param.Z_gas) && isfinite(param.Z_gas)
    Z = param.Z_gas .* ones(size(P));
    metodo_Z = 'FIJO_USUARIO';
  else
    P_psia = P .* 0.000145037738;
    T_R = T .* 1.8;
    Ppc = 756.8 - 131.0 .* gg - 3.6 .* gg.^2;
    Tpc = 169.2 + 349.5 .* gg - 74.0 .* gg.^2;
    Ppr = P_psia ./ max(Ppc, 1.0);
    Tpr = T_R ./ max(Tpc, 1.0);
    Z = 1.0 - 3.52 .* Ppr .* exp(-2.26 .* Tpr) + ...
        0.274 .* Ppr.^2 .* exp(-1.878 .* Tpr);
    Z = min(max(Z, 0.20), 1.40);
    metodo_Z = 'SUTTON_PAPAY_SCREENING';
  endif

  R = 287.05 ./ gg;
  if isfield(param,'R_gas') && isnumeric(param.R_gas) && isscalar(param.R_gas) && isfinite(param.R_gas)
    R = param.R_gas;
  endif
  k = getnum_local(param, {'k_gas','gamma_calor_especifico'}, 1.28);
  k = min(max(k, 1.05), 1.45);
  cp = k .* R ./ max(k - 1.0, 0.05);
  rho = P ./ max(Z .* R .* T, 1.0e-12);

  % Lee-Gonzalez-Eakin. Resultado final en Pa.s.
  M = 28.97 .* gg;
  T_R = T .* 1.8;
  K = ((9.379 + 0.01607 .* M) .* T_R.^1.5) ./ ...
      (209.2 + 19.26 .* M + T_R);
  X = 3.448 + 986.4 ./ T_R + 0.01009 .* M;
  Y = 2.447 - 0.2224 .* X;
  rho_g_cc = rho ./ 1000.0;
  mu_cp = 1.0e-4 .* K .* exp(X .* rho_g_cc.^Y);
  mu = min(max(mu_cp .* 1.0e-3, 5.0e-6), 8.0e-5);

  Pstd = getnum_local(param, {'P_std','Pstd'}, 101325.0);
  Tstd = getnum_local(param, {'T_std','Tstd'}, 288.15);
  Zstd = 1.0;
  rho_std = Pstd ./ (Zstd .* R .* Tstd);

  props = struct();
  props.P = P;
  props.T = T;
  props.Z = Z;
  props.rho = rho;
  props.mu = mu;
  props.R = R;
  props.k = k;
  props.cp = cp;
  props.rho_std = rho_std;
  props.Pstd = Pstd;
  props.Tstd = Tstd;
  props.metodo_Z = metodo_Z;
endfunction

function v = getnum_local(s, campos, defecto)
  v = defecto;
  for i = 1:numel(campos)
    f = campos{i};
    if isfield(s,f) && isnumeric(s.(f)) && ~isempty(s.(f)) && isfinite(s.(f)(1))
      v = s.(f)(1);
      return;
    endif
  endfor
endfunction
