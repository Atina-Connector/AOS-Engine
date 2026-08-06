function BM_menu()
% BM_menu - Despachador modular de Bombeo Mecanico.
% AOS 0.1.3R1.1 - Release limpia consolidada.

  script_dir = fileparts(mfilename('fullpath'));
  AOS_root = fileparts(fileparts(script_dir));
  addpath(fullfile(AOS_root, 'src'), '-begin');
  addpath(script_dir, '-begin');
  iniciar_aos;

  while true
    modulos = bm_registro_modulos();
    fprintf('\n====================================================\n');
    fprintf(' AOS 0.1.2 - BOMBEO MECANICO\n');
    fprintf('====================================================\n');
    for k = 1:numel(modulos)
      disponible = existe_funcion(modulos(k).funcion);
      marca = estado_visible(modulos(k).estado, disponible);
      fprintf(' %d - %s [%s]\n', k, modulos(k).nombre, marca);
    end
    fprintf(' 0 - Volver\n');

    op = input('Seleccione una opcion: ');
    if isempty(op), op = 1; end
    if ~isnumeric(op) || ~isscalar(op) || ~isfinite(op)
      fprintf('Opcion no valida.\n');
      continue;
    end
    op = round(op);
    if op == 0, return; end
    if op < 1 || op > numel(modulos)
      fprintf('Opcion no valida.\n');
      continue;
    end

    m = modulos(op);
    if ~existe_funcion(m.funcion)
      fprintf('\nModulo no disponible: %s\n', m.nombre);
      fprintf('Estado declarado: %s\n', m.estado);
      continue;
    end

    fprintf('\nModulo : %s\n', m.nombre);
    fprintf('Estado : %s\n', m.estado);
    fprintf('Version: %s\n', m.version);
    try
      feval(m.funcion);
    catch err
      fprintf(2, '\nERROR EN MODULO BM [%s]: %s\n', m.id, err.message);
      if exist('getReport', 'file') == 2
        fprintf(2, '%s\n', getReport(err));
      end
    end
  end
end

function tf = existe_funcion(fh)
  nombre = func2str(fh);
  tf = exist(nombre, 'file') == 2 || exist(nombre, 'builtin') == 5;
end

function txt = estado_visible(estado, disponible)
  if ~disponible
    txt = 'NO DISPONIBLE';
  else
    txt = estado;
  end
end
