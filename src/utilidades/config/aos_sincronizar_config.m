function p = aos_sincronizar_config(p, modulo)
% Sincroniza una configuracion activa sin permitir que aliases del .aosdat
% sobrescriban valores editados durante la sesion. GNU Octave objetivo.

  if nargin < 1 || ~isstruct(p), p = struct(); end
  if nargin < 2 || isempty(modulo), modulo = 'GENERAL'; end

  % Capturar siempre los canonicos presentes. Si la estructura aun no estaba
  % marcada como normalizada, esta llamada representa un estado runtime y no
  % una importacion cruda.
  snap = aos_capturar_canonicos_runtime(p);
  p.aos_config_normalizada = true;

  p = aos_normalizar_config(p, modulo);
  p = aos_restaurar_canonicos_runtime(p, snap);

  % Reaplicar profundidad segun el SLA, sin cruzar D_iny con D_bomba.
  m = upper(strtrim(modulo));
  if any(strcmp(m, {'GL','JGL','SENS_GL','SENS_JGL','SENSIBILIDAD_GL','SENSIBILIDAD_JGL'}))
    if es_numero(p,'D_iny'), p = aos_set_profundidad(p, m, p.D_iny); end
  elseif any(strcmp(m, {'BES','BM'}))
    if es_numero(p,'D_bomba'), p = aos_set_profundidad(p, m, p.D_bomba); end
  end

  % La politica de Qiny tambien es canonica. El modo fijo conserva cualquier
  % valor, incluido cero; el automatico elimina todos los aliases runtime que
  % pudieran reactivar el valor importado del .aosdat.
  if isfield(p,'qiny_modo') && ischar(p.qiny_modo)
    modo_q = lower(strtrim(p.qiny_modo));
    if strcmp(modo_q,'fijo') && es_numero(p,'Q_iny')
      p = aos_set_qiny(p, p.Q_iny*86400, 'fijo');
    elseif strcmp(modo_q,'automatico')
      p = aos_set_qiny(p, 0, 'automatico');
    end
  end

  p = aos_sincronizar_aliases_canonicos(p);
  p.aos_config_normalizada = true;
  p.aos_config_normalizada_modulo = modulo;
end

function tf = es_numero(s,c)
  tf = isstruct(s) && isfield(s,c) && isnumeric(s.(c)) && ...
       isscalar(s.(c)) && isfinite(s.(c));
end
