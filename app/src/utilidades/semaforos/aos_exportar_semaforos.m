function aos_exportar_semaforos(fid, sem, nombre_seccion)
  if nargin < 1 || fid < 0 || nargin < 2 || ~isstruct(sem), return; end
  if nargin < 3 || isempty(nombre_seccion), nombre_seccion = 'SEMAFOROS'; end
  fprintf(fid, '\n[%s]\n', nombre_seccion);
  fprintf(fid, 'sistema=%s\n', leer_txt(sem, 'sistema', 'AOS'));
  fprintf(fid, 'formato=spot,[estado],item,mensaje\n');
  fprintf(fid, 'nota=El spot es textual para baja conectividad. El Viewer/App debe renderizar el color usando el estado entre corchetes.\n');
  fprintf(fid, 'general=%s [%s] GENERAL - %s\n', aos_spot_texto(leer_txt(sem,'general','S/D')), leer_txt(sem,'general','S/D'), limpiar(leer_txt(sem,'descripcion','')));
  if isfield(sem, 'items')
      for i=1:length(sem.items)
          it = sem.items(i);
          fprintf(fid, 'item_%02d=%s [%s] %s - %s\n', i, aos_spot_texto(leer_txt(it,'estado','S/D')), leer_txt(it,'estado','S/D'), limpiar(leer_txt(it,'nombre',sprintf('ITEM_%02d',i))), limpiar(leer_txt(it,'mensaje','')));
      end
  end
  if isfield(sem, 'modelo'), fprintf(fid, 'modelo=%s\n', limpiar(sem.modelo)); end
end
function out = limpiar(valor)
  [s, ok] = aos_texto_seguro(valor, '');
  if ~ok || isempty(s), out = ''; return; end
  out = strrep(s, sprintf('\n'), ' | ');
  out = strrep(out, sprintf('\r'), ' ');
  out = strrep(out, '|', '/');
endfunction

function v = leer_txt(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    [tmp, ok] = aos_texto_seguro(s.(campo), defecto);
    if ok && ~isempty(tmp), v = tmp; endif
  endif
endfunction
