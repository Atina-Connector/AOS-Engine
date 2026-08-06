function [Qmax_std, Pwf_fun, meta] = aos_gas_ipr(param)
% IPR de gas para CGF/EGF. Q [m3/s estándar], P [Pa].
% Modelo preferido: backpressure Q=C(Pr^2-Pwf^2)^n, con C en Sm3/d/bar^(2n).

  Pr = getnum_local(param, {'P_res'}, 200e5);
  modelo = gettext_local(param, {'gas_ipr_model','modelo_IPR_gas'}, 'BACKPRESSURE');
  meta = struct('modelo',upper(modelo),'confianza','MEDIA','origen','CONFIGURADO');

  if strcmpi(modelo,'BACKPRESSURE') || strcmpi(modelo,'FETKOVICH_GAS')
    n = getnum_local(param, {'gas_ipr_n','cgf_n','egf_n'}, 0.80);
    C = getnum_local(param, {'gas_ipr_C_Sm3_d_bar2n','cgf_C_Sm3_d_bar2n','egf_C_Sm3_d_bar2n'}, NaN);
    if ~isfinite(C) || C <= 0
      ipg = getnum_local(param, {'IP_gas_Sm3_d_bar','gas_PI_Sm3_d_bar'}, 1500.0);
      C = ipg ./ max((2 .* (Pr./1e5)).^n,1e-12);
      meta.confianza='BAJA';
      meta.origen='C_INFERIDO_DESDE_IP_GAS';
    endif
    n = min(max(n,0.50),1.50);
    Prb = Pr ./ 1e5;
    Qmax_d = C .* max(Prb.^2 - 1.0.^2,0).^n;
    Qmax_std = Qmax_d ./ 86400.0;
    Pwf_fun = @(Q) backpressure_inv_local(Q,Pr,C,n);
    meta.C = C; meta.n = n;
  else
    ipg = getnum_local(param, {'IP_gas_Sm3_d_bar','gas_PI_Sm3_d_bar'}, 1500.0);
    Qmax_std = ipg .* (Pr./1e5) ./ 86400.0;
    Pwf_fun = @(Q) max(Pr - (max(Q,0).*86400.0./ipg).*1e5,1e5);
    meta.modelo='LINEAR_GAS'; meta.IP_gas_Sm3_d_bar=ipg;
  endif
endfunction

function Pwf = backpressure_inv_local(Q,Pr,C,n)
  qd = max(Q,0).*86400.0;
  Prb = Pr./1e5;
  term = max(Prb.^2 - (qd./max(C,1e-30)).^(1./n),1.0);
  Pwf = sqrt(term).*1e5;
endfunction

function v=getnum_local(s,campos,defecto)
  v=defecto;
  for k=1:numel(campos)
    if isfield(s,campos{k})&&isnumeric(s.(campos{k}))&&~isempty(s.(campos{k}))&&isfinite(s.(campos{k})(1))
      v=s.(campos{k})(1);return;
    endif
  endfor
endfunction

function t=gettext_local(s,campos,defecto)
  t=defecto;
  for k=1:numel(campos)
    if isfield(s,campos{k})&&ischar(s.(campos{k}))&&~isempty(strtrim(s.(campos{k})))
      t=strtrim(s.(campos{k}));return;
    endif
  endfor
endfunction
