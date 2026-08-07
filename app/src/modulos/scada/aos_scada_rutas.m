function rutas = aos_scada_rutas()
  root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
  base=fullfile(root,'intercambio','scada');
  rutas=struct('base',base,'entrada',fullfile(base,'entrada'), ...
               'procesados',fullfile(base,'procesados'), ...
               'rechazados',fullfile(base,'rechazados'), ...
               'salida',fullfile(base,'salida'), ...
               'logs',fullfile(base,'logs'));
  f=fieldnames(rutas);
  for i=1:numel(f)
    p=rutas.(f{i});
    if exist(p,'dir')~=7,mkdir(p);endif
  endfor
endfunction
