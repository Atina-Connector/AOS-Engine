function e = jgl_eductor_estado_aplicado(p, Ql, Qiny, Ps, deltaP_aplicado, origen)
% JGL_EDUCTOR_ESTADO_APLICADO Cierra energia y presiones para el dP usado.
% El solver puede relajar DeltaP o usar una estimacion de una pasada. Esta
% rutina reconstruye un unico estado coherente para reporte, grafico y audit.
% GNU Octave es el entorno objetivo.

  if nargin < 6 || isempty(origen), origen = 'SOLVER'; end
  if nargin < 5 || isempty(deltaP_aplicado), deltaP_aplicado = 0; end
  Ql = max(Ql, 0);
  Qiny = max(Qiny, 0);
  Ps = max(Ps, 0);

  raw = jgl_eductor_comun(p, max(Ql,1e-12), Qiny, Ps);
  e = raw;
  if ~isfield(e,'detalle') || ~isstruct(e.detalle), e.detalle = struct(); end

  limite_energia = raw.pot_disp / max(Ql, 1e-12);
  if ~isfinite(limite_energia) || limite_energia < 0, limite_energia = 0; end
  dp = min(max(deltaP_aplicado, 0), limite_energia);

  e.Ps = Ps;
  e.Pd = Ps + dp;
  e.deltaP = dp;
  e.pot_trans = dp * Ql;
  e.eta = e.pot_trans / max(e.pot_disp, 1e-12);
  e.detalle.deltaP_modelo_crudo = raw.deltaP;
  e.detalle.deltaP_aplicado = dp;
  e.detalle.origen_estado_aplicado = origen;
  e.detalle.limite_deltaP_energia = limite_energia;

  if Qiny <= 1e-12
    e.estado = 'SIN_GAS_MOTRIZ';
  elseif isfield(e,'condicion_motriz') && isstruct(e.condicion_motriz) && ...
      isfield(e.condicion_motriz,'bloquea_operacion') && e.condicion_motriz.bloquea_operacion
    e.estado = e.condicion_motriz.estado;
  elseif ~isfinite(e.Pm) || e.Pm <= Ps
    e.estado = 'SIN_PRESION_MOTRIZ';
  elseif Ql <= 1e-12
    e.estado = 'LIMITADO_POR_RESERVORIO';
  elseif dp <= 1e-9
    e.estado = 'SIN_TRABAJO_TRANSFERIDO';
  elseif e.pot_trans > e.pot_disp * (1 + 1e-8)
    e.estado = 'RESULTADO_NO_FISICO';
  else
    e.estado = 'OK';
  end
end
