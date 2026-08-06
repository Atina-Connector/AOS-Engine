function econ = sens_configurar_economia_inyeccion()
% SENS_CONFIGURAR_ECONOMIA_INYECCION Configuracion economica opcional Qiny.
% Los defaults provienen de Configuracion general y del AOSDAT activo.
% La economia nunca se activa silenciosamente: el usuario confirma la corrida.
  econ = defaults_local();
  if ~aos_preguntar_sn('Incluir analisis economico? (s/n) [n]: ', false), return; endif

  m = strtrim(input(sprintf('  Moneda [%s]: ', econ.moneda), 's'));
  if ~isempty(m), econ.moneda = m; endif
  econ.valor_petroleo_por_m3 = leer_local(sprintf('  Valor neto del petroleo por m3 [%.6g]: ',econ.valor_petroleo_por_m3),econ.valor_petroleo_por_m3);
  econ.costo_gas_por_1000Sm3 = leer_local(sprintf('  Costo del gas inyectado por 1000 Sm3 [%.6g]: ',econ.costo_gas_por_1000Sm3),econ.costo_gas_por_1000Sm3);
  econ.costo_fijo_diario = leer_local(sprintf('  Costo fijo incremental diario [%.6g]: ',econ.costo_fijo_diario),econ.costo_fijo_diario);
  econ.habilitado = econ.valor_petroleo_por_m3 > 0 || ...
                     econ.costo_gas_por_1000Sm3 > 0 || ...
                     econ.costo_fijo_diario > 0;
  if ~econ.habilitado
    fprintf('Analisis economico desactivado: todos los valores monetarios son cero.\n');
  endif
endfunction

function e=defaults_local()
  e=struct('habilitado',false,'moneda','USD','valor_petroleo_por_m3',0, ...
    'costo_gas_por_1000Sm3',0,'costo_fijo_diario',0);
  try
    p=aos_preferencias_usuario('cargar');
    if isfield(p,'economia')&&isstruct(p.economia),e=copiar_local(e,p.economia);endif
  catch
  end_try_catch
  global CONFIG_ACTIVA;
  if ~isempty(CONFIG_ACTIVA)&&isstruct(CONFIG_ACTIVA)&&isfield(CONFIG_ACTIVA,'economia')&&isstruct(CONFIG_ACTIVA.economia)
    e=copiar_local(e,CONFIG_ACTIVA.economia);
  endif
  e.habilitado=false;
endfunction

function e=copiar_local(e,x)
  campos={'moneda','valor_petroleo_por_m3','costo_gas_por_1000Sm3','costo_fijo_diario'};
  for i=1:numel(campos)
    c=campos{i};
    if isfield(x,c)&&~isempty(x.(c))
      if strcmp(c,'moneda')
        e.(c)=char(x.(c));
      else
        v=numero_local(x.(c));if isfinite(v)&&v>=0,e.(c)=v;endif
      endif
    endif
  endfor
endfunction

function v=leer_local(mensaje,defecto)
  txt=strtrim(input(mensaje,'s'));
  if isempty(txt),v=defecto;return;endif
  v=str2double(txt);
  if ~isfinite(v)||v<0,fprintf('  Valor no valido; se conserva %.6g.\n',defecto);v=defecto;endif
endfunction

function v=numero_local(x)
  if isnumeric(x)&&isscalar(x),v=double(x);elseif ischar(x),v=str2double(x);else,v=NaN;endif
endfunction
