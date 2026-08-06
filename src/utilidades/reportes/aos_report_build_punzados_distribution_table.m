function [tabla, resumen] = aos_report_build_punzados_distribution_table(Ql, param)
% AOS_REPORT_BUILD_PUNZADOS_DISTRIBUTION_TABLE Distribucion productiva por tiros.
  tabla=struct([]);resumen=struct('estado','NO_DISPONIBLE','metodo','','n_tramos',0,'n_tiros_total',0,'aviso','');
  global geologia;
  if exist('aos_obtener_punzados_activos','file')~=2||exist('aos_distribuir_produccion_punzados','file')~=2,return;endif
  try
    ints=aos_obtener_punzados_activos(geologia,param);if isempty(ints),return;endif
    d=aos_distribuir_produccion_punzados(Ql,geologia,ints,param);
    resumen.estado='DISPONIBLE';resumen.metodo=txt_local(d,'metodo','NO_INFORMADO');
    resumen.n_tramos=num_local(d,'n_tramos',numel(d.tramos));resumen.n_tiros_total=num_local(d,'n_tiros_total',0);
    campos={'MD_desde_m','MD_hasta_m','TVD_medio_m','n_tiros','fraccion_aporte','Ql_m3d','Qo_m3d','Qw_m3d','Ql_por_tiro_m3d'};
    labels={'MD desde','MD hasta','TVD medio','Tiros','Fraccion','Ql','Qo','Qw','Ql por tiro'};
    units={'m','m','m','','','m3/d','m3/d','m3/d','m3/d'};
    tabla=aos_report_table_from_structs('well_perforation_distribution','Aporte productivo por intervalo punzado','POZO', ...
      d.tramos,campos,labels,units,'role','PRIMARY_RESULT','category','COMPLETION','priority','PRIMARY', ...
      'default_mode','FULL_BODY','mandatory',true,'source','AOS_PERFORATION_DISTRIBUTION');
  catch err
    resumen.aviso=err.message;
  end_try_catch
endfunction
function s=txt_local(x,c,d),s=d;if isstruct(x)&&isfield(x,c)&&ischar(x.(c)),s=x.(c);endif,endfunction
function v=num_local(x,c,d),v=d;if isstruct(x)&&isfield(x,c)&&isnumeric(x.(c))&&isscalar(x.(c))&&isfinite(x.(c)),v=x.(c);endif,endfunction
