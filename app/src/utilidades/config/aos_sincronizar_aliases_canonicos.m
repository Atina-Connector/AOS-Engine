function p = aos_sincronizar_aliases_canonicos(p)
% Publica aliases y estructuras anidadas desde los campos canonicos activos.
% La direccion es siempre canonico -> alias. Nunca reinterpreta un alias para
% sobrescribir una edicion de menu, solver o sensibilidad.
% Compatible con GNU Octave.

  if nargin < 1 || ~isstruct(p), p = struct(); end
  grupos = {'pozo','tubing','casing','fluidos','gl','jgl','bes','bm','int1'};
  for i = 1:length(grupos)
    g = grupos{i};
    if ~isfield(p,g) || ~isstruct(p.(g)), p.(g) = struct(); end
  end

  p = sync_presion(p, 'P_res');
  p = sync_presion(p, 'P_wh');
  p = sync_presion(p, 'P_iny_sup');
  p = sync_presion(p, 'P_b');
  p = sync_presion(p, 'P_intake_min');
  p = sync_presion(p, 'P_sep');

  if numero(p,'IP')
    p.IP_m3_d_bar = p.IP * 86400 * 1e5;
    p.IP_m3dbar = p.IP_m3_d_bar;
  end
  if numero(p,'T_sup'), p.T_sup_C = p.T_sup - 273.15; end
  if numero(p,'T_fondo'), p.T_fondo_C = p.T_fondo - 273.15; end

  if numero(p,'rho_o'), p.rho_o_kg_m3 = p.rho_o; end
  if numero(p,'rho_w'), p.rho_w_kg_m3 = p.rho_w; end
  if numero(p,'rho_g_std'), p.rho_g_std_kg_m3 = p.rho_g_std; end
  if numero(p,'diam_tbg')
    p.ID_tubing_m = p.diam_tbg;
    p.tubing.ID = p.diam_tbg;
    p.tubing.ID_tubing_m = p.diam_tbg;
  end
  if numero(p,'ID_csg')
    p.ID_casing_m = p.ID_csg;
    p.casing.ID = p.ID_csg;
    p.casing.ID_casing_m = p.ID_csg;
  end
  if numero(p,'rugosidad')
    p.rugosidad_m = p.rugosidad;
    p.tubing.rugosidad_m = p.rugosidad;
  end

  if numero(p,'P_res'), p.int1.P_res = p.P_res; end
  if numero(p,'IP'), p.int1.IP = p.IP; end
  if numero(p,'WC'), p.fluidos.WC = p.WC; end
  if numero(p,'GLR'), p.fluidos.GLR = p.GLR; end
  if numero(p,'API'), p.fluidos.API = p.API; end
  if numero(p,'gamma_g'), p.fluidos.gamma_g = p.gamma_g; end
  if numero(p,'rho_o'), p.fluidos.rho_o = p.rho_o; end
  if numero(p,'rho_w'), p.fluidos.rho_w = p.rho_w; end
  if numero(p,'rho_g_std'), p.fluidos.rho_g_std = p.rho_g_std; end
  if numero(p,'P_b'), p.fluidos.P_b = p.P_b; end

  % Profundidades GL/JGL. No tocar D_bomba.
  if numero(p,'D_iny')
    d = p.D_iny;
    p.D_iny_m = d; p.D_levantamiento = d; p.D_levantamiento_m = d;
    p.D_valvula = d; p.D_valvula_m = d; p.D_eductor = d; p.D_eductor_m = d;
    p.gl.D_iny = d; p.gl.D_iny_m = d; p.gl.D_valvula = d; p.gl.D_valvula_m = d;
    p.jgl.D_iny = d; p.jgl.D_iny_m = d; p.jgl.D_eductor = d; p.jgl.D_eductor_m = d;
    p.pozo.D_iny = d; p.pozo.D_iny_m = d;
  end

  % Profundidades BES/BM. No tocar D_iny.
  if numero(p,'D_bomba')
    d = p.D_bomba;
    p.D_bomba_m = d;
    p.bes.D_bomba = d; p.bes.D_bomba_m = d;
    p.bm.D_bomba = d; p.bm.D_bomba_m = d;
  end
  if numero(p,'D_intake')
    p.D_intake_m = p.D_intake;
    p.bes.D_intake = p.D_intake; p.bes.D_intake_m = p.D_intake;
  elseif numero(p,'D_bomba')
    p.bes.D_intake = p.D_bomba; p.bes.D_intake_m = p.D_bomba;
  end
  if numero(p,'D_res'), p.D_res_m = p.D_res; p.pozo.D_res = p.D_res; p.pozo.D_res_m = p.D_res; end

  if numero(p,'P_iny_sup')
    p.gl.P_iny_sup = p.P_iny_sup;
    p.gl.P_iny_sup_bar = p.P_iny_sup/1e5;
    p.jgl.P_iny_sup = p.P_iny_sup;
  end

  if isfield(p,'Q_iny') && numero(p,'Q_iny')
    q = max(p.Q_iny,0);
    qs = q*86400;
    qm = qs/0.028316846592/1e6;
    p.Qiny = q; p.Qiny_plot = q;
    p.Qiny_sim_Sm3_d = qs; p.Qiny_Sm3_d = qs; p.Q_iny_Sm3_d = qs;
    p.Qiny_sim_MMscfd = qm; p.Qiny_MMscfd = qm; p.Q_iny_MMscfd = qm;
    p.gl.Q_iny = q; p.gl.Qiny = q; p.gl.Qiny_Sm3_d = qs; p.gl.Q_iny_Sm3_d = qs;
    p.jgl.Q_iny = q; p.jgl.Qiny = q; p.jgl.Qiny_Sm3_d = qs; p.jgl.Q_iny_Sm3_d = qs;
    if isfield(p,'qiny_modo')
      p.gl.qiny_modo = p.qiny_modo; p.jgl.qiny_modo = p.qiny_modo;
    end
  end

  if numero(p,'A_n'), p.A_n_m2 = p.A_n; p.jgl.A_n = p.A_n; end
  if numero(p,'d_t'), p.d_t_m = p.d_t; p.jgl.d_t = p.d_t; end

  % Parametros propios de BES/BM usados por reportes y sensibilidades.
  bes_campos = {'frecuencia','frecuencia_base','num_etapas','curva_bomba_file', ...
                'T_max_motor','eficiencia_motor','cp_fluido','velocidad_min_refrig', ...
                'voltaje_motor','IR_base','factor_envejecimiento','mu_o'};
  bm_campos = {'D_bomba_mm','S_carrera','N_velocidad','eta_vol','eta_mecanica_BM', ...
               'P_intake_min','tipo_unidad','modelo_unidad_BM','material_varillas', ...
               'tuberia_anclada','usar_gibbs_BM'};
  p = copiar_campos(p, 'bes', bes_campos);
  p = copiar_campos(p, 'bm', bm_campos);
end

function p = sync_presion(p, campo)
  if numero(p,campo)
    p.([campo '_bar']) = p.(campo)/1e5;
    p.([campo '_psi']) = p.(campo)/6894.757293168;
  end
end

function tf = numero(s,c)
  tf = isstruct(s) && isfield(s,c) && isnumeric(s.(c)) && isscalar(s.(c)) && isfinite(s.(c));
end

function p = copiar_campos(p, grupo, campos)
  for i = 1:length(campos)
    c = campos{i};
    if isfield(p,c), p.(grupo).(c) = p.(c); end
  end
end
