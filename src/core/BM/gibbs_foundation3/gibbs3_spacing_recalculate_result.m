function res = gibbs3_spacing_recalculate_result(res)
% GIBBS3_SPACING_RECALCULATE_RESULT Migra un resultado GF3 al modelo 1.7.
%
% No vuelve a ejecutar el solver. Recalcula diseno de sarta, barras e
% instruccion de espaciamiento usando los ciclos ya almacenados.

  if nargin < 1 || ~isstruct(res)
    error('Se requiere una estructura de resultado GF3.');
  end
  if ~isfield(res, 'param') || ~isstruct(res.param)
    error('El resultado no contiene res.param.');
  end
  requeridos = {'promedio','malla','equilibrio','metricas','tuberia','bomba'};
  for i = 1:numel(requeridos)
    if ~isfield(res, requeridos{i})
      error('El resultado no contiene res.%s.', requeridos{i});
    end
  end

  res.param = gibbs3_defaults(res.param);
  res.diseno_sarta_espaciamiento = gibbs3_rod_spacing_design(res);
  res.version_esquema_resultado = 'GF3_RESULTADO_1_7_ESPACIAMIENTO_DIFERENCIAL';
end
