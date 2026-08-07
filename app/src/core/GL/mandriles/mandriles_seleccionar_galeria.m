function sel = mandriles_seleccionar_galeria(param, galeria, Pc_bar, Pt_bar, T_K, Qobj)
% Selecciona mandril/valvula/puerto de la galeria real disponible.

  sel = struct('ok',false,'item',struct(),'capacidad',struct(), ...
    'motivo','SIN_ELEMENTO_COMPATIBLE','descartes',{{}});
  if isempty(galeria)
    sel.motivo='GALERIA_VACIA'; return;
  endif
  dP = Pc_bar-Pt_bar;
  candidatos = struct([]);
  for i=1:numel(galeria)
    g=galeria(i); razones={};
    if ~g.habilitado, razones{end+1}='DESHABILITADO'; endif
    if isfinite(g.stock) && g.stock<=0, razones{end+1}='SIN_STOCK'; endif
    if max(Pc_bar,Pt_bar)>g.rating_bar, razones{end+1}='RATING'; endif
    if isfinite(g.Tmax_C) && (T_K-273.15)>g.Tmax_C, razones{end+1}='TEMPERATURA'; endif
    if Qobj>g.Qmax_Sm3_d, razones{end+1}='CAUDAL_MAX'; endif
    if dP<g.dP_apertura_min_bar || dP>g.dP_apertura_max_bar, razones{end+1}='RANGO_DP'; endif
    pp=param; pp.mand_rating_bar=g.rating_bar; pp.mand_puertos_mm=g.puertos_mm;
    cap=mandriles_capacidad_orificio(pp,Pc_bar,Pt_bar,T_K,Qobj);
    if ~strcmp(cap.estado,'OK'), razones{end+1}='PUERTO_CAPACIDAD'; endif
    if isempty(razones)
      c=struct('item',g,'capacidad',cap,'score',score_local(g,cap,Qobj,dP));
      if isempty(candidatos),candidatos=c;else,candidatos(end+1)=c;endif
    else
      sel.descartes{end+1}=sprintf('%s:%s',g.id,strjoin(razones,'+'));
    endif
  endfor
  if isempty(candidatos), return; endif
  [~,ix]=min([candidatos.score]);
  sel.ok=true; sel.item=candidatos(ix).item; sel.capacidad=candidatos(ix).capacidad; sel.motivo='OK';
endfunction

function s=score_local(g,cap,Q,dP)
% Prioriza menor rating suficiente, menor sobredimensionamiento y menor puerto.
  s=0.03*g.rating_bar + 20*abs(cap.capacidad_m3d-Q)/max(Q,1) + cap.puerto_mm + 0.1*abs(dP-g.dP_apertura_min_bar);
endfunction
