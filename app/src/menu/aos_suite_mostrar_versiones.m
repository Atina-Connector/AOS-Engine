function aos_suite_mostrar_versiones()
% AOS_SUITE_MOSTRAR_VERSIONES Imprime bancos, versiones y servicios.
  lista = aos_suite_registro_productos();
  fprintf('\n%-12s %-22s %-21s %-22s %-8s\n', ...
    'ID', 'BANCO DE TRABAJO', 'VERSION', 'ESTADO', 'ENTRADA');
  fprintf('%s\n', repmat('-', 1, 94));
  for i = 1:numel(lista)
    if lista(i).disponible, disp_txt = 'OK'; else, disp_txt = 'FALTA'; endif
    fprintf('%-12s %-22s %-21s %-22s %-8s\n', lista(i).id, ...
      lista(i).nombre, lista(i).version, lista(i).estado, disp_txt);
  endfor
  fprintf('\n--- SERVICIOS TRANSVERSALES ---\n');
  servicios = aos_suite_registro_servicios();
  for i = 1:numel(servicios)
    fprintf('%-16s %-28s %-18s %s\n', servicios(i).id, servicios(i).nombre, ...
      servicios(i).estado, servicios(i).version);
  endfor
  fprintf('\nAOS 0.2.0 DEV1 inaugura el desarrollo distribuido con bancos, servicios y solvers versionados.\n');
endfunction
