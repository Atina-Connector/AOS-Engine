function varargout = aos_sla_intake_guard(sistema, Ql, varargin)
% aos_sla_intake_guard.m - AOS 0.0.11
% Guardia comun de intake para Sistemas de Levantamiento Artificial (SLA).
%
% Principio:
%   El solver no maquilla resultados. Si el reservorio no puede sostener
%   el nivel de intake requerido por el SLA, AOS lo informa como diagnostico.
%
% Usos compatibles:
%   guard = aos_sla_intake_guard(sistema, Ql, param)
%   guard = aos_sla_intake_guard(sistema, Ql, P_raw, param)
%   guard = aos_sla_intake_guard(sistema, Ql, P_raw, param, detalle)
%   guard = aos_sla_intake_guard(sistema, Ql, P_usada, detalle, param)
%   guard = aos_sla_intake_guard(sistema, Ql, P_raw, P_usada, param)
%   [estado, mensaje, detalle] = aos_sla_intake_guard(...)

  if nargin < 1 || isempty(sistema), sistema = 'SLA'; end
  if nargin < 2 || isempty(Ql), Ql = NaN; end

  P_raw = NaN;
  P_usada = NaN;
  param = struct();
  detalle = struct();

  % ------------------------------------------------------------------
  % Parser defensivo de firmas antiguas/nuevas.
  % ------------------------------------------------------------------
  for i = 1:length(varargin)
      a = varargin{i};
      if isnumeric(a) && ~isempty(a)
          val = a(1);
          if ~isfinite(P_raw)
              P_raw = val;
              P_usada = val;
          elseif ~isfinite(P_usada) || abs(P_usada - P_raw) < eps(max(abs(P_raw),1))
              P_usada = val;
          end
      elseif isstruct(a)
          if es_detalle_intake(a)
              detalle = merge_struct_guard(detalle, a);
          else
              param = merge_struct_guard(param, a);
          end
      end
  end

  % Si la llamada fue guard(sistema,Ql,param), calcular intake crudo.
  if ~isfinite(P_raw) && isstruct(param) && ~isempty(fieldnames(param))
      try
          [Pcalc, detcalc] = calcular_columna_succion(Ql, param);
          P_usada = Pcalc;
          if isstruct(detcalc)
              detalle = merge_struct_guard(detalle, detcalc);
              if isfield(detcalc, 'P_s_raw') && isnumeric(detcalc.P_s_raw) && isfinite(detcalc.P_s_raw(1))
                  P_raw = detcalc.P_s_raw(1);
              else
                  P_raw = Pcalc;
              end
          else
              P_raw = Pcalc;
          end
      catch err_calc
          detalle.error_intake_guard = err_calc.message;
      end
  end

  % El detalle crudo siempre tiene prioridad si existe.
  if isstruct(detalle)
      if isfield(detalle, 'P_s_raw') && isnumeric(detalle.P_s_raw) && isfinite(detalle.P_s_raw(1))
          P_raw = detalle.P_s_raw(1);
      end
      if isfield(detalle, 'P_s_usada') && isnumeric(detalle.P_s_usada) && isfinite(detalle.P_s_usada(1))
          P_usada = detalle.P_s_usada(1);
      end
  end
  if ~isfinite(P_usada), P_usada = P_raw; end

  P_min = leer_num_guard(param, {'P_intake_min','P_succion_min'}, 1e5);

  guard = struct();
  guard.sistema = sistema;
  guard.Ql = Ql;
  guard.P_intake_raw = P_raw;
  guard.P_intake_usada = P_usada;
  guard.P_intake_bar = P_raw / 1e5;
  guard.P_intake_min = P_min;
  guard.estado = 'OK';
  guard.color = 'VERDE';
  guard.nivel = 'VERDE';
  guard.severidad = 'VERDE';
  guard.mensaje = sprintf('[VERDE] INTAKE / RESERVORIO (%s): P_intake %.2f bar dentro del rango operativo.', sistema, P_raw/1e5);
  guard.detalle = detalle;

  if ~isfinite(P_raw) || isnan(P_raw)
      guard.estado = 'NO_FISICO';
      guard.color = 'ROJO';
      guard.nivel = 'ROJO';
      guard.severidad = 'ROJO';
      guard.mensaje = sprintf('[ROJO] INTAKE / RESERVORIO (%s): presion de intake no finita. Revisar IPR, VLP, survey, PVT y datos de entrada.', sistema);
  elseif P_raw < 0
      guard.estado = 'NO_FISICO';
      guard.color = 'ROJO';
      guard.nivel = 'ROJO';
      guard.severidad = 'ROJO';
      guard.mensaje = sprintf(['[ROJO] INTAKE / RESERVORIO (%s): el reservorio no puede sostener ese nivel de intake para el SLA. ' ...
                         'P_intake calculada = %.2f bar. Resultado no factible sin recalibrar IPR/P_res/profundidad o condicion operativa.'], ...
                         sistema, P_raw/1e5);
  elseif P_raw < P_min
      guard.estado = 'LIMITADO_POR_RESERVORIO';
      guard.color = 'ROJO';
      guard.nivel = 'ROJO';
      guard.severidad = 'ROJO';
      guard.mensaje = sprintf(['[ROJO] INTAKE / RESERVORIO (%s): el reservorio no puede sostener ese nivel de intake para el SLA evaluado. ' ...
                         'P_intake calculada = %.2f bar, minimo operativo = %.2f bar. ' ...
                         'Revisar IPR, P_res, profundidad efectiva, VLP o condiciones del sistema.'], ...
                         sistema, P_raw/1e5, P_min/1e5);
  elseif isstruct(param) && isfield(param, 'P_res') && isnumeric(param.P_res) && ~isempty(param.P_res) && isfinite(param.P_res(1)) && P_raw > param.P_res(1)*1.001
      guard.estado = 'FUERA_DE_RANGO_IPR';
      guard.color = 'AMARILLO';
      guard.nivel = 'AMARILLO';
      guard.severidad = 'AMARILLO';
      guard.mensaje = sprintf('[AMARILLO] INTAKE / RESERVORIO (%s): P_intake %.2f bar mayor que P_res %.2f bar. Revisar IPR o signo de columnas.', sistema, P_raw/1e5, param.P_res(1)/1e5);
  end

  guard.detalle.estado = guard.estado;
  guard.detalle.mensaje = guard.mensaje;

  if nargout <= 1
      varargout{1} = guard;
  elseif nargout == 2
      varargout{1} = guard.estado;
      varargout{2} = guard.mensaje;
  else
      varargout{1} = guard.estado;
      varargout{2} = guard.mensaje;
      varargout{3} = guard.detalle;
  end
end

function tf = es_detalle_intake(s)
  tf = false;
  if ~isstruct(s), return; end
  claves = {'P_s_raw','P_s_usada','P_wf','delta_P_succion','H_l','rho_mezcla','estado','mensaje'};
  for k = 1:length(claves)
      if isfield(s, claves{k})
          tf = true;
          return;
      end
  end
end

function out = merge_struct_guard(a, b)
  out = a;
  if ~isstruct(out), out = struct(); end
  if ~isstruct(b), return; end
  f = fieldnames(b);
  for k = 1:length(f)
      out.(f{k}) = b.(f{k});
  end
end

function v = leer_num_guard(s, nombres, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  for k = 1:length(nombres)
      nombre = nombres{k};
      if isfield(s, nombre)
          tmp = s.(nombre);
          if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
              v = tmp(1);
              return;
          elseif ischar(tmp)
              val = str2double(strtrim(tmp));
              if isfinite(val)
                  v = val;
                  return;
              end
          end
      end
  end
end
