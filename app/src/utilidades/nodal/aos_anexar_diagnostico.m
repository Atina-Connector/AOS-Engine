function texto = aos_anexar_diagnostico(texto, nuevo)
% Anexa mensajes de diagnostico conservando compatibilidad Octave.
  if nargin < 1 || isempty(texto), texto = ''; end
  if nargin < 2 || isempty(nuevo), return; end
  if isstruct(nuevo) && isfield(nuevo, 'mensaje')
      nuevo = nuevo.mensaje;
  end
  if ~ischar(nuevo), return; end
  if isempty(strtrim(texto))
      texto = nuevo;
  else
      texto = sprintf('%s\n%s', texto, nuevo);
  end
end
