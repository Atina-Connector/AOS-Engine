function ok = test_sens_gljgl02_contrato_estatico()
% Verifica que la armonizacion sea explicita y separada del solver fisico.
  ok=false;
  raiz=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  req={ ...
    'src/sensibilidad/sens_menu_tratamiento_curva.m', ...
    'src/sensibilidad/sens_seleccionar_grado_polinomio.m', ...
    'src/sensibilidad/sens_ajuste_polinomico.m', ...
    'src/sensibilidad/sens_validar_ajuste_polinomico.m', ...
    'src/sensibilidad/sens_verificar_optimo_polinomico.m', ...
    'src/sensibilidad/sens_imprimir_diagnostico_polinomio.m'};
  for i=1:numel(req),assert(exist(fullfile(raiz,req{i}),'file')==2);endfor

  menu=fileread(fullfile(raiz,'src','sensibilidad','sens_menu_tratamiento_curva.m'));
  assert(~isempty(strfind(menu,'Discreto, sin armonizacion')));
  assert(~isempty(strfind(menu,'Armonizacion polinomica informativa')));
  assert(~isempty(strfind(menu,'Armonizacion polinomica con optimo verificado')));
  assert(~isempty(strfind(menu,'T.oculto = false')));

  grado=fileread(fullfile(raiz,'src','sensibilidad','sens_seleccionar_grado_polinomio.m'));
  assert(~isempty(strfind(grado,'5 - Quintico [HISTORICO AOS]')));

  opt=fileread(fullfile(raiz,'src','sensibilidad','sens_optimo_inyeccion.m'));
  assert(~isempty(strfind(opt,'sin tratamiento explicito, NO ejecuta polyfit')));
  assert(isempty(strfind(opt,'polyfit(')));
  assert(~isempty(strfind(opt,'if T.usar_polinomio')));
  assert(~isempty(strfind(opt,'sens_ajuste_polinomico')));
  assert(~isempty(strfind(opt,'valido_curva y valido_optimo')));
  helper=fileread(fullfile(raiz,'src','sensibilidad','sens_ajuste_polinomico.m'));
  assert(~isempty(strfind(helper,'polyfit(')));

  ver=fileread(fullfile(raiz,'src','sensibilidad','sens_verificar_optimo_polinomico.m'));
  assert(~isempty(strfind(ver,'sens_gl_evaluar_punto')));
  assert(~isempty(strfind(ver,'sens_jgl_evaluar_punto')));

  for f={'sens_Qiny_GL.m','sens_Qiny_JGL.m','sens_Qiny.m','sens_balance_energetico.m'}
    t=fileread(fullfile(raiz,'src','sensibilidad',f{1}));
    assert(~isempty(strfind(t,'sens_menu_tratamiento_curva')));
  endfor

  exp=fileread(fullfile(raiz,'src','sensibilidad','sens_exportar_resultados.m'));
  assert(~isempty(strfind(exp,'CURVE_TREATMENT_')));
  assert(~isempty(strfind(exp,'POLYNOMIAL_CURVE_')));
  assert(~isempty(strfind(exp,'POLYNOMIAL_OPTIMUM_VERIFICATION_')));
  assert(~isempty(strfind(exp,'fuente_primaria=SENSITIVITY_TABLE')));
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_contrato_estatico APROBADO\n');
endfunction
