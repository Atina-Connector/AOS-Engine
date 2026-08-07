function aos_rpt_escribir_diagnostico(fid, d)
% AOS_RPT_ESCRIBIR_DIAGNOSTICO Serializa diagnostico ejecutivo portable.
  if nargin<2 || ~isstruct(d), return; endif
  fprintf(fid,'\n[EXECUTIVE_DIAGNOSIS]\n');
  fprintf(fid,'schema=%s\n',texto_local(d,'schema','AOS_EXECUTIVE_DIAGNOSIS_1.0'));
  fprintf(fid,'render_preferred=EXECUTIVE_SUMMARY\n');
  fprintf(fid,'display_order=10\n');
  fprintf(fid,'estado_global=%s\n',limpiar_local(texto_local(d,'estado_global','NO_EVALUADO')));
  fprintf(fid,'semaforo=%s\n',limpiar_local(texto_local(d,'semaforo','GRIS')));
  fprintf(fid,'resumen=%s\n',limpiar_local(texto_local(d,'resumen','')));
  escribir_num_local(fid,d,'n_puntos','%d');
  escribir_num_local(fid,d,'n_aceptados','%d');
  escribir_num_local(fid,d,'n_rechazados','%d');
  escribir_num_local(fid,d,'n_sin_produccion','%d');
  escribir_num_local(fid,d,'n_no_convergidos','%d');
  escribir_num_local(fid,d,'n_advertencias','%d');
  if isfield(d,'q_tolerancia') && isnumeric(d.q_tolerancia) && isscalar(d.q_tolerancia) && isfinite(d.q_tolerancia)
    fprintf(fid,'q_tolerancia=%.12g\n',d.q_tolerancia);
    fprintf(fid,'q_tolerancia_unidad=%s\n',limpiar_local(texto_local(d,'q_unidad','-')));
  endif
  mensajes={}; if isfield(d,'mensajes') && iscell(d.mensajes), mensajes=d.mensajes; endif
  fprintf(fid,'n_mensajes=%d\n',numel(mensajes));
  for i=1:numel(mensajes)
    if ischar(mensajes{i}), fprintf(fid,'mensaje_%03d=%s\n',i,limpiar_local(mensajes{i})); endif
  endfor
endfunction
function escribir_num_local(fid,s,campo,fmt)
  if isfield(s,campo)&&isnumeric(s.(campo))&&isscalar(s.(campo))&&isfinite(s.(campo))
    fprintf(fid,[campo '=' fmt '\n'],round(s.(campo)));
  endif
endfunction
function t=texto_local(s,c,d)
  t=d;if isfield(s,c)&&ischar(s.(c))&&~isempty(strtrim(s.(c))),t=s.(c);endif
endfunction
function s=limpiar_local(s)
  if ~ischar(s),s='';endif;s=regexprep(s,'[\r\n=]',' ');
endfunction
