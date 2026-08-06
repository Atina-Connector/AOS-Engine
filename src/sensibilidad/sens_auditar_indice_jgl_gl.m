function a = sens_auditar_indice_jgl_gl(qiny_sm3d, indice_jgl, indice_gl, tolerancia_pct)
% Compara exactamente el mismo indicador canonico entre JGL y GL.
% No modifica resultados ni fuerza JGL >= GL; solo informa inconsistencias.
  if nargin<4 || isempty(tolerancia_pct), tolerancia_pct=1e-6; endif
  n=min([numel(qiny_sm3d),numel(indice_jgl),numel(indice_gl)]);
  qiny_sm3d=qiny_sm3d(1:n);indice_jgl=indice_jgl(1:n);indice_gl=indice_gl(1:n);
  ok=isfinite(indice_jgl)&isfinite(indice_gl);
  delta=indice_jgl-indice_gl;
  ids=find(ok & delta < -abs(tolerancia_pct));
  mensajes=cell(1,numel(ids));
  for k=1:numel(ids)
    i=ids(k);
    mensajes{k}=sprintf(['ALERTA ENERGETICA: a Qiny %.0f Sm3/d el indice bruto JGL ' ...
      '(%.3f %%) es menor que GL (%.3f %%). Se conserva el resultado y se marca para revision fisica.'], ...
      qiny_sm3d(i),indice_jgl(i),indice_gl(i));
  endfor
  a=struct('schema','AOS_ENERGY_COMPARISON_AUDIT_1_0','n_puntos',n, ...
    'n_comparables',sum(ok),'n_jgl_menor_gl',numel(ids), ...
    'indices_jgl_menor_gl',ids,'delta_pct',delta,'mensajes',{mensajes}, ...
    'criterio','MISMO_INDICE_BRUTO_CANONICO_SIN_CLAMP');
endfunction
