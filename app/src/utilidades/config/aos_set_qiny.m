function p = aos_set_qiny(p, q_sm3d, modo)
% AOS_SET_QINY Define Qiny con prioridad explicita del usuario.
% GNU Octave es el entorno objetivo.
%
% modo = 'fijo'
%   q_sm3d es el valor exacto ingresado por el usuario en Sm3/d.
%   Se admite cualquier valor >= 0, incluido cero.
%   El valor se propaga a todos los aliases y estructuras internas.
%
% modo = 'automatico'
%   Elimina la imposicion de caudal fijo. Los valores del .aosdat quedan
%   solo como referencia y el motor calcula Qiny.

  if nargin < 1 || ~isstruct(p), p = struct(); end
  if nargin < 3 || isempty(modo), modo = 'fijo'; end
  modo = lower(strtrim(modo));

  if ~isfield(p, 'gl') || ~isstruct(p.gl), p.gl = struct(); end
  if ~isfield(p, 'jgl') || ~isstruct(p.jgl), p.jgl = struct(); end

  if strcmp(modo, 'automatico')
    p.qiny_modo = 'automatico';
    p.gl.qiny_modo = 'automatico';
    p.jgl.qiny_modo = 'automatico';

    % Retirar solamente los campos que imponen el caudal en el runtime.
    p = quitar_campos(p, {'Q_iny','Qiny','Qiny_plot','Qiny_sim_Sm3_d', ...
                          'Qiny_Sm3_d','Q_iny_Sm3_d','Qiny_sim_MMscfd', ...
                          'Qiny_MMscfd','Q_iny_MMscfd'});
    p.gl = quitar_campos(p.gl, {'Q_iny','Qiny','Qiny_Sm3_d','Q_iny_Sm3_d', ...
                                'Qiny_MMscfd','Q_iny_MMscfd'});
    p.jgl = quitar_campos(p.jgl, {'Q_iny','Qiny','Qiny_Sm3_d','Q_iny_Sm3_d', ...
                                  'Qiny_MMscfd','Q_iny_MMscfd'});
    return;
  end

  if isempty(q_sm3d) || ~isnumeric(q_sm3d) || ~isscalar(q_sm3d) || ~isfinite(q_sm3d)
    error('Qiny fijo debe ser un numero escalar finito expresado en Sm3/d.');
  end
  if q_sm3d < 0
    error('Qiny fijo no puede ser negativo. Valor ingresado: %.6g Sm3/d.', q_sm3d);
  end

  % Sm3/d -> m3/s estandar. No aplicar conversion scf->m3: la entrada ya
  % esta expresada en metros cubicos estandar por dia.
  q_m3s = q_sm3d / 86400;
  q_mmscfd = q_sm3d / 0.028316846592 / 1e6;

  p.qiny_modo = 'fijo';
  p.Q_iny = q_m3s;
  p.Qiny = q_m3s;
  p.Qiny_plot = q_m3s;
  p.Qiny_sim_Sm3_d = q_sm3d;
  p.Qiny_Sm3_d = q_sm3d;
  p.Q_iny_Sm3_d = q_sm3d;
  p.Qiny_sim_MMscfd = q_mmscfd;
  p.Qiny_MMscfd = q_mmscfd;
  p.Q_iny_MMscfd = q_mmscfd;

  p.gl.qiny_modo = 'fijo';
  p.gl.Q_iny = q_m3s;
  p.gl.Qiny = q_m3s;
  p.gl.Qiny_Sm3_d = q_sm3d;
  p.gl.Q_iny_Sm3_d = q_sm3d;
  p.gl.Qiny_MMscfd = q_mmscfd;
  p.gl.Q_iny_MMscfd = q_mmscfd;

  p.jgl.qiny_modo = 'fijo';
  p.jgl.Q_iny = q_m3s;
  p.jgl.Qiny = q_m3s;
  p.jgl.Qiny_Sm3_d = q_sm3d;
  p.jgl.Q_iny_Sm3_d = q_sm3d;
  p.jgl.Qiny_MMscfd = q_mmscfd;
  p.jgl.Q_iny_MMscfd = q_mmscfd;
end

function s = quitar_campos(s, campos)
  if ~isstruct(s), s = struct(); return; end
  for i = 1:length(campos)
    if isfield(s, campos{i}), s = rmfield(s, campos{i}); end
  end
end
