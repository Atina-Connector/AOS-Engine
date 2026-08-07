function ok = test_sens_gljgl01_contrato_estatico()
% TEST_SENS_GLJGL01_CONTRATO_ESTATICO Verifica el contrato del hotfix.
  ok = false;
  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));

  requeridos = { ...
    'src/sensibilidad/sens_gl_evaluar_punto.m', ...
    'src/sensibilidad/sens_jgl_evaluar_punto.m', ...
    'src/sensibilidad/sens_validar_base_gl_jgl.m', ...
    'src/sensibilidad/sens_validar_punto_gl.m', ...
    'src/sensibilidad/sens_validar_punto_jgl.m', ...
    'src/sensibilidad/sens_firma_config_gl_jgl.m'};
  for i = 1:numel(requeridos)
    assert(exist(fullfile(raiz, requeridos{i}), 'file') == 2);
  endfor

  prep = fileread(fullfile(raiz, 'src', 'sensibilidad', 'sens_preparar_base.m'));
  assert(~isempty(strfind(prep, 'base.modelo_IPR = ''linear''')));
  assert(isempty(strfind(prep, 'base.modelo_IPR = ''Vogel''')));

  carga = fileread(fullfile(raiz, 'src', 'sensibilidad', 'sens_cargar_base.m'));
  assert(~isempty(strfind(carga, 'strcmp(contexto, ''SENS_GL'')')));
  assert(~isempty(strfind(carga, 'strcmp(tipo_u, ''GL'')')));
  assert(~isempty(strfind(carga, 'strcmp(contexto, ''SENS_JGL'')')));
  assert(~isempty(strfind(carga, 'strcmp(tipo_u, ''JGL'')')));
  assert(~isempty(strfind(carga, 'nunca queda como opcion por defecto')));

  menu = fileread(fullfile(raiz, 'src', 'sensibilidad', 'sens_menu_modo_general.m'));
  assert(~isempty(strfind(menu, 'defecto = ''preciso''')));
  assert(~isempty(strfind(menu, 'RESULTADO FINAL')));
  assert(~isempty(strfind(menu, 'PRELIMINAR, SIN OPTIMO')));

  malla = fileread(fullfile(raiz, 'src', 'sensibilidad', 'sens_jgl_gl_malla.m'));
  assert(isempty(strfind(malla, 'estado_gl{i} = ''OK''')));
  assert(~isempty(strfind(malla, 'estado_gl{i} = E.estado')));
  assert(~isempty(strfind(malla, 'sens_gl_evaluar_punto')));

  jgl = fileread(fullfile(raiz, 'src', 'core', 'JGL', 'jgl_sensibilidad_parametrica.m'));
  assert(isempty(strfind(jgl, 'jgl_sensibilidad_hibrida')));
  assert(~isempty(strfind(jgl, 'sens_jgl_evaluar_punto')));
  assert(~isempty(strfind(jgl, 'SENS-GLJGL-01_METODO_UNIFORME')));
  assert(~isempty(strfind(jgl, 'R.valido_para_optimo')));

  exp = fileread(fullfile(raiz, 'src', 'sensibilidad', 'sens_exportar_resultados.m'));
  assert(~isempty(strfind(exp, 'Ql_JGL_raw_m3d')));
  assert(~isempty(strfind(exp, 'Ql_GL_raw_m3d')));
  assert(~isempty(strfind(exp, 'valido_para_curva')));
  assert(~isempty(strfind(exp, 'valido_para_optimo')));
  assert(~isempty(strfind(exp, 'Motivo_rechazo')));

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl01_contrato_estatico APROBADO\n');
endfunction
