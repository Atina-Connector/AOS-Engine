function ok = test_sens_gljgl03_contrato_estatico()
% Verifica menu visible, ruta derivada, grafica y reporting SENS03.
  ok = false;
  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  req = { ...
    'src/core/JGL/jgl_modo_condicion_motriz.m', ...
    'src/core/JGL/jgl_deltaP_cinetica_qiny.m', ...
    'src/core/JGL/jgl_condicion_motriz.m', ...
    'src/sensibilidad/sens_menu_condicion_motriz_jgl.m', ...
    'src/sensibilidad/sens_jgl_construir_presiones.m', ...
    'src/sensibilidad/sens_jgl_limite_presion.m', ...
    'src/sensibilidad/sens_jgl_graficar_presiones.m'};
  for i=1:numel(req),assert(exist(fullfile(raiz,req{i}),'file')==2);endfor

  menu = fileread(fullfile(raiz,'src','sensibilidad','sens_menu_condicion_motriz_jgl.m'));
  assert(~isempty(strfind(menu,'Derivar la presion minima requerida desde Qiny')));
  assert(~isempty(strfind(menu,'Ingresar una presion superficial disponible')));
  assert(~isempty(strfind(menu,'Confirmar que no existe presion motriz')));

  comun = fileread(fullfile(raiz,'src','core','JGL','jgl_eductor_comun.m'));
  i_cond = strfind(comun,'jgl_condicion_motriz(p,Qiny,Ps)');
  i_block = strfind(comun,'C.bloquea_operacion');
  assert(~isempty(i_cond) && ~isempty(i_block) && i_cond(1) < i_block(1));
  assert(~isempty(strfind(comun,'Piny_sup_requerida')));

  ed = fileread(fullfile(raiz,'src','utilidades','nodal','eductor_jgl.m'));
  assert(~isempty(strfind(ed,'DERIVADA_DESDE_QINY')));
  assert(~isempty(strfind(ed,'qiny_impuesto_cinetico_explicito')));

  for f={'sens_Qiny_JGL.m','sens_Qiny.m'}
    t=fileread(fullfile(raiz,'src','sensibilidad',f{1}));
    assert(~isempty(strfind(t,'sens_menu_condicion_motriz_jgl')));
    assert(~isempty(strfind(t,'sens_jgl_graficar_presiones')));
    assert(~isempty(strfind(t,'PRESIONES_JGL')));
  endfor

  menu_punto = fileread(fullfile(raiz,'src','menu','JGL_menu.m'));
  assert(~isempty(strfind(menu_punto,'SIMULACION PUNTUAL JGL')));
  assert(~isempty(strfind(menu_punto,'sens_menu_condicion_motriz_jgl')));

  exp = fileread(fullfile(raiz,'src','sensibilidad','sens_exportar_resultados.m'));
  assert(~isempty(strfind(exp,'[JGL_MOTIVE_PRESSURE]')));
  assert(~isempty(strfind(exp,'P_iny_sup_requerida_JGL_bar')));
  assert(~isempty(strfind(exp,'formula_fondo=Pm_req=Ps+DeltaP_motriz_req')));
  assert(~isempty(strfind(exp,'sobrescritura_oculta=NO')));

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl03_contrato_estatico APROBADO\n');
endfunction
