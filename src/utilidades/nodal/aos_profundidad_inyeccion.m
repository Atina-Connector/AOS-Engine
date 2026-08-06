function D = aos_profundidad_inyeccion(param, defecto)
% aos_profundidad_inyeccion.m
% Profundidad canónica de inyección/levantamiento para GL/JGL.
% Evita usar D_bomba salvo como compatibilidad histórica.
  if nargin < 2 || isempty(defecto), defecto = NaN; end
  D = defecto;
  if nargin < 1 || ~isstruct(param), return; end
  campos = {'D_iny_m','D_iny','D_levantamiento_m','D_levantamiento', ...
            'D_valvula_m','D_valvula','D_eductor_m','D_eductor'};
  for i = 1:length(campos)
      [v, ok] = leer_num_prof(param, campos{i});
      if ok && v > 0, D = v; return; end
  end
  if isfield(param, 'gl') && isstruct(param.gl)
      campos_gl = {'D_iny_m','D_iny','D_valvula_m','D_valvula'};
      for i = 1:length(campos_gl)
          [v, ok] = leer_num_prof(param.gl, campos_gl{i});
          if ok && v > 0, D = v; return; end
      end
  end
  if isfield(param, 'jgl') && isstruct(param.jgl)
      campos_j = {'D_iny_m','D_iny','D_eductor_m','D_eductor'};
      for i = 1:length(campos_j)
          [v, ok] = leer_num_prof(param.jgl, campos_j{i});
          if ok && v > 0, D = v; return; end
      end
  end
  % Alias histórico: solo si no existe ningún campo específico GL/JGL.
  [v, ok] = leer_num_prof(param, 'D_bomba');
  if ok && v > 0, D = v; end
end

function [v, ok] = leer_num_prof(s, campo)
  v = NaN; ok = false;
  if ~isstruct(s) || ~isfield(s, campo), return; end
  x = s.(campo);
  if isnumeric(x) && ~isempty(x) && isfinite(x(1))
      v = x(1); ok = true;
  elseif ischar(x)
      y = str2double(x);
      if isfinite(y), v = y; ok = true; end
  end
end
