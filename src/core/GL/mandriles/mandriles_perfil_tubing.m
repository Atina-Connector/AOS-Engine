function prof = mandriles_perfil_tubing(param, survey, profundidad_activa, etapa)
% Compatibilidad con llamadas anteriores. El calculo fisico se delega al
% perfil compresible por tramos.
  p = mandriles_defaults(param);
  nivel = p.mand_nivel_estatico_m;
  if ~isfinite(nivel)
    nivel = 0;
  endif
  if nargin < 4 || etapa <= 0
    profundidad_activa = nivel;
    qg = 0;
    ql = 0;
  else
    qg = 0;
    if isfield(p,'mand_Qg_unloading_m3d') && isfinite(p.mand_Qg_unloading_m3d)
      qg = p.mand_Qg_unloading_m3d;
    endif
    ql = 0;
    if isfield(p,'mand_Ql_diseno_m3d') && isfinite(p.mand_Ql_diseno_m3d)
      ql = p.mand_Ql_diseno_m3d;
    endif
  endif
  prof = mandriles_perfil_tubing_unloading(p,survey,nivel,profundidad_activa,qg,ql);
  prof.etapa = etapa;
endfunction
