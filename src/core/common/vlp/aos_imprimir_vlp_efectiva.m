function aos_imprimir_vlp_efectiva(param, etiqueta)
% Imprime auditoria corta del modelo VLP efectivo.
  if nargin < 2 || isempty(etiqueta), etiqueta = 'AOS'; end
  try
      info = aos_vlp_info(param);
      fprintf('\n--- VLP EFECTIVA AOS (%s) ---\n', etiqueta);
      fprintf('Modelo VLP seleccionado : %s\n', info.modelo_solicitado);
      fprintf('Modelo VLP efectivo     : %s\n', info.modelo_efectivo);
      fprintf('Funcion VLP usada       : %s\n', info.funcion);
      if info.fallback
          fprintf('Fallback VLP            : si');
          if isfield(info, 'motivo_fallback') && ~isempty(info.motivo_fallback)
              fprintf(' (%s)', info.motivo_fallback);
          end
          fprintf('\n');
      else
          fprintf('Fallback VLP            : no\n');
      end
      fprintf('--------------------------------\n');
  catch err
      fprintf('Advertencia: no se pudo auditar VLP efectiva: %s\n', err.message);
  end
end
