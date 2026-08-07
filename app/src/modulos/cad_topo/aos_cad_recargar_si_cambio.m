function ok = aos_cad_recargar_si_cambio(forzar, silencioso)
% AOS_CAD_RECARGAR_SI_CAMBIO Reimporta DXF/STEP si cambio mtime (o si forzar).
% Delega en aos_cad_sincronizar_2d_3d para invalidar y reconstruir de forma
% coherente (nunca deja geometria nueva con resultados viejos).
  ok = false;
  if nargin < 1, forzar = false; endif
  if nargin < 2, silencioso = false; endif

  opts = struct();
  opts.forzar = logical(forzar);
  opts.silencioso = logical(silencioso);
  opts.reconstruir_topologia = true;
  opts.reconstruir_vinculo = true;
  opts.reconstruir_escena = true;
  opts.incluir_puertos = false;

  [ok_sync, reporte] = aos_cad_sincronizar_2d_3d(opts);
  if ~ok_sync
    ok = false;
    return;
  endif
  % Compatibilidad menu: true si hubo fuentes cambiadas (o forzar con accion).
  hubo = false;
  if isstruct(reporte) && isfield(reporte, 'fuentes_cambiadas') ...
      && ~isempty(reporte.fuentes_cambiadas)
    hubo = true;
  endif
  ok = hubo;
endfunction
