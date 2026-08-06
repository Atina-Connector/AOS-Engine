function aos_rpt_escribir_mandriles(fid,R)
% AOS_RPT_ESCRIBIR_MANDRILES Resumen de diseno; filas en tabla nativa HF3.5.
  if fid<0||~isstruct(R),return;endif
  fprintf(fid,'\n[MANDRILES_DISENO]\n');
  fprintf(fid,'version=%s\nestado=%s\nmodo_cantidad=%s\nfuente_galeria=%s\n',txt(R,'version',''),txt(R,'estado',''),txt(R,'modo_cantidad',''),txt(R,'fuente_galeria',''));
  fprintf(fid,'modelo_casing=%s\nmodelo_tubing=%s\n',txt(R,'modelo_casing',''),txt(R,'modelo_tubing',''));
  if isfield(R,'nivel_inicial')&&isstruct(R.nivel_inicial)
    n=R.nivel_inicial;fprintf(fid,'nivel_inicial_MD_m=%.6f\nnivel_inicial_TVD_m=%.6f\nnivel_origen=%s\nnivel_confianza=%s\n',num(n,'MD_m',NaN),num(n,'TVD_m',NaN),txt(n,'origen',''),txt(n,'confianza',''));
  endif
  fprintf(fid,'Ql_diseno_m3d=%.6f\nQl_unloading_m3d=%.6f\nQg_unloading_Sm3_d=%.6f\n',num(R,'Ql_diseno_m3d',NaN),num(R,'Ql_unloading_m3d',NaN),num(R,'Qg_unloading_m3d',NaN));
  fprintf(fid,'Qiny_objetivo_Sm3_d=%.6f\nprofundidad_objetivo_m=%.6f\nprofundidad_alcanzable_m=%.6f\npresion_adicional_bar=%.6f\nn_estaciones=%d\n',num(R,'Qiny_objetivo_m3d',NaN),num(R,'profundidad_objetivo_m',NaN),num(R,'profundidad_alcanzable_m',NaN),num(R,'presion_adicional_requerida_bar',NaN),count_valves(R));
  fprintf(fid,'table_id=gl_mandriles_diseno\n');
  fprintf(fid,'datos_completos=TABLA_NATIVA_O_ARCHIVO_INTERNO\n');
  fprintf(fid,'presentacion_controlada_por=REPORT_COMPOSITION\n');
endfunction
function n=count_valves(R),n=0;if isfield(R,'valvulas'),n=numel(R.valvulas);endif,endfunction
function s=txt(x,c,d),s=d;if isfield(x,c)&&ischar(x.(c)),s=regexprep(x.(c),'[\r\n=]',' ');endif,endfunction
function v=num(x,c,d),v=d;if isfield(x,c)&&isnumeric(x.(c))&&isscalar(x.(c))&&isfinite(x.(c)),v=x.(c);endif,endfunction
