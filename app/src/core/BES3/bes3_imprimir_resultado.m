function bes3_imprimir_resultado(sol)
  apagada=strcmp(texto_local(sol,'modo_operacion'),'BOMBA_APAGADA');
  fprintf('\n================ RESULTADOS BES3 ================\n');
  fprintf('Version / validacion       : %s / %s\n',sol.version,sol.estado_validacion);
  fprintf('Modo operativo             : %s\n',texto_local(sol,'modo_operacion'));
  fprintf('Frecuencia conf./efectiva  : %.2f / %.2f Hz\n',num_local(sol,'frecuencia_configurada_Hz'),num_local(sol,'frecuencia_efectiva_Hz'));
  fprintf('Estado de frecuencia       : %s\n',texto_local(sol,'frecuencia_estado'));
  fprintf('IPR seleccionado           : %s\n',texto_local(sol,'modelo_IPR'));
  fprintf('VLP seleccionado / efectivo: %s / %s\n',texto_local(sol,'modelo_VLP'),texto_local(sol,'vlp_efectivo'));
  fprintf('Estado solver              : %s\n',sol.estado);
  fprintf('Tipo de punto              : %s\n',texto_local(sol,'punto_tipo'));
  fprintf('Convergido                 : %s\n',sino_local(sol.convergido));
  fprintf('Aceptacion fisica prelim.  : %s\n',sino_local(sol.aceptado_preliminar));
  fprintf('Aceptacion certificada     : NO (pendiente benchmark)\n');
  fprintf('Bomba                      : %s\n',sol.bomba.modelo);
  fprintf('Etapas totales             : %.0f\n',num_local(sol,'num_etapas_total'));
  if sol.convergido
    if apagada,fprintf('Liquido por flujo natural  : %.2f m3/d\n',sol.Ql_m3_d);else,fprintf('Produccion superficie      : %.2f m3/d\n',sol.Ql_m3_d);endif
  elseif strcmp(sol.estado,'POZO_SIN_FLUJO_NATURAL')
    fprintf('Liquido por flujo natural  : 0.00 m3/d\n');
  else
    fprintf('Caudal de referencia       : %.2f m3/d (NO es cruce nodal)\n',sol.Ql_m3_d);
    fprintf('Margen en referencia       : %.2f bar\n',sol.margen_nodal_bar);
    fprintf('ADVERTENCIA                : no existe punto de operacion dentro del dominio evaluado.\n');
  endif
  fprintf('Petroleo                   : %.2f m3/d\n',sol.Qo_m3_d);
  if apagada
    fprintf('Head aportado por bomba    : 0.00 m\n');fprintf('Potencia / corriente       : 0.00 kW / 0.00 A\n');
    fprintf('Recirculacion capilar      : 0.00 m3/d (inactiva)\n');
  else
    fprintf('Caudal local etapas sup.   : %.2f m3/d\n',num_local(sol,'Q_etapas_superiores_m3_d'));
    fprintf('Recirculacion capilar      : %.2f m3/d\n',sol.Q_recirc_m3_d);
    fprintf('Caudal etapas inferiores   : %.2f m3/d\n',num_local(sol,'Q_etapas_inferiores_m3_d'));
    fprintf('Caudal nominal efectivo    : %.2f m3/d (BEP corregido)\n',num_local(sol,'Q_nominal_efectivo_m3_d'));
    fprintf('Limite de recirculacion    : %.2f m3/d (%.1f %% Qnom)\n',num_local(sol,'Q_recirc_max_diseno_m3_d'),num_diag_local(sol,'limite_recirc_pct_nominal'));
    fprintf('Recirculacion / Qnom       : %.2f %%\n',num_local(sol,'Q_recirc_pct_nominal'));
    fprintf('Diseno de recirculacion    : %s\n',texto_local(sol,'estado_diseno_recirculacion'));
    fprintf('Estado operativo recirc.   : %s\n',texto_local(sol,'estado_operativo_recirculacion'));
  endif
  if ~isfield(sol,'punto')
    fprintf('Diagnostico                : %s\n',sol.diagnostico);fprintf('===================================================\n');return;
  endif
  e=sol.punto;r=e.recirculacion;
  fprintf('P wf en punzados           : %.2f bar\n',e.Pwf_Pa/1e5);
  fprintf('P intake disponible        : %.2f bar\n',e.Pintake_Pa/1e5);
  fprintf('P descarga disponible      : %.2f bar\n',e.Pdesc_disponible_Pa/1e5);
  fprintf('P descarga requerida VLP   : %.2f bar\n',e.Pdesc_req_Pa/1e5);
  if apagada
    fprintf('Perdida pasiva BES apagada : %.2f bar (%s)\n',e.dP_bomba_apagada_Pa/1e5,e.bomba_apagada_loss.modelo);
  else
    d=sol.diagnostico_recirculacion;
    fprintf('Delta P bomba              : %.2f bar\n',e.dP_bomba_Pa/1e5);fprintf('Head total                 : %.1f m\n',e.head_m);
    fprintf('Potencia al eje            : %.2f kW\n',e.P_eje_kW);fprintf('GVF que entra a bomba      : %.2f %%\n',100*e.fluido.gvf_bomba);
    fprintf('Posicion vs punzados       : %s\n',e.geometria.posicion_estado);
    fprintf('Etapa de toma / secciones  : %d | %d inferiores + %d superiores\n',d.etapa_toma,d.n_etapas_inferiores,d.n_etapas_superiores);
    fprintf('BEP etapas inferiores      : %.1f %% (%s)\n',d.BEP_inferior_pct,d.rango_inferior_estado);
    fprintf('BEP etapas superiores      : %.1f %% (%s)\n',d.BEP_superior_pct,d.rango_superior_estado);
    fprintf('Refrigeracion natural      : %.2f m3/d\n',r.Q_natural_m3_d);fprintf('Refrigeracion minima       : %.2f m3/d\n',r.Q_min_refrig_m3_d);
    fprintf('Recirculacion requerida    : %.2f m3/d\n',r.Q_requerido_m3_d);
    if isstruct(r.capilar)&&isfield(r.capilar,'ID_m'),fprintf('Capilar ID / OD            : %.2f / %.2f mm\n',1000*r.capilar.ID_m,1000*r.capilar.OD_m);endif
    fprintf('Presion toma / capilar     : %.2f / %.2f bar\n',d.dP_toma_bar,d.dP_capilar_bar);
    fprintf('Regimen capilar            : %s (Re %.0f)\n',r.regimen_capilar,r.Re_capilar);fprintf('Margen de presion          : %.1f %%\n',100*r.margen_presion);
    fprintf('Velocidad sobre motor      : %.3f m/s\n',r.velocidad_total_m_s);fprintf('Temperatura motor          : %.1f C\n',e.electrico.termica.T_motor_C);
    fprintf('Potencia superficie        : %.2f kW\n',e.electrico.P_superficie_kW);fprintf('Corriente                  : %.1f A\n',e.electrico.corriente_A);
    fprintf('Operacion respecto BEP sup.: %.1f %%\n',sol.BEP_superior_pct);fprintf('Gas                        : %s\n',sol.gas_estado);
    fprintf('Refrigeracion              : %s\n',sol.refrigeracion_estado);
  endif
  fprintf('Raices detectadas          : %d\n',sol.n_raices);
  fprintf('\nSemaforos:\n');for i=1:numel(sol.semaforos),fprintf('  [%s] %-28s %s\n',sol.semaforos(i).estado,sol.semaforos(i).id,sol.semaforos(i).mensaje);endfor
  fprintf('Diagnostico                : %s\n',sol.diagnostico);fprintf('===================================================\n');
endfunction
function s=sino_local(x),if x,s='SI';else,s='NO';endif,endfunction
function s=texto_local(x,campo),s='N/A';if isstruct(x)&&isfield(x,campo)&&ischar(x.(campo)),s=x.(campo);endif,endfunction
function v=num_local(x,campo),v=NaN;if isstruct(x)&&isfield(x,campo)&&isnumeric(x.(campo))&&~isempty(x.(campo)),v=x.(campo)(1);endif,endfunction
function v=num_diag_local(sol,campo),v=NaN;if isfield(sol,'diagnostico_recirculacion'),v=num_local(sol.diagnostico_recirculacion,campo);endif,endfunction
