function VERIFICAR_MENU_QINY_3_OPCIONES()
% Verificacion no interactiva del selector Qiny. GNU Octave objetivo.
  fprintf('\n=== VERIFICACION MENU QINY 3 OPCIONES ===\n');
  iniciar_aos;
  p=struct();
  p.Qiny_aosdat_Sm3_d=16486;
  p.Q_iny=16486/86400;
  p.gl=struct(); p.jgl=struct();

  [p1,i1]=aos_aplicar_opcion_qiny(p,1,[]);
  assert(abs(p1.Q_iny*86400-16486)<1e-6);
  assert(strcmp(i1.modo,'configurado'));

  pruebas=[0 3000 16486 25000 140000];
  for k=1:numel(pruebas)
    q=pruebas(k);
    [px,ix]=aos_aplicar_opcion_qiny(p,2,q);
    assert(abs(px.Q_iny*86400-q)<1e-6);
    assert(abs(px.gl.Q_iny*86400-q)<1e-6);
    assert(abs(px.jgl.Q_iny*86400-q)<1e-6);
    assert(strcmp(ix.modo,'manual'));
  end

  [p3,i3]=aos_aplicar_opcion_qiny(p,3,[]);
  assert(strcmp(p3.qiny_modo,'automatico'));
  assert(strcmp(i3.modo,'automatico'));
  assert(~isfield(p3,'Q_iny'));

  f=which('sens_P_iny');
  if isempty(f), f=fullfile(fileparts(mfilename('fullpath')),'src','sensibilidad','sens_P_iny.m'); end
  txt=fileread(f);
  assert(~isempty(strfind(txt,"politica_q = 'presion'")));
  assert(isempty(strfind(txt,"sens_menu_qiny_comun(base, 'presion')")));

  fprintf('Opcion 1: conserva valor configurado. OK\n');
  fprintf('Opcion 2: acepta cualquier valor >= 0. OK\n');
  fprintf('Opcion 3: activa calculo automatico. OK\n');
  fprintf('Sensibilidad P_iny: automatico punto a punto obligatorio. OK\n');
  fprintf('VERIFICACION APROBADA.\n');
end
