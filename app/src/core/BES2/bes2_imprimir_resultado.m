function bes2_imprimir_resultado(sol)
  fprintf('\n========== RESULTADOS BES V2 ==========' );
  fprintf('\nEstado solver            : %s',sol.estado);
  fprintf('\nAceptado                  : %s',si_no_local(sol.aceptado));
  fprintf('\nModelo bomba              : %s',sol.bomba.modelo);
  fprintf('\nOrigen curva              : %s',sol.bomba.origen);
  fprintf('\nLiquido                   : %.2f m3/d',sol.Ql_m3_d);
  fprintf('\nPetroleo                  : %.2f m3/d',sol.Qo_m3_d);
  fprintf('\nGas total                 : %.0f Sm3/d',sol.Qg_total_Sm3_d);
  if isfield(sol,'punto')&&isstruct(sol.punto)&&isfield(sol.punto,'Pintake_Pa')
    p=sol.punto;
    fprintf('\nP intake                  : %.2f bar',p.Pintake_Pa/1e5);
    fprintf('\nP descarga requerida      : %.2f bar',p.Pdesc_req_Pa/1e5);
    fprintf('\nDelta P bomba             : %.2f bar',p.dP_bomba_Pa/1e5);
    fprintf('\nHead total                : %.1f m',p.head_m);
    fprintf('\nEficiencia bomba          : %.1f %%',100*p.eta_bomba);
    fprintf('\nGas libre antes separador : %.1f %%',100*p.fluido.gvf_free);
    fprintf('\nGas que entra a bomba     : %.1f %%',100*p.fluido.gvf_bomba);
    fprintf('\nPotencia eje              : %.2f kW',p.P_eje_kW);
  endif
  if isfield(sol,'percent_BEP')
    fprintf('\nOperacion respecto BEP    : %.1f %%',sol.percent_BEP);
    fprintf('\nRango bomba               : %s',sol.rango_estado);
    fprintf('\nEstado gas                : %s',sol.gas_estado);
    fprintf('\nPotencia superficie       : %.2f kW',sol.electrico.P_superficie_kW);
    fprintf('\nCorriente                 : %.1f A',sol.electrico.corriente_A);
    fprintf('\nTemperatura motor         : %.1f C',sol.electrico.termica.T_motor_C);
    fprintf('\nEstado electrico/termico  : %s',sol.electrico.estado);
  endif
  fprintf('\nRaices detectadas         : %d',sol.n_raices);
  fprintf('\nDiagnostico               : %s',sol.diagnostico);
  fprintf('\n========================================\n');
endfunction
function s=si_no_local(v),if v,s='SI';else,s='NO';endif,endfunction
