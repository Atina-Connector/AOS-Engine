function egf_imprimir_resultado(sol)
  fprintf('\n========== RESULTADOS EGF V1 ==========\n');
  fprintf('Estado solver            : %s\n',sol.estado);
  fprintf('Aceptado                  : %s\n',si_no_local(sol.aceptado));
  fprintf('Eyector                   : %s\n',sol.eyector.modelo);
  fprintf('Origen                    : %s\n',sol.eyector.origen);
  fprintf('Gas aspirado              : %.0f Sm3/d\n',sol.Qg_aspirado_Sm3_d);
  fprintf('Gas motriz                : %.0f Sm3/d\n',sol.Qg_motriz_Sm3_d);
  fprintf('Gas total descarga        : %.0f Sm3/d\n',sol.Qg_total_Sm3_d);
  if isfield(sol,'punto')
    p=sol.punto;
    fprintf('Pwf                       : %.2f bar\n',p.Pwf/1e5);
    fprintf('Presion succion           : %.2f bar\n',p.Ps/1e5);
    fprintf('P motriz fondo            : %.2f bar\n',p.Pm_fondo/1e5);
    fprintf('P mezcla                  : %.2f bar\n',p.Pmix/1e5);
    fprintf('P descarga disponible     : %.2f bar\n',p.Pd_pred/1e5);
    fprintf('P descarga requerida      : %.2f bar\n',p.Pd_req/1e5);
    fprintf('Entrainment m_s/m_p       : %.3f\n',p.entrainment);
    fprintf('Mach mezcla               : %.3f\n',p.Mach_mix);
    fprintf('Regimen                   : %s\n',p.regimen);
    fprintf('Potencia equivalente sup. : %.2f kW\n',p.P_equiv_superficie_kW);
  endif
  fprintf('Diagnostico               : %s\n',sol.diagnostico);
  fprintf('========================================\n');
endfunction
function s=si_no_local(v),if v,s='SI';else,s='NO';endif,endfunction
