function param = aos_despachar_aosdat_secciones(param)
% AOS_DESPACHAR_AOSDAT_SECCIONES Normaliza bloques nativos sin intervencion.
% La importacion .aosdat es unica e indiferenciada. Esta funcion no pregunta
% al usuario, no descarta secciones y no ejecuta comandos operativos.
  if ~isstruct(param), return; endif
  if ~isfield(param,'aosdat_sections') || ~isstruct(param.aosdat_sections), return; endif

  mapas = {
    'catalogos', {'catalogos','catalogo','aos_catalogos','catalogos_embebidos'};
    'calibracion', {'calibracion','calibraciones','aos_calibracion'};
    'scada', {'scada','scada_datos','scada_config'};
    'economia', {'economia','parametros_economicos','economicos'};
    'pcp', {'pcp','sla_pcp','bombeo_cavidades_progresivas'};
    'ldl', {'ldl','pcp_ldl','sla_pcp_ldl'};
    'inyectores', {'inyectores','pozos_inyectores','pozos_inyectores_agua','pozos_inyectores_gas','pozos_inyectores_polimeros','inyeccion_agua','inyeccion_gas','inyeccion_polimeros'};
    'mallas', {'mallas','malla','niveles','mallas_niveles'};
    'baterias', {'baterias','instalaciones','baterias_instalaciones'};
    'fluidos', {'fluidos','aseguramiento_flujo','aseguramiento_de_flujo'};
    'red_electrica', {'red_electrica','redes_electricas'};
    'arranque', {'arranque','secuencia_arranque','secuencia_de_arranque'};
  };

  detectadas = {};
  for i=1:size(mapas,1)
    canon = mapas{i,1}; aliases = mapas{i,2};
    [valor, origen, ok] = buscar_local(param, aliases);
    if ok
      if ~isfield(param,canon) || isempty(param.(canon))
        param.(canon)=valor;
      endif
      detectadas{end+1}=sprintf('%s<-%s',canon,origen); %#ok<AGROW>
    endif
  endfor

  param.aosdat_despacho = struct();
  param.aosdat_despacho.version = 'AOSDAT_DISPATCH_1.0';
  param.aosdat_despacho.secciones_detectadas = detectadas;
  param.aosdat_despacho.automatico = true;
  param.aosdat_despacho.intervencion_usuario = false;
endfunction

function [valor,origen,ok]=buscar_local(param,aliases)
  valor=[]; origen=''; ok=false;
  for j=1:numel(aliases)
    a=aliases{j};
    if isfield(param,a)
      valor=param.(a);origen=a;ok=true;return;
    endif
    if isfield(param,'aosdat_sections') && isfield(param.aosdat_sections,a)
      valor=param.aosdat_sections.(a);origen=['aosdat_sections.',a];ok=true;return;
    endif
  endfor
endfunction
