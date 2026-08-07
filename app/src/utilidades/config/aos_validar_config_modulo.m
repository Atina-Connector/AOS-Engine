function ok = aos_validar_config_modulo(cfg, modulo, silencioso)
% aos_validar_config_modulo.m - Validacion liviana antes de ejecutar modulos.
% No reemplaza validacion fisica. Solo detecta faltantes graves y evita caidas.

  if nargin < 3, silencioso = false; end
  if nargin < 2 || isempty(modulo), modulo = 'GENERAL'; end
  ok = true;

  if ~isstruct(cfg)
      ok = false;
      if ~silencioso, fprintf('ERROR AOS: la configuracion no es una estructura valida.\n'); end
      return;
  end

  comunes = {'P_res','IP','WC','P_wh','D_bomba','D_res'};
  faltan = {};
  for i = 1:length(comunes)
      c = comunes{i};
      if ~isfield(cfg, c) || isempty(cfg.(c))
          faltan{end+1} = c;
      end
  end

  grupos = {'pozo','tubing','fluidos'};
  for i = 1:length(grupos)
      g = grupos{i};
      if isfield(cfg, g) && ~isempty(cfg.(g)) && ~isstruct(cfg.(g))
          ok = false;
          if ~silencioso
              fprintf('ERROR AOS: el campo %s existe pero no es estructura. Normalice la configuracion.\n', g);
          end
      end
  end

  if ~isempty(faltan)
      ok = false;
      if ~silencioso
          fprintf('ADVERTENCIA AOS: faltan campos requeridos para %s: ', modulo);
          for k = 1:length(faltan)
              fprintf('%s ', faltan{k});
          end
          fprintf('\n');
      end
  end
end
