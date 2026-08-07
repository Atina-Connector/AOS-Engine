function [res, cambios] = gibbs3_repair_spacing_result(res)
% GIBBS3_REPAIR_SPACING_RESULT Recalcula spacing en resultados residentes.
%
% Repara resultados creados por versiones que dejaban longitud de tubing
% anclada como NaN y convertian una correccion no finita en levantamiento 0.

  cambios = {};
  if nargin < 1 || ~isstruct(res)
    error('Se requiere un resultado GF3 valido.');
  end
  if ~isfield(res, 'param') || ~isstruct(res.param)
    error('El resultado GF3 no contiene param.');
  end

  if exist('gibbs3_upgrade_result_schema', 'file') == 2
    res = gibbs3_upgrade_result_schema(res);
  end

  res.param = gibbs3_defaults(res.param);
  res.version = res.param.gibbs3_version;

  if isfield(res, 'tuberia') && isstruct(res.tuberia)
    if ~isfield(res.tuberia, 'longitud_m') || ...
        ~isfinite(res.tuberia.longitud_m) || res.tuberia.longitud_m <= 0
      if isfinite(res.param.longitud_tuberia_m) && ...
          res.param.longitud_tuberia_m > 0
        res.tuberia.longitud_m = res.param.longitud_tuberia_m;
      else
        res.tuberia.longitud_m = res.param.D_bomba;
      end
      cambios{end+1} = 'tuberia.longitud_m';
    end
    if res.param.tuberia_anclada
      res.tuberia.delta_max_m = 0.0;
      campos_cero = {'x_tuberia_m','elongacion_m','u_fondo_m'};
      for ic = 1:numel(campos_cero)
        if isfield(res.tuberia, campos_cero{ic})
          valor_cero = res.tuberia.(campos_cero{ic});
          valor_cero(:) = 0.0;
          res.tuberia.(campos_cero{ic}) = valor_cero;
        endif
      endfor
      if isfield(res, 'promedio') && isstruct(res.promedio)
        if isfield(res.promedio, 'u_tuberia_fondo_m')
          res.promedio.u_tuberia_fondo_m(:) = 0.0;
        endif
        if isfield(res.promedio, 'elongacion_tuberia_m')
          res.promedio.elongacion_tuberia_m(:) = 0.0;
        endif
      endif
      cambios{end+1} = 'tuberia_anclada_sin_desplazamiento';
    endif
  end

  requeridos = {'promedio', 'malla', 'equilibrio', 'metricas', 'tuberia'};
  for i = 1:numel(requeridos)
    if ~isfield(res, requeridos{i})
      error('No se puede reparar spacing: falta res.%s.', requeridos{i});
    end
  end

  res.diseno_sarta_espaciamiento = gibbs3_rod_spacing_design(res);
  cambios{end+1} = 'diseno_sarta_espaciamiento.espaciamiento';

  try
    [ok, msg] = gibbs3_validate_result(res);
    res.validacion = struct('ok', ok, 'mensajes', {msg});
    cambios{end+1} = 'validacion';
  catch
  end

  res.schema_spacing = 'GF3_SPACING_1_6_2_FINITO_SEGURO';
  res.gf3_tubing_sign_schema = 'GF3_TUBING_SIGN_1_8';
end
