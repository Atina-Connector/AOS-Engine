function param = gibbs18_defaults(param)
% Defaults robustos para Gibbs Foundation v18.3. Unidades internas SI.
  if nargin < 1 || ~isstruct(param), param = struct(); end
  if ~isfield(param,'S_carrera'), param.S_carrera = 1.5; end
  if ~isfield(param,'N_velocidad'), param.N_velocidad = 6; end
  if ~isfield(param,'D_bomba'), param.D_bomba = 1500; end
  if ~isfield(param,'D_bomba_mm'), param.D_bomba_mm = 32; end
  if ~isfield(param,'WC'), param.WC = 0.5; end
  if ~isfield(param,'rho_o'), param.rho_o = 850; end
  if ~isfield(param,'rho_w'), param.rho_w = 1000; end
  if ~isfield(param,'P_wh'), param.P_wh = 10e5; end
  if ~isfield(param,'P_intake_min'), param.P_intake_min = 1e5; end
  if ~isfield(param,'eta_vol'), param.eta_vol = 0.85; end
  if ~isfield(param,'gibbs18_n_nodos'), param.gibbs18_n_nodos = 41; end
  if ~isfield(param,'gibbs18_n_ciclos'), param.gibbs18_n_ciclos = 5; end
  if ~isfield(param,'gibbs18_descartar_ciclos'), param.gibbs18_descartar_ciclos = 1; end
  if ~isfield(param,'gibbs18_puntos_por_ciclo'), param.gibbs18_puntos_por_ciclo = 720; end
  if ~isfield(param,'gibbs18_amortiguamiento'), param.gibbs18_amortiguamiento = 0.20; end
  if ~isfield(param,'gibbs18_E_Pa'), param.gibbs18_E_Pa = 207e9; end
  if ~isfield(param,'gibbs18_rho_rod'), param.gibbs18_rho_rod = 7850; end
  if ~isfield(param,'gibbs18_diam_varilla_mm'), param.gibbs18_diam_varilla_mm = 22.2; end
  if ~isfield(param,'gibbs18_llenado_bomba'), param.gibbs18_llenado_bomba = min(max(param.eta_vol,0.05),1.2); end
  if ~isfield(param,'gibbs18_bc_bomba'), param.gibbs18_bc_bomba = 'bomba_ideal_llena'; end

  % v18.3: modo automatico. Para baja velocidad usa modo cuasiestatico
  % estabilizado; para casos rapidos/profundos conserva solver dinamico foundation.
  if ~isfield(param,'gibbs18_modo_solver'), param.gibbs18_modo_solver = 'automatico'; end
  if ~isfield(param,'gibbs18_spm_limite_cuasiestatico'), param.gibbs18_spm_limite_cuasiestatico = 4.5; end
  if ~isfield(param,'gibbs18_valve_transition_frac'), param.gibbs18_valve_transition_frac = 0.006; end
  if ~isfield(param,'gibbs18_factor_inercia_superficie'), param.gibbs18_factor_inercia_superficie = 0.35; end
  if ~isfield(param,'gibbs18_factor_viscoso_superficie'), param.gibbs18_factor_viscoso_superficie = 0.00; end

  % Carga operativa de superficie.
  if ~isfield(param,'gibbs18_aplicar_offset_estatico'), param.gibbs18_aplicar_offset_estatico = 1; end
  if ~isfield(param,'gibbs18_surface_offset_manual_N'), param.gibbs18_surface_offset_manual_N = NaN; end
  if ~isfield(param,'gibbs18_buoyancy_factor_rods'), param.gibbs18_buoyancy_factor_rods = 0.87; end
  if ~isfield(param,'gibbs18_usar_carga_superficie_corregida'), param.gibbs18_usar_carga_superficie_corregida = 1; end

  param.gibbs18_version = 'AOS_BM_Gibbs_Foundation_v18_3_Octave';
end
