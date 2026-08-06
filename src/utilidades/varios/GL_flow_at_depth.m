function [Qtotal_std, Ql, Qo, detalle] = GL_flow_at_depth(D_valvula, param_base, survey, Qiny)
% GL_FLOW_AT_DEPTH Evalua GL a una profundidad usando el solver comun AOS.
% GNU Octave es el entorno objetivo.
%
% D_valvula : profundidad MD de inyeccion [m]
% param_base: configuracion activa
% survey    : survey opcional
% Qiny      : caudal fijo opcional [m3/s estandar]. Si se omite, respeta la
%             politica Qiny activa; en modo automatico lo calcula.
%
% Esta funcion no contiene caudales ni GOR hardcodeados y no modifica
% D_bomba. Toda la hidraulica pasa por aos_resolver_gl.

  if nargin < 2 || ~isstruct(param_base)
    error('GL_flow_at_depth requiere D_valvula y param_base.');
  end
  if nargin < 3, survey = []; end

  p = aos_sincronizar_config(param_base, 'GL');
  p = aos_set_profundidad(p, 'GL', D_valvula);
  if ~isempty(survey), p.survey = survey; end
  p = aos_sincronizar_config(p, 'GL');

  detalle = struct();
  detalle.D_iny_solicitada = D_valvula;
  detalle.D_iny_efectiva = p.D_iny;
  detalle.qiny_fuente = '';
  detalle.qiny_auto = struct();

  if nargin >= 4 && ~isempty(Qiny)
    if ~isnumeric(Qiny) || ~isscalar(Qiny) || ~isfinite(Qiny) || Qiny < 0
      error('Qiny debe ser un escalar finito >= 0 expresado en m3/s estandar.');
    end
    p = aos_set_qiny(p, Qiny * 86400, 'fijo');
    detalle.qiny_fuente = 'ARGUMENTO_EXPLICITO';
  else
    [Qcfg, fuente] = aos_qiny_configurada(p);
    if isempty(Qcfg)
      [Qcfg, det_auto] = aos_calcular_qiny_auto_gl(p, p.D_iny);
      p = aos_set_qiny(p, Qcfg * 86400, 'fijo');
      detalle.qiny_fuente = 'AUTOMATICO';
      detalle.qiny_auto = det_auto;
    else
      p = aos_set_qiny(p, Qcfg * 86400, 'fijo');
      detalle.qiny_fuente = fuente;
    end
  end

  Qiny_eff = p.Q_iny;
  [Ql, det_solver] = aos_resolver_gl(p, Qiny_eff);
  WC = getnum_gl_depth(p, 'WC', 0.5);
  GLR = getnum_gl_depth(p, 'GLR', 0);
  Qo = max(Ql, 0) * (1 - min(max(WC,0),1));
  Qtotal_std = Qiny_eff + max(Ql,0) * max(GLR,0);

  detalle.Qiny_solicitado = Qiny_eff;
  detalle.Qiny_efectivo = Qiny_eff;
  detalle.Qg_formacion_std = max(Ql,0) * max(GLR,0);
  detalle.Qg_total_std = Qtotal_std;
  detalle.solver = det_solver;
end

function v = getnum_gl_depth(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s,campo)
    x = s.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1); end
  end
end
