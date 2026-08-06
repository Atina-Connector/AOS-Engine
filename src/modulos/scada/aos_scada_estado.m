function aos_scada_estado()
  r=aos_scada_rutas();
  entrada=dir(fullfile(r.entrada,'*.aosdat'));
  procesados=dir(fullfile(r.procesados,'*.aosdat'));
  rechazados=dir(fullfile(r.rechazados,'*.aosdat'));
  salida=dir(fullfile(r.salida,'*'));
  salida=salida(~[salida.isdir]);
  fprintf('\n--- ESTADO SCADA ---\n');
  fprintf('Bandeja entrada : %s (%d paquetes)\n',r.entrada,numel(entrada));
  fprintf('Procesados      : %s (%d paquetes)\n',r.procesados,numel(procesados));
  fprintf('Rechazados      : %s (%d paquetes)\n',r.rechazados,numel(rechazados));
  fprintf('Salida servidor : %s (%d archivos)\n',r.salida,numel(salida));
endfunction
