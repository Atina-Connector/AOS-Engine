function r = sens_bes_evaluar(p)
% SENS_BES_EVALUAR Evaluacion BES trazable para sensibilidades.

  p = sens_bes_preparar_base(p);
  audit = struct();
  audit.P_wh_efectivo_bar = leer_num(p,'P_wh',NaN) / 1e5;
  audit.D_bomba_efectiva_m = leer_num(p,'D_bomba',NaN);
  audit.frecuencia_efectiva_Hz = leer_num(p,'frecuencia',NaN);
  audit.num_etapas_efectivo = leer_num(p,'num_etapas',NaN);
  audit.IP_efectivo_m3dbar = leer_num(p,'IP',NaN) * 86400 * 1e5;
  audit.modelo_IPR = leer_txt(p,'modelo_IPR','N/A');
  audit.modelo_VLP = leer_txt(p,'modelo_VLP','N/A');

  r = struct('Ql',NaN,'Qo',NaN,'Qg_total',NaN,'P_intake',NaN,'T_motor',NaN, ...
    'Q_recirc',NaN,'corriente',NaN,'IR_actual',NaN,'IR_estado','N/A', ...
    'run_life',NaN,'diagnostico','','estado','ERROR','param',p,'audit',audit);
  try
    [r.Ql,r.Qo,r.Qg_total,r.P_intake,r.T_motor,r.Q_recirc,r.corriente, ...
      r.IR_actual,r.IR_estado,r.run_life,r.diagnostico] = BES_sim(p);
    if isfinite(r.Ql)
        r.estado = 'OK';
    else
        r.estado = 'NO_VALIDO';
    end
    r.audit.Ql_m3d = r.Ql * 86400;
    r.audit.Qo_m3d = r.Qo * 86400;
    r.audit.P_intake_bar = r.P_intake / 1e5;
  catch err
    r.diagnostico = err.message;
    r.estado = 'ERROR';
    r.audit.error = err.message;
  end
end

function v = leer_num(s,c,d)
  v=d;
  if isstruct(s) && isfield(s,c) && isnumeric(s.(c)) && isscalar(s.(c)) && isfinite(s.(c))
      v=s.(c);
  end
end

function v = leer_txt(s,c,d)
  v=d;
  if isstruct(s) && isfield(s,c) && ischar(s.(c)) && ~isempty(s.(c)), v=s.(c); end
end
