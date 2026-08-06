function p = mandriles_defaults(p)
% Valores editables del Diseno de Mandriles V2.
% Las variables mand_* pueden ser incluidas en el .aosdat.
  if nargin < 1 || ~isstruct(p)
    p = struct();
  endif

  p = setdef_local(p, 'mand_N_max', 0); % 0 = cantidad automatica
  p = setdef_local(p, 'mand_N_limite_tecnico', 12);
  p = setdef_local(p, 'mand_espaciado_min_m', 30);
  p = setdef_local(p, 'mand_dP_apertura_bar', 3.0);
  p = setdef_local(p, 'mand_dP_cierre_bar', 1.0);
  p = setdef_local(p, 'mand_paso_busqueda_m', 10);
  p = setdef_local(p, 'mand_paso_integracion_m', 5);

  % Propiedades y condiciones termodinamicas.
  p = setdef_local(p, 'mand_rho_kill', 1050);
  p = setdef_local(p, 'mand_rho_liq_kg_m3', NaN);
  p = setdef_local(p, 'mand_nivel_estatico_m', NaN);
  p = setdef_local(p, 'mand_T_sup_K', temperatura_sup_local(p));
  p = setdef_local(p, 'mand_grad_T_K_m', gradiente_T_local(p));
  p = setdef_local(p, 'mand_Z_gas', 0.90);
  p = setdef_local(p, 'mand_gamma_g', gamma_local(p));
  p = setdef_local(p, 'mand_kappa', 1.30);
  p = setdef_local(p, 'mand_Cd', 0.82);
  p = setdef_local(p, 'mand_Pstd_Pa', 101325);
  p = setdef_local(p, 'mand_Tstd_K', 288.15);
  p = setdef_local(p, 'mand_mu_gas_Pa_s', 1.2e-5);
  p = setdef_local(p, 'mand_mu_liq_Pa_s', 0.003);

  % Geometria. Se priorizan los valores canonicos de AOS cuando existen.
  p = setdef_local(p, 'mand_ID_tubing_m', leer_local(p, {'diam_tbg','ID_tubing_m'}, 0.062));
  p = setdef_local(p, 'mand_ID_casing_m', leer_local(p, {'ID_csg','ID_casing_m'}, 0.121));
  p = setdef_local(p, 'mand_OD_tubing_m', leer_local(p, {'OD_tbg','OD_tubing_m'}, 0.073));
  p = setdef_local(p, 'mand_rugosidad_m', leer_local(p, {'rugosidad'}, 4.6e-5));

  % Modelo de tubing durante unloading.
  p = setdef_local(p, 'mand_modelo_presion', 'COMPRESIBLE_NUMERICO');
  p = setdef_local(p, 'mand_modelo_tubing', 'HOMOGENEO_COMPRESIBLE_POR_TRAMOS');
  p = setdef_local(p, 'mand_factor_holdup', 1.15);
  p = setdef_local(p, 'mand_Ql_diseno_m3d', NaN);
  p = setdef_local(p, 'mand_fraccion_Qg_unloading', 0.55);
  p = setdef_local(p, 'mand_fraccion_Ql_unloading', 0.50);
  p = setdef_local(p, 'mand_Ql_min_unloading_m3d', 1.0);
  p = setdef_local(p, 'mand_Qg_unloading_m3d', NaN);
  p = setdef_local(p, 'mand_grad_aliviado_bar_m', 0.020); % solo compatibilidad/reporte

  % Galeria.
  p = setdef_local(p, 'mand_rating_bar', 350);
  p = setdef_local(p, 'mand_puertos_mm', [2 2.5 3 3.5 4 4.5 5 5.5 6 7 8 9 10 12]);
  p = setdef_local(p, 'mand_usar_galeria_generica', true);
endfunction

function s = setdef_local(s, n, v)
  if ~isfield(s, n) || isempty(s.(n))
    s.(n) = v;
  endif
endfunction

function v = leer_local(s, nombres, defecto)
  v = defecto;
  for i = 1:numel(nombres)
    n = nombres{i};
    if isfield(s, n)
      x = s.(n);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
        v = x(1);
        return;
      endif
    endif
  endfor
endfunction

function g = gamma_local(p)
  g = leer_local(p, {'gamma_g','gas_gravity','SG_gas'}, 0.70);
endfunction

function T = temperatura_sup_local(p)
  T = leer_local(p, {'T_sup'}, 20);
  if T < 200
    T = T + 273.15;
  endif
endfunction

function grad = gradiente_T_local(p)
  Ts = temperatura_sup_local(p);
  Tf = leer_local(p, {'T_fondo'}, NaN);
  D = leer_local(p, {'D_res','D_packer','D_iny'}, NaN);
  if isfinite(Tf) && Tf < 200
    Tf = Tf + 273.15;
  endif
  if isfinite(Tf) && isfinite(D) && D > 0
    grad = max((Tf - Ts) / D, 0);
  else
    grad = 0.025;
  endif
endfunction
