function Q_erosion = calcular_erosion_punzados(geol, intervalos)
% Caudal critico por erosion usando solamente intervalos activos.
  if nargin<1||~isstruct(geol),geol=struct();endif
  if nargin<2||isempty(intervalos)
    intervalos=aos_obtener_punzados_activos(geol,struct());
  else
    [intervalos,~]=aos_punzados_normalizar(intervalos);
    if ~isempty(intervalos.tramos)
      intervalos.tramos=intervalos.tramos([intervalos.tramos.activo]);
    endif
  endif
  if isempty(intervalos.tramos),Q_erosion=0;return;endif

  C=120;
  rho_l=850;
  if isfield(geol,'rho_petroleo')
    [rho_l,ok]=aos_numero_seguro(geol.rho_petroleo,850);if ~ok,rho_l=850;endif
  endif
  rho_lbm=max(rho_l*0.062428,eps);
  v_eros_ms=(C/sqrt(rho_lbm))*0.3048;

  Q_erosion=0;
  for i=1:numel(intervalos.tramos)
    t=intervalos.tramos(i);
    espesor=max(t.MD_hasta-t.MD_desde,0);
    N=max(round(espesor*max(t.densidad_tpm,0)),0);
    d=max(t.diametro_punzado_m,0);
    area=pi*(d/2)^2;
    Q_erosion=Q_erosion+N*area*v_eros_ms;
  endfor
endfunction
