function p = bes3_seleccionar_modelos(p)
% Seleccion explicita de IPR y VLP antes de cada simulacion BES3.
  p=bes3_defaults(p);

  fprintf('\n--- MODELOS DE FLUJO BES3 ---\n');
  fprintf('IPR (entrada de reservorio):\n');
  fprintf('  1 - Linear\n');
  fprintf('  2 - Vogel\n');
  fprintf('  3 - Fetkovich\n');
  opdef=aos_opcion_modelo_ipr(p.modelo_IPR);
  op=input(sprintf('Seleccione IPR (1-3) [%d]: ',opdef));
  if isempty(op),op=opdef;endif
  if op==2
    p.modelo_IPR='Vogel';
    pres=leer_num_local(p,'P_res',100e5);
    pb=leer_num_local(p,'P_b',leer_num_local(p,'P_b_bar',pres/1e5));
    if pb>1e4,pb=pb/1e5;endif
    v=input(sprintf('Presion de burbuja (bar) [%.2f]: ',pb));
    if ~isempty(v),p.P_b=v*1e5;elseif ~isfield(p,'P_b')||isempty(p.P_b),p.P_b=pb*1e5;endif
  elseif op==3
    p.modelo_IPR='Fetkovich';
    n=leer_num_local(p,'fetkovich_n',1.0);
    v=input(sprintf('Exponente Fetkovich n [%.3f]: ',n));
    if ~isempty(v),p.fetkovich_n=max(v,0.05);else,p.fetkovich_n=max(n,0.05);endif
    if ~isfield(p,'fetkovich_C')||~isnumeric(p.fetkovich_C)||isempty(p.fetkovich_C)||~isfinite(p.fetkovich_C(1))||p.fetkovich_C(1)<=0
      fprintf('Aviso: sin coeficiente C de ensayo, AOS usara la estimacion historica derivada del IP.\n');
    endif
  else
    p.modelo_IPR='linear';
  endif

  fprintf('\nVLP (salida por tubing hasta superficie):\n');
  fprintf('  1 - Simplificado\n');
  fprintf('  2 - Hagedorn-Brown\n');
  fprintf('  3 - Duns & Ros\n');
  opdef=aos_opcion_modelo_vlp(p.modelo_VLP);
  op=input(sprintf('Seleccione VLP (1-3) [%d]: ',opdef));
  if isempty(op),op=opdef;endif
  if op==2
    p.modelo_VLP='HB';
  elseif op==3
    p.modelo_VLP='DR';
  else
    p.modelo_VLP='simplified';
  endif

  fprintf('\nModelos seleccionados:\n');
  fprintf('  IPR: %s\n',p.modelo_IPR);
  fprintf('  VLP: %s\n',p.modelo_VLP);
  try
    info=aos_vlp_info(p,p.D_bomba);
    fprintf('  VLP efectiva: %s',info.efectivo);
    if isfield(info,'fallback')&&info.fallback,fprintf(' (fallback por datos insuficientes)');endif
    fprintf('\n');
  catch
  end_try_catch
  if isfield(p,'survey')&&~isempty(p.survey)
    try,diagnostico_vlp(p.survey,p.modelo_VLP);catch,end_try_catch
  endif
endfunction

function v=leer_num_local(s,campo,defecto)
  v=defecto;
  if ~isstruct(s)||~isfield(s,campo),return;endif
  x=s.(campo);
  if isnumeric(x)&&~isempty(x)&&isfinite(x(1)),v=x(1);return;endif
  if ischar(x),z=str2double(strtrim(x));if isfinite(z),v=z;endif,endif
endfunction
