function p = jgl_defaults(p)
% Defaults comunes AOS 0.0.12 JGL. Compatible con GNU Octave.
% Debe llamarse antes de leer cualquier campo jgl_* desde menus o solvers.
  if nargin < 1 || ~isstruct(p), p = struct(); end
  p = setdef(p,'jgl_modo','automatico');
  p = setdef(p,'jgl_tol_Q_rel',0.005);
  p = setdef(p,'jgl_tol_P_bar',0.25);
  p = setdef(p,'jgl_tol_dP_bar',0.25);
  p = setdef(p,'jgl_min_iter',3);
  p = setdef(p,'jgl_max_iter',10);
  p = setdef(p,'jgl_alpha',0.50);
  p = setdef(p,'jgl_eta_transfer',0.35);
  p = setdef(p,'jgl_factor_gas_liquido',0.20);
  p = setdef(p,'jgl_geometria_modo','derivada');
  % SENS-GLJGL-03: AUTO_ESTRICTO no deriva presion en forma oculta.
  % Las sensibilidades fijan DERIVADA_DESDE_QINY mediante un menu visible.
  p = setdef(p,'jgl_condicion_motriz_modo','AUTO_ESTRICTO');
  p = setdef(p,'jgl_presion_sup_estado','NO_INFORMADA');
  p = setdef(p,'jgl_tol_presion_factibilidad_bar',0.10);
  p = setdef(p,'jgl_confianza_umbral_alta',80);
  p = setdef(p,'jgl_confianza_umbral_media',55);
  p = setdef(p,'WC',0.5);
  p = setdef(p,'GLR',0);
  p = setdef(p,'rho_g_std',0.8);
  p = setdef(p,'rho_o',850);
  p = setdef(p,'rho_w',1000);
  p = setdef(p,'P_wh',10e5);
  p = setdef(p,'P_iny_sup',0);
  p = setdef(p,'T_sup',298.15);
  p = setdef(p,'T_fondo',358.15);
  if ~isfield(p,'D_iny') || isempty(p.D_iny)
    if isfield(p,'D_levantamiento') && ~isempty(p.D_levantamiento)
      p.D_iny=p.D_levantamiento;
    elseif isfield(p,'D_valvula') && ~isempty(p.D_valvula)
      p.D_iny=p.D_valvula;
    elseif isfield(p,'D_eductor') && ~isempty(p.D_eductor)
      p.D_iny=p.D_eductor;
    elseif isfield(p,'D_bomba') && ~isempty(p.D_bomba)
      % Compatibilidad de lectura legacy: no se escribe D_bomba desde D_iny.
      p.D_iny=p.D_bomba;
    else
      p.D_iny=1500;
    end
  end
  p = jgl_actualizar_geometria(p, p.jgl_geometria_modo);
end
function s=setdef(s,n,v), if ~isfield(s,n)||isempty(s.(n)), s.(n)=v; end, end
