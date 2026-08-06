function ok = aos_preparar_config_activa(modulo)
% Normaliza CONFIG_ACTIVA y sincroniza geologia/punzados antes de un modulo.
  if nargin < 1 || isempty(modulo), modulo = 'GENERAL'; end
  ok = true;
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA), return; end
  if ~isstruct(CONFIG_ACTIVA)
      fprintf('ADVERTENCIA AOS: CONFIG_ACTIVA no es estructura. Se descarta.\n');
      CONFIG_ACTIVA = [];
      ok = false;
      return;
  end
  try
      CONFIG_ACTIVA = aos_normalizar_config(CONFIG_ACTIVA, modulo);
      aos_sincronizar_geologia_activa();
      ok = aos_validar_config_modulo(CONFIG_ACTIVA, modulo, true);
  catch err
      fprintf('ADVERTENCIA AOS: no se pudo preparar configuracion para %s: %s\n', modulo, err.message);
      ok = false;
  end
end
