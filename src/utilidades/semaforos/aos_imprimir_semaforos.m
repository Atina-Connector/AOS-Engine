function aos_imprimir_semaforos(sem, titulo)
  if nargin < 2 || isempty(titulo)
      if isstruct(sem) && isfield(sem, 'sistema'), titulo = sem.sistema; else titulo = 'AOS'; end
  end
  if nargin < 1 || ~isstruct(sem)
      fprintf('\n--- SEMAFOROS OPERATIVOS (%s) ---\nNo disponibles.\n', titulo); return;
  end
  sistema = leer_txt(sem, 'sistema', titulo);
  fprintf('\n--- SEMAFOROS OPERATIVOS AOS (%s) ---\n', sistema);
  fprintf('%s [%s] GENERAL - %s\n', aos_spot_texto(leer_txt(sem,'general','S/D')), leer_txt(sem,'general','S/D'), leer_txt(sem,'descripcion',''));
  if isfield(sem, 'items')
      for i = 1:length(sem.items)
          it = sem.items(i);
          fprintf('  %s [%s] %-20s %s\n', aos_spot_texto(leer_txt(it,'estado','S/D')), leer_txt(it,'estado','S/D'), leer_txt(it,'nombre',sprintf('ITEM %d',i)), leer_txt(it,'mensaje',''));
      end
  end
  fprintf('---------------------------------------\n');
end
function s = leer_txt(x, campo, defecto)
  s = defecto;
  if isstruct(x) && isfield(x, campo)
      [y, ok] = aos_texto_seguro(x.(campo), defecto);
      if ok && ~isempty(y), s = y; endif
  endif
endfunction
