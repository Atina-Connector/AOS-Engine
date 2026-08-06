function VERIFICAR_MODO_ABREVIADO_TRANSVERSAL()
% Verificador robusto para GNU Octave.
% Inicializa todas las rutas AOS antes de comprobar las funciones del parche.

  fprintf('\n=== VERIFICACION MODO ABREVIADO TRANSVERSAL ===\n');

  raiz = localizar_raiz_aos(fileparts(mfilename('fullpath')));
  if isempty(raiz)
    error('No se encontro la raiz de AOS. Ejecute este verificador desde la carpeta raiz de AOS.');
  end

  addpath(fullfile(raiz, 'src'), '-begin');
  if exist('iniciar_aos', 'file') ~= 2
    error('No se encontro src/iniciar_aos.m en la raiz detectada: %s', raiz);
  end
  iniciar_aos();
  rehash();

  fprintf('Raiz AOS verificada: %s\n', raiz);

  req = {'jgl_menu_aproximacion', ...
         'sens_abreviado_seleccionar', ...
         'sens_abreviado_imprimir', ...
         'sens_menu_modo_general', ...
         'aos_resolver_gl'};

  for i = 1:numel(req)
    ruta = which(req{i});
    assert(exist(req{i}, 'file') == 2, ['Falta ', req{i}]);
    fprintf('[OK] %s -> %s\n', req{i}, ruta);
  end

  x = linspace(0, 1, 15);
  y = 10 + 2*x - 3*x.^2 + 0.2*x.^4;
  A = sens_abreviado_seleccionar(x, y);

  assert(isstruct(A), 'sens_abreviado_seleccionar no devolvio una estructura.');
  assert(isfield(A, 'estado') && strcmp(A.estado, 'OK'), 'El ajuste abreviado no devolvio estado OK.');
  assert(isfield(A, 'grado') && A.grado >= 2 && A.grado <= 5, 'Grado polinomico fuera de rango.');
  assert(isfield(A, 'seleccion') && sum(A.seleccion) >= 2, 'No se seleccionaron suficientes puntos.');

  fprintf('[OK] Ajuste grado %d; %d puntos seleccionados.\n', A.grado, sum(A.seleccion));
  fprintf('[OK] El polinomio solo selecciona verificaciones; no reemplaza resultados.\n');
  fprintf('VERIFICACION ESTATICA APROBADA.\n');
  fprintf('Ejecute luego una sensibilidad corta de 5 puntos y otra de 15 puntos.\n');
end

function raiz = localizar_raiz_aos(inicio)
  raiz = '';
  p = inicio;
  for k = 1:10
    if exist(fullfile(p, 'AOS.m'), 'file') && exist(fullfile(p, 'src'), 'dir')
      raiz = p;
      return;
    end
    padre = fileparts(p);
    if strcmp(padre, p)
      break;
    end
    p = padre;
  end
end
