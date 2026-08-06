function p = bes3_editar_parametros(p,grupo)
  p=bes3_defaults(p);if nargin<2,grupo=1;endif
  if grupo==1
    fprintf('\n--- BES3: HIDRAULICA Y OPERACION ---\n');
    v=input(sprintf('IP (m3/d/bar) [%.3f]: ',p.IP*86400*1e5));if ~isempty(v),p.IP=v/86400/1e5;endif
    v=input(sprintf('WC [%.3f]: ',p.WC));if ~isempty(v),p.WC=v;endif
    v=input(sprintf('P cabeza (bar) [%.2f]: ',p.P_wh/1e5));if ~isempty(v),p.P_wh=v*1e5;endif
    v=input(sprintf('Profundidad intake (m) [%.1f]: ',p.D_bomba));if ~isempty(v),p.D_bomba=v;p.cable_longitud_m=v;endif
    v=input(sprintf('GLR (Sm3/m3) [%.2f]: ',p.GLR));if ~isempty(v),p.GLR=v;endif
    v=input(sprintf('Frecuencia configurada (Hz, admite 0) [%.1f]: ',p.frecuencia));if ~isempty(v),p.frecuencia=max(v,0);endif
    p.bes3_frecuencia_configurada_Hz=p.frecuencia;
    if p.frecuencia<=0,p.bes3_estado_bomba='apagada';else,p.bes3_estado_bomba='encendida';endif
    v=input(sprintf('Frecuencia minima operativa (Hz) [%.1f]: ',p.bes3_frecuencia_min_operativa_Hz));if ~isempty(v),p.bes3_frecuencia_min_operativa_Hz=max(v,0);endif
    v=input(sprintf('Frecuencia maxima operativa (Hz) [%.1f]: ',p.bes3_frecuencia_max_operativa_Hz));if ~isempty(v),p.bes3_frecuencia_max_operativa_Hz=max(v,p.bes3_frecuencia_min_operativa_Hz);endif
    v=input(sprintf('Etapas [%d]: ',p.num_etapas));if ~isempty(v),p.num_etapas=round(v);endif
    v=input(sprintf('Eficiencia separador [%.2f]: ',p.bes2_eta_separador));if ~isempty(v),p.bes2_eta_separador=v;endif
    fprintf('\nBomba apagada / flujo natural:\n');
    fprintf('1 - Ideal sin perdida pasiva (equivalente directo a Qiny=0)\n');
    fprintf('2 - BES instalada con perdida pasiva\n');
    fprintf('3 - Flujo bloqueado por completacion\n');
    op=input('Seleccione modelo [1]: ');if isempty(op),op=1;endif
    if op==2
      p.bes3_bomba_apagada_modelo='instalada';
      v=input(sprintf('Coeficiente K de perdida pasiva [%.2f]: ',p.bes3_bomba_apagada_K));if ~isempty(v),p.bes3_bomba_apagada_K=max(v,0);endif
      v=input(sprintf('Delta P fijo pasivo (bar) [%.2f]: ',p.bes3_bomba_apagada_dP_fijo_bar));if ~isempty(v),p.bes3_bomba_apagada_dP_fijo_bar=max(v,0);endif
      v=input(sprintf('Area efectiva de paso (cm2) [%.2f]: ',p.bes3_bomba_apagada_area_m2*1e4));if ~isempty(v),p.bes3_bomba_apagada_area_m2=max(v,0.01)/1e4;endif
      p.bes3_bomba_apagada_permite_flujo=1;
    elseif op==3
      p.bes3_bomba_apagada_modelo='bloqueada';p.bes3_bomba_apagada_permite_flujo=0;
    else
      p.bes3_bomba_apagada_modelo='ideal';p.bes3_bomba_apagada_permite_flujo=1;
    endif
    p=bes3_seleccionar_modelos(p);
  else
    fprintf('\n--- BES3: COMPLETACION, MOTOR Y CAPILAR ---\n');
    v=input(sprintf('Longitud protector (m) [%.2f]: ',p.bes3_longitud_protector_m));if ~isempty(v),p.bes3_longitud_protector_m=v;endif
    v=input(sprintf('Longitud motor (m) [%.2f]: ',p.bes3_longitud_motor_m));if ~isempty(v),p.bes3_longitud_motor_m=v;endif
    v=input(sprintf('OD motor (mm) [%.1f]: ',1000*p.bes3_OD_motor_m));if ~isempty(v),p.bes3_OD_motor_m=v/1000;endif
    v=input(sprintf('ID casing (mm) [%.1f]: ',1000*p.bes3_ID_casing_m));if ~isempty(v),p.bes3_ID_casing_m=v/1000;endif
    v=input(sprintf('Shroud 1-si 0-no [%d]: ',logical(p.bes3_shroud_habilitado)));if ~isempty(v),p.bes3_shroud_habilitado=logical(v);endif
    if p.bes3_shroud_habilitado
      v=input(sprintf('ID shroud (mm) [%.1f]: ',1000*p.bes3_ID_shroud_m));if ~isempty(v),p.bes3_ID_shroud_m=v/1000;endif
      v=input(sprintf('OD shroud (mm) [%.1f]: ',1000*p.bes3_OD_shroud_m));if ~isempty(v),p.bes3_OD_shroud_m=v/1000;endif
    endif
    v=input(sprintf('Velocidad minima refrigeracion (m/s) [%.3f]: ',p.velocidad_min_refrig));if ~isempty(v),p.velocidad_min_refrig=v;endif
    v=input(sprintf('Limite recirculacion (%% Q nominal efectivo) [%.1f]: ',p.bes3_limite_recirculacion_pct_nominal));if ~isempty(v),p.bes3_limite_recirculacion_pct_nominal=max(v,0);endif
    fprintf('Recirculacion: 1-automatica 2-instalada 3-deshabilitada\n');op=input('Seleccione [1]: ');if isempty(op),op=1;endif
    if op==2,p.bes3_recirculacion_modo='instalada';elseif op==3,p.bes3_recirculacion_modo='deshabilitada';else,p.bes3_recirculacion_modo='automatico';endif
    if strcmp(p.bes3_recirculacion_modo,'instalada')
      v=input(sprintf('Etapa toma [%.0f]: ',p.bes3_etapa_toma));if ~isempty(v),p.bes3_etapa_toma=round(v);endif
      v=input(sprintf('ID capilar (mm) [%.2f]: ',1000*p.bes3_capilar_ID_m));if ~isempty(v),p.bes3_capilar_ID_m=v/1000;endif
      v=input(sprintf('OD capilar (mm) [%.2f]: ',1000*p.bes3_capilar_OD_m));if ~isempty(v),p.bes3_capilar_OD_m=v/1000;endif
    endif
    v=input(sprintf('Longitud capilar (m) [%.2f]: ',p.bes3_capilar_longitud_m));if ~isempty(v),p.bes3_capilar_longitud_m=v;endif
    v=input(sprintf('OD cable (mm) [%.2f]: ',1000*p.bes3_OD_cable_m));if ~isempty(v),p.bes3_OD_cable_m=v/1000;endif
    v=input(sprintf('Dogleg (deg/30m) [%.2f]: ',p.bes3_dogleg_deg_30m));if ~isempty(v),p.bes3_dogleg_deg_30m=v;endif
  endif
  p.OD_motor=p.bes3_OD_motor_m;p.ID_casing=p.bes3_ID_casing_m;p.bes2_bomba_file=p.bes3_bomba_file;p=bes3_defaults(p);
endfunction
