function cgf_imprimir_resultado(sol)
  fprintf('\n========== RESULTADOS CGF V1 ==========\n');
  fprintf('Estado solver            : %s\n',sol.estado);
  fprintf('Aceptado                  : %s\n',si_no_local(sol.aceptado));
  fprintf('Compresor                 : %s\n',sol.compresor.modelo);
  fprintf('Origen mapa               : %s\n',sol.compresor.origen);
  fprintf('Produccion gas            : %.0f Sm3/d\n',sol.Qg_Sm3_d);
  if isfield(sol,'punto')
    p=sol.punto;
    fprintf('Pwf                       : %.2f bar\n',p.Pwf_Pa/1e5);
    fprintf('Presion succion           : %.2f bar\n',p.Ps_Pa/1e5);
    fprintf('Presion descarga          : %.2f bar\n',p.Pd_Pa/1e5);
    fprintf('Descarga requerida        : %.2f bar\n',p.Pd_req_Pa/1e5);
    fprintf('Relacion compresion       : %.3f\n',p.mapa.PR);
    fprintf('Temperatura descarga      : %.1f C\n',p.T_d_K-273.15);
    fprintf('Eficiencia politropica    : %.1f %%\n',100*p.mapa.eta_p);
    fprintf('Margen surge              : %.1f %%\n',p.mapa.margen_surge_pct);
    fprintf('Margen choke              : %.1f %%\n',p.mapa.margen_choke_pct);
    fprintf('Potencia eje              : %.2f kW\n',p.P_eje_kW);
  endif
  if isfield(sol,'electrico')
    fprintf('Potencia superficie       : %.2f kW\n',sol.electrico.P_superficie_kW);
    fprintf('Corriente                 : %.1f A\n',sol.electrico.corriente_A);
    fprintf('Temperatura motor         : %.1f C\n',sol.electrico.termica.T_motor_C);
  endif
  fprintf('Estado liquidos           : %s\n',sol.liquid_state);
  fprintf('Diagnostico               : %s\n',sol.diagnostico);
  fprintf('========================================\n');
endfunction
function s=si_no_local(v),if v,s='SI';else,s='NO';endif,endfunction
