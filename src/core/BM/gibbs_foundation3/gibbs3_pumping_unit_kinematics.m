function [u, v, a, theta] = gibbs3_pumping_unit_kinematics(t, p)
% GIBBS3_PUMPING_UNIT_KINEMATICS Cinematica del aparato de bombeo.
% Los perfiles representativos no reemplazan la geometria certificada del
% fabricante. El modelo linkage_conventional usa una geometria explicita.

  persistent cache_key cache
  key = clave_perfil(p);
  if isempty(cache_key) || ~strcmp(cache_key, key)
    cache = construir_perfil(p);
    cache_key = key;
  end

  omega = 2*pi*p.N_velocidad/60;
  theta = mod(omega*t + p.pumping_unit_crank_phase_rad, 2*pi);
  u = interp1(cache.theta, cache.u_m, theta, 'linear');
  du_dtheta = interp1(cache.theta, cache.du_dtheta_m, theta, 'linear');
  d2u_dtheta2 = interp1(cache.theta, cache.d2u_dtheta2_m, theta, 'linear');
  v = du_dtheta * omega;
  a = d2u_dtheta2 * omega^2;
end

function key = clave_perfil(p)
  key = sprintf('%s|%.12g|%.12g|%.12g|%.12g|%.12g|%.12g|%.12g|%.12g|%d|%.12g', ...
    lower(p.pumping_unit_kinematic_model), p.S_carrera, ...
    p.pumping_unit_asymmetry, p.pumping_unit_crank_radius_m, ...
    p.pumping_unit_pitman_length_m, p.pumping_unit_beam_rear_arm_m, ...
    p.pumping_unit_beam_front_arm_m, p.pumping_unit_crank_center_x_m, ...
    p.pumping_unit_crank_center_y_m, round(p.pumping_unit_linkage_branch), ...
    p.pumping_unit_profile_shape);
end

function perfil = construir_perfil(p)
  n = 4096;
  th = (0:n-1)' * (2*pi/n);
  modelo = lower(strtrim(p.pumping_unit_kinematic_model));

  switch modelo
    case 'sinusoidal'
      raw = 0.5*(1-cos(th));
    case 'perfil_convencional_representativo'
      raw = 0.5*(1-cos(th)) + 0.10*sin(2*th)/8;
    case 'perfil_markii_representativo'
      raw = 0.5*(1-cos(th)) + 0.38*sin(2*th)/8;
    case 'perfil_reverse_mark_representativo'
      raw = 0.5*(1-cos(th)) - 0.34*sin(2*th)/8;
    case 'perfil_balanceado_aire'
      raw = 0.5*(1-cos(th)) + 0.06*sin(2*th)/8;
    case 'perfil_carrera_larga'
      raw = perfil_suave(th, max(p.pumping_unit_profile_shape, 1.0));
    case 'perfil_hidraulico_suave'
      raw = perfil_suave(th, max(p.pumping_unit_profile_shape, 1.4));
    case 'linkage_conventional'
      raw = perfil_linkage(th, p);
    otherwise
      error('Modelo cinematico de aparato no reconocido: %s', ...
        p.pumping_unit_kinematic_model);
  end

  span = max(raw)-min(raw);
  if ~all(isfinite(raw)) || span <= eps
    error('La geometria del aparato no produce una carrera valida.');
  end
  u = p.S_carrera * (raw-min(raw)) / span;
  dth = 2*pi/n;
  du = (circshift(u,-1)-circshift(u,1))/(2*dth);
  d2u = (circshift(u,-1)-2*u+circshift(u,1))/(dth^2);

  perfil = struct();
  perfil.theta = [th; 2*pi];
  perfil.u_m = [u; u(1)];
  perfil.du_dtheta_m = [du; du(1)];
  perfil.d2u_dtheta2_m = [d2u; d2u(1)];
end

function raw = perfil_suave(th, forma)
  raw = zeros(size(th));
  subida = th <= pi;
  r = th(subida)/pi;
  s = 3*r.^2-2*r.^3;
  num = s.^forma;
  den = num + (1-s).^forma;
  den(den < eps) = eps;
  s = num ./ den;
  raw(subida) = s;
  q = (th(~subida)-pi)/pi;
  sd = 3*q.^2-2*q.^3;
  numd = sd.^forma;
  dend = numd + (1-sd).^forma;
  dend(dend < eps) = eps;
  sd = numd ./ dend;
  raw(~subida) = 1-sd;
end

function raw = perfil_linkage(th, p)
  r = p.pumping_unit_crank_radius_m;
  lp = p.pumping_unit_pitman_length_m;
  rb = p.pumping_unit_beam_rear_arm_m;
  rf = p.pumping_unit_beam_front_arm_m;
  cx = p.pumping_unit_crank_center_x_m;
  cy = p.pumping_unit_crank_center_y_m;
  rama = sign(p.pumping_unit_linkage_branch);
  if rama == 0, rama = 1; end

  raw = zeros(size(th));
  for k = 1:numel(th)
    px = cx + r*cos(th(k));
    py = cy + r*sin(th(k));
    d = hypot(px, py);
    if d <= eps || d > rb+lp || d < abs(rb-lp)
      error('Geometria linkage incompatible en angulo %.3f rad.', th(k));
    end
    aa = (rb^2-lp^2+d^2)/(2*d);
    hh2 = rb^2-aa^2;
    if hh2 < -1e-10
      error('Geometria linkage sin interseccion real.');
    end
    hh = sqrt(max(hh2,0));
    bx0 = aa*px/d;
    by0 = aa*py/d;
    bx = bx0 + rama*hh*(-py/d);
    by = by0 + rama*hh*( px/d);
    raw(k) = -(rf/rb)*by;
  end
end
