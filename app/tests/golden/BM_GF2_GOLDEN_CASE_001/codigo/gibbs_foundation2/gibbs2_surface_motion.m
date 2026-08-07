function [u, v] = gibbs2_surface_motion(t, param)
  S = max(leer_num(param,'S_carrera',1.5), 0);
  spm = max(leer_num(param,'N_velocidad',6), 0.1);
  T = 60/spm;
  w = 2*pi/T;
  u = 0.5*S*(1 - cos(w*t));
  v = 0.5*S*w*sin(w*t);
end
function v = leer_num(s,c,d)
  v = d; if isstruct(s)&&isfield(s,c), tmp=s.(c); if isnumeric(tmp)&&~isempty(tmp)&&isfinite(tmp(1)), v=tmp(1); end, end
end
