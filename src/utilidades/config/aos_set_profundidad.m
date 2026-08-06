function cfg = aos_set_profundidad(cfg, modulo, valor_m)
% AOS_SET_PROFUNDIDAD Actualiza una profundidad operativa sin dejar aliases viejos.
%
% AOS 0.0.11c. Evita que una edicion de menu sea revertida al volver a
% normalizar la configuracion. Cada familia de SLA mantiene su significado:
%   GL/JGL : profundidad de inyeccion/levantamiento/valvula/eductor.
%   BES/BM : profundidad de bomba/intake.
%
% El valor se expresa siempre en metros.

  if nargin < 1 || ~isstruct(cfg), cfg = struct(); end
  if nargin < 2 || isempty(modulo), modulo = 'GENERAL'; end
  if nargin < 3 || ~isnumeric(valor_m) || ~isscalar(valor_m) || ~isfinite(valor_m) || valor_m < 0
      error('La profundidad debe ser un numero finito mayor o igual que cero, en metros.');
  end

  m = upper(strtrim(modulo));

  if any(strcmp(m, {'GL','JGL','SENS_GL','SENS_JGL','SENSIBILIDAD_GL','SENSIBILIDAD_JGL'}))
      % Canonicos de GL/JGL.
      cfg.D_iny = valor_m;
      cfg.D_iny_m = valor_m;
      cfg.D_levantamiento = valor_m;
      cfg.D_levantamiento_m = valor_m;
      cfg.D_valvula = valor_m;
      cfg.D_valvula_m = valor_m;
      cfg.D_eductor = valor_m;
      cfg.D_eductor_m = valor_m;

      if ~isfield(cfg, 'gl') || ~isstruct(cfg.gl), cfg.gl = struct(); end
      cfg.gl.D_iny = valor_m;
      cfg.gl.D_iny_m = valor_m;
      cfg.gl.D_valvula = valor_m;
      cfg.gl.D_valvula_m = valor_m;

      if ~isfield(cfg, 'jgl') || ~isstruct(cfg.jgl), cfg.jgl = struct(); end
      cfg.jgl.D_iny = valor_m;
      cfg.jgl.D_iny_m = valor_m;
      cfg.jgl.D_eductor = valor_m;
      cfg.jgl.D_eductor_m = valor_m;

      if ~isfield(cfg, 'pozo') || ~isstruct(cfg.pozo), cfg.pozo = struct(); end
      cfg.pozo.D_iny = valor_m;
      cfg.pozo.D_iny_m = valor_m;

      if isfield(cfg, 'estado_mecanico') && isstruct(cfg.estado_mecanico)
          cfg.estado_mecanico.prof_inyeccion_activa_m = valor_m;
      end

  elseif any(strcmp(m, {'BES','BM'}))
      cfg.D_bomba = valor_m;
      cfg.D_bomba_m = valor_m;
      if strcmp(m, 'BES')
          cfg.D_intake = valor_m;
          cfg.D_intake_m = valor_m;
          if ~isfield(cfg, 'bes') || ~isstruct(cfg.bes), cfg.bes = struct(); end
          cfg.bes.D_bomba = valor_m;
          cfg.bes.D_bomba_m = valor_m;
          cfg.bes.D_intake = valor_m;
          cfg.bes.D_intake_m = valor_m;
      else
          if ~isfield(cfg, 'bm') || ~isstruct(cfg.bm), cfg.bm = struct(); end
          cfg.bm.D_bomba = valor_m;
          cfg.bm.D_bomba_m = valor_m;
      end
  else
      % En modo GENERAL no adivinar el SLA ni contaminar profundidades.
      cfg.D_operativa = valor_m;
      cfg.D_operativa_m = valor_m;
  end

  cfg.aos_profundidad_editada = true;
  cfg.aos_profundidad_editada_modulo = m;
  cfg.aos_profundidad_editada_m = valor_m;
end
