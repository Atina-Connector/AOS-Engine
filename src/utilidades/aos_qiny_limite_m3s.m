function q_m3s = aos_qiny_limite_m3s(param, cual, defecto_sm3d)
% Lee limites de sensibilidad Qiny con preferencia por Sm3/d.
% Compatibilidad: Qiny_min/Qiny_max menores que 100 se interpretan como
% MMscf/d de versiones tempranas; valores mayores se interpretan Sm3/d.
  if nargin < 3, defecto_sm3d = 0; end
  q_m3s = defecto_sm3d / 86400;
  if nargin < 2 || ~isstruct(param), return; end
  c = lower(strtrim(cual));
  if strcmp(c, 'max')
      metricos = {'Qiny_max_Sm3_d','Qiny_max_sm3d'};
      heredado = 'Qiny_max';
  else
      metricos = {'Qiny_min_Sm3_d','Qiny_min_sm3d'};
      heredado = 'Qiny_min';
  end
  for i = 1:length(metricos)
      if isfield(param, metricos{i}) && isnumeric(param.(metricos{i})) && isscalar(param.(metricos{i}))
          q_m3s = param.(metricos{i}) / 86400;
          return;
      end
  end
  if isfield(param, heredado) && isnumeric(param.(heredado)) && isscalar(param.(heredado))
      v = param.(heredado);
      if abs(v) < 100
          q_m3s = aos_mmscfd_a_m3s(v);
      else
          q_m3s = v / 86400;
      end
  end
end
