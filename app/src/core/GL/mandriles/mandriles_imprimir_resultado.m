function mandriles_imprimir_resultado(R)
  fprintf('\n========== DISENO DE MANDRILES V2 AUTOMATICO ==========\n');
  fprintf('Estado                    : %s\n',R.estado);
  fprintf('Origen nivel inicial      : %s\n',R.nivel_inicial.origen);
  fprintf('Confianza nivel           : %s\n',R.nivel_inicial.confianza);
  fprintf('Nivel inicial             : %.1f m MD / %.1f m TVD\n', ...
      R.nivel_inicial.MD_m,R.nivel_inicial.TVD_m);
  if isfinite(R.nivel_inicial.Ql_natural_m3d)
    fprintf('Ql natural Qiny=0         : %.2f m3/d\n',R.nivel_inicial.Ql_natural_m3d);
  endif
  if isfinite(R.nivel_inicial.Pwf_natural_bar)
    fprintf('Pwf natural               : %.2f bar\n',R.nivel_inicial.Pwf_natural_bar);
  endif
  fprintf('Modelo casing             : %s\n',R.modelo_casing);
  fprintf('Modelo tubing             : %s\n',R.modelo_tubing);
  fprintf('Ql perfil operativo       : %.2f m3/d [%s]\n', ...
      R.Ql_diseno_m3d,R.fuente_Ql_diseno);
  fprintf('Ql screening unloading    : %.2f m3/d\n',R.Ql_unloading_m3d);
  fprintf('Qg screening unloading    : %.0f Sm3/d\n',R.Qg_unloading_m3d);
  fprintf('Modo cantidad             : %s\n',R.modo_cantidad);
  fprintf('Galeria                   : %s\n',R.fuente_galeria);
  fprintf('Qiny objetivo             : %.0f Sm3/d\n',R.Qiny_objetivo_m3d);
  fprintf('Profundidad objetivo      : %.1f m MD\n',R.profundidad_objetivo_m);
  fprintf('Profundidad alcanzable    : %.1f m MD\n',R.profundidad_alcanzable_m);
  fprintf('Numero sugerido           : %d\n',numel(R.valvulas));
  if isfinite(R.presion_adicional_requerida_bar) && R.presion_adicional_requerida_bar>0
    fprintf('Presion adicional req.    : %.1f bar\n',R.presion_adicional_requerida_bar);
  endif
  fprintf('---------------------------------------------------------------------------------------------------------------------\n');
  fprintf(' N Tipo              MD(m) TVD(m) PcOpen Ptub   dP  Puerto Capacidad Uso  Rating  Galeria / Valvula\n');
  for i=1:numel(R.valvulas)
    v=R.valvulas(i);
    fprintf('%2d %-17s %6.0f %6.0f %7.1f %6.1f %5.1f %6.1f %8.0f %4.0f%% %6.0f  %s / %s\n', ...
      v.n,v.tipo,v.MD_m,v.TVD_m,v.Pc_est_bar,v.Pt_bar,v.dP_bar, ...
      v.puerto_mm,v.capacidad_m3d,100*v.utilizacion,v.rating_bar, ...
      v.galeria_id,v.valvula_modelo);
  endfor
  fprintf('---------------------------------------------------------------------------------------------------------------------\n');
  if strcmp(R.estado,'DISENO_PARCIAL')
    fprintf('Interpretacion            : mejor diseno alcanzable; se informa presion adicional para la siguiente estacion.\n');
  elseif isempty(R.valvulas)
    fprintf('Interpretacion            : no abre la primera estacion; revisar nivel inferido, presion y diagnosticos de galeria.\n');
  endif
endfunction
