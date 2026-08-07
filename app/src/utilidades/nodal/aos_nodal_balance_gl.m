function [residuo, detalle] = aos_nodal_balance_gl(Ql, param, Qiny, D_iny)
% aos_nodal_balance_gl.m
% Balance único GL para solver y gráfico:
%   residuo = P_succion_disponible - P_VLP_requerida
% AOS 0.0.11f: evita caminos diferentes entre el buscador y el plot.
  if nargin < 1 || isempty(Ql), Ql = 0; end
  if nargin < 2 || ~isstruct(param), param = struct(); end
  if nargin < 3 || isempty(Qiny)
      if isfield(param, 'Q_iny'), Qiny = param.Q_iny; else, Qiny = 0; end
  end
  if nargin < 4 || isempty(D_iny) || ~isfinite(D_iny)
      D_iny = aos_profundidad_inyeccion(param, getnum_nb(param,'D_bomba', getnum_nb(param,'D_res',0)));
  end
  Ql = max(Ql, 0);
  Qiny = max(Qiny, 0);

  p = param;
  p.Q_iny = Qiny;
  try
      p = aos_set_profundidad(p, 'GL', D_iny);
  catch
      p.D_iny = D_iny;
      p.D_iny_m = D_iny;
      p.D_levantamiento = D_iny;
  end
  GLR = getnum_nb(p, 'GLR', 0);
  Qg_total_std = Qiny + Ql * GLR;

  [P_s, det_s] = calcular_columna_succion(Ql, p);
  [P_req, det_vlp] = compute_P_req(p, Ql, Qg_total_std, D_iny);
  residuo = P_s - P_req;

  detalle = struct();
  detalle.Ql = Ql;
  detalle.Qiny = Qiny;
  detalle.Qg_inyectado_std = Qiny;
  detalle.Qg_formacion_std = Ql * GLR;
  detalle.Qg_total_std = Qg_total_std;
  detalle.GLR_usado = GLR;
  if isfield(p, 'qiny_modo') && ischar(p.qiny_modo)
    detalle.qiny_modo = p.qiny_modo;
  else
    detalle.qiny_modo = 'argumento_explicito';
  end
  detalle.P_s = P_s;
  detalle.P_req = P_req;
  detalle.residuo = residuo;
  detalle.D_iny = D_iny;
  detalle.succion = det_s;
  detalle.vlp = det_vlp;
end

function v = getnum_nb(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      x = s.(campo);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
          v = x(1); return;
      elseif ischar(x)
          y = str2double(x);
          if isfinite(y), v = y; return; end
      end
  end
end
