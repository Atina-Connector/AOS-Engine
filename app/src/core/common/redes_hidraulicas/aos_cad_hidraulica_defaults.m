function cfg = aos_cad_hidraulica_defaults(modelo)
% AOS_CAD_HIDRAULICA_DEFAULTS Configuracion efectiva del solver DXF DEV1.
% Todos los valores pueden editarse en el .aoscad antes de recalcular.
  if nargin < 1, modelo = struct(); endif

  cfg = struct();
  cfg.version = 'AOSCAD-HIDRAULICA-0.0.1-DEV1';
  cfg.estado = 'DESARROLLO_NO_VALIDADO';
  cfg.motor_objetivo = 'GNU_OCTAVE';
  cfg.modelo = 'AUTOMATICO';
  cfg.modelo_multifasico = 'MULTIFASICO_HB';
  cfg.g = 9.81;
  cfg.P_min_Pa = 101325;
  cfg.tol_presion_Pa = 10;
  cfg.max_iter_presion = 60;
  cfg.tol_balance_m3s = 1e-10;
  cfg.permitir_defaults = true;
  cfg.rechazar_lazos = false;
  cfg.rechazar_desconectados = true;
  cfg.signo_bc_caudal = 'POSITIVO_ES_DEMANDA';
  % Parametros del solver de lazos Kirchhoff (Sprint 4)
  cfg.max_iter_lazo = 60;
  cfg.tol_lazo_Pa = 10;
  cfg.tol_dq_m3s = 1e-9;
  cfg.q_init_lazo_m3s = 1e-4;
  cfg.dq_derivada_m3s = 1e-7;
  cfg.metodo_lazo = 'NEWTON';
  cfg.amortiguamiento_lazo_min = 0.05;

  cfg.fluido = struct();
  cfg.fluido.id = 'FLUIDO_001';
  cfg.fluido.nombre = 'FLUIDO_DEFAULT_AOSCAD';
  cfg.fluido.API = 35;
  cfg.fluido.WC = 0.50;
  cfg.fluido.GLR = 0;
  cfg.fluido.gamma_g = 0.70;
  cfg.fluido.rho_o = 850;
  cfg.fluido.rho_w = 1000;
  cfg.fluido.rho_g_std = 0.8;
  cfg.fluido.mu_l_Pas = 1.0e-3;
  cfg.fluido.mu_g_Pas = 1.5e-5;
  cfg.fluido.T_sup_K = 298.15;
  cfg.fluido.T_fondo_K = 298.15;
  cfg.fluido.P_std_Pa = 101325;
  cfg.fluido.T_std_K = 288.15;

  if isstruct(modelo) && isfield(modelo, 'simulacion') && ...
      isstruct(modelo.simulacion) && ...
      isfield(modelo.simulacion, 'configuracion_hidraulica') && ...
      isstruct(modelo.simulacion.configuracion_hidraulica)
    cfg = merge_struct_local(cfg, modelo.simulacion.configuracion_hidraulica);
  endif

  cfg = aos_cad_hidraulica_extraer_config_dxf(modelo, cfg);
  cfg.fluido.WC = max(0, min(1, cfg.fluido.WC));
  cfg.fluido.gamma_g = max(cfg.fluido.gamma_g, 0.1);
  cfg.P_min_Pa = max(cfg.P_min_Pa, 1000);
endfunction

function out = merge_struct_local(base, nuevo)
  out = base;
  if ~isstruct(nuevo), return; endif
  fn = fieldnames(nuevo);
  for i = 1:numel(fn)
    k = fn{i};
    if isstruct(nuevo.(k)) && isfield(out, k) && isstruct(out.(k))
      out.(k) = merge_struct_local(out.(k), nuevo.(k));
    else
      out.(k) = nuevo.(k);
    endif
  endfor
endfunction
