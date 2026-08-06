function cfg = aos_aplicar_aliases_aosdat(cfg)
% Normaliza aliases del formato .aosdat a los campos internos de AOS.
% La interfaz usa bar, m, m3/d y Sm3/d; el nucleo conserva Pa y m3/s.

  if nargin < 1 || ~isstruct(cfg), cfg = struct(); end

  % Promover aliases de secciones estructuradas. El importador conserva
  % [POZO], [FLUIDOS], [GL], [TUBING], [CASING] e [INT1] sin perder datos;
  % aqui se publican los campos canonicos que usan los motores 0.0.11.
  if isfield(cfg, 'int1') && isstruct(cfg.int1)
      cfg = promover(cfg, cfg.int1, 'P_res', {'P_res'});
      cfg = promover(cfg, cfg.int1, 'P_res_bar', {'P_res_bar'});
      cfg = promover(cfg, cfg.int1, 'IP', {'IP'});
      cfg = promover(cfg, cfg.int1, 'IP_m3_d_bar', {'IP_m3_d_bar','IP_m3dbar'});
  end
  if isfield(cfg, 'pozo') && isstruct(cfg.pozo)
      cfg = promover(cfg, cfg.pozo, 'D_res', {'D_res'});
      cfg = promover(cfg, cfg.pozo, 'D_res_m', {'D_res_m','D_midperf_m'});
      cfg = promover(cfg, cfg.pozo, 'D_iny_m', {'D_iny_m','D_valvula_m','D_eductor_m'});
      cfg = promover(cfg, cfg.pozo, 'D_packer', {'D_packer','prof_packer_m'});
  end
  if isfield(cfg, 'fluidos') && isstruct(cfg.fluidos)
      nombres = {'WC','GLR','API','gamma_g','rho_o','rho_w','rho_g_std','P_b','P_b_bar','P_b_psi','T_sup_C','T_fondo_C'};
      for ii = 1:length(nombres), cfg = promover(cfg, cfg.fluidos, nombres{ii}, {nombres{ii}}); end
  end
  if isfield(cfg, 'gl') && isstruct(cfg.gl)
      cfg = promover(cfg, cfg.gl, 'P_iny_sup', {'P_iny_sup'});
      cfg = promover(cfg, cfg.gl, 'P_iny_sup_bar', {'P_iny_sup_bar','P_iny_bar'});
      cfg = promover(cfg, cfg.gl, 'D_iny_m', {'D_iny_m','D_valvula_m','D_valvula'});
      cfg = promover(cfg, cfg.gl, 'Q_iny', {'Q_iny'});
      cfg = promover(cfg, cfg.gl, 'Qiny_Sm3_d', {'Qiny_Sm3_d','Q_iny_Sm3_d'});
  end
  if isfield(cfg, 'tubing') && isstruct(cfg.tubing)
      cfg = promover(cfg, cfg.tubing, 'ID_tubing_m', {'ID_tubing_m','ID_tubing','ID'});
      cfg = promover(cfg, cfg.tubing, 'OD_tbg', {'OD_tbg','OD'});
      cfg = promover(cfg, cfg.tubing, 'rugosidad_m', {'rugosidad_m','rugosidad'});
  end
  if isfield(cfg, 'casing') && isstruct(cfg.casing)
      cfg = promover(cfg, cfg.casing, 'ID_casing_m', {'ID_casing_m','ID_casing','ID'});
  end

  % Promocion generica sin pisar campos canonicos. Esto permite que nuevos
  % parametros escalares de [POZO], [FLUIDOS], [GL], [JGL], [BES], [BM] e
  % [INT1] queden disponibles automaticamente para los modulos actuales,
  % mientras la estructura original se conserva completa.
  grupos_promocion = {'pozo','fluidos','gl','jgl','bes','bm','int1','tubing','casing'};
  for ig = 1:length(grupos_promocion)
      g = grupos_promocion{ig};
      if isfield(cfg, g) && isstruct(cfg.(g))
          cfg = promover_escalares(cfg, cfg.(g));
      end
  end

  % Presiones: los campos explicitos en bar tienen prioridad.
  cfg = set_pa_desde_bar(cfg, 'P_res', {'P_res_bar'});
  cfg = set_pa_desde_bar(cfg, 'P_wh', {'P_wh_bar'});
  cfg = set_pa_desde_bar(cfg, 'P_iny_sup', {'P_iny_sup_bar','P_iny_bar'});
  cfg = set_pa_desde_bar(cfg, 'P_b', {'P_b_bar'});
  cfg = set_pa_desde_bar(cfg, 'P_intake_min', {'P_intake_min_bar','P_succion_min_bar'});
  cfg = set_pa_desde_bar(cfg, 'P_sep', {'P_sep_bar'});

  % Compatibilidad de lectura: si el archivo solo trae referencias
  % imperiales, convertirlas. Los campos metricos en bar siempre tienen
  % prioridad y son los que AOS exporta en 0.0.11.
  cfg = set_pa_desde_psi_si_falta_bar(cfg, 'P_res', {'P_res_bar'}, {'P_res_psi','P_res_psig'});
  cfg = set_pa_desde_psi_si_falta_bar(cfg, 'P_wh', {'P_wh_bar'}, {'P_wh_psi','P_wh_psig'});
  cfg = set_pa_desde_psi_si_falta_bar(cfg, 'P_iny_sup', {'P_iny_sup_bar','P_iny_bar'}, {'P_iny_sup_psi','P_iny_sup_psig','P_iny_psi','P_iny_psig'});
  cfg = set_pa_desde_psi_si_falta_bar(cfg, 'P_b', {'P_b_bar'}, {'P_b_psi','P_b_psig'});
  cfg = set_pa_desde_psi_si_falta_bar(cfg, 'P_intake_min', {'P_intake_min_bar','P_succion_min_bar'}, {'P_intake_min_psi','P_succion_min_psi'});
  cfg = set_pa_desde_psi_si_falta_bar(cfg, 'P_sep', {'P_sep_bar'}, {'P_sep_psi','P_sep_psig'});

  % Productividad: m3/d/bar -> m3/s/Pa.
  [v, ok] = primer_numero(cfg, {'IP_m3_d_bar','IP_m3dbar','IP_m3_dia_bar'});
  if ok, cfg.IP = v / 86400 / 1e5; end

  % Alias historico usado por las primeras versiones de calibracion.
  if (~isfield(cfg, 'factor_IP_residual') || isempty(cfg.factor_IP_residual))
      [v, ok] = primer_numero(cfg, {'factor_declinacion','factor_IP','factor_ip_residual'});
      if ok, cfg.factor_IP_residual = v; end
  end

  % Temperaturas de usuario en grados C -> K internos.
  [v, ok] = primer_numero(cfg, {'T_sup_C','T_superficie_C'});
  if ok, cfg.T_sup = v + 273.15; end
  [v, ok] = primer_numero(cfg, {'T_fondo_C','T_res_C'});
  if ok, cfg.T_fondo = v + 273.15; end

  % Densidades y diametros.
  cfg = copiar_numero(cfg, 'rho_o', {'rho_o_kg_m3','rho_petroleo_kg_m3'});
  cfg = copiar_numero(cfg, 'rho_w', {'rho_w_kg_m3','rho_agua_kg_m3'});
  cfg = copiar_numero(cfg, 'rho_g_std', {'rho_g_std_kg_m3'});
  cfg = copiar_numero(cfg, 'diam_tbg', {'ID_tubing_m','ID_tubing','diam_tbg_m'});
  cfg = copiar_numero(cfg, 'ID_csg', {'ID_casing_m','ID_casing','diam_casing_m'});
  cfg = copiar_numero(cfg, 'rugosidad', {'rugosidad_m'});

  % Profundidades y significado operativo.
  [v, ok] = primer_numero(cfg, {'D_iny','D_iny_m','D_levantamiento','D_levantamiento_m','D_valvula','D_valvula_m','D_eductor','D_eductor_m'});
  if ~ok && isfield(cfg, 'estado_mecanico') && isstruct(cfg.estado_mecanico)
      [v, ok] = primer_numero(cfg.estado_mecanico, {'prof_inyeccion_activa_m','prof_valvula_m','prof_eductor_m'});
  end
  if ok
      cfg.D_iny = v;
      cfg.D_levantamiento = v;
      cfg.D_iny_m = v;
      cfg.D_levantamiento_m = v;
      cfg.D_valvula = v;
      cfg.D_valvula_m = v;
      cfg.D_eductor = v;
      cfg.D_eductor_m = v;
  end
  % D_iny y D_bomba son variables operativas diferentes. La compatibilidad
  % legacy, cuando sea necesaria, se decide por modulo en el normalizador.

  [vb, okb] = primer_numero(cfg, {'D_bomba','D_bomba_m','D_intake','D_intake_m'});
  if ~okb && isfield(cfg,'bes') && isstruct(cfg.bes)
      [vb, okb] = primer_numero(cfg.bes, {'D_bomba','D_bomba_m','D_intake','D_intake_m'});
  end
  if ~okb && isfield(cfg,'bm') && isstruct(cfg.bm)
      [vb, okb] = primer_numero(cfg.bm, {'D_bomba','D_bomba_m'});
  end
  if okb
      cfg.D_bomba = vb;
      cfg.D_bomba_m = vb;
  end

  cfg = copiar_numero(cfg, 'D_res', {'D_res_m','D_midperf_m'});
  cfg = copiar_numero(cfg, 'D_midperf', {'D_midperf_m'});
  cfg = copiar_numero(cfg, 'D_punzados_tope', {'D_punzados_tope_m'});
  cfg = copiar_numero(cfg, 'D_punzados_base', {'D_punzados_base_m'});

  if isfield(cfg, 'estado_mecanico') && isstruct(cfg.estado_mecanico)
      cfg = copiar_numero_desde(cfg, cfg.estado_mecanico, 'D_packer', {'prof_packer_m'});
      cfg = copiar_numero_desde(cfg, cfg.estado_mecanico, 'D_midperf', {'prof_midperf_m'});
      cfg = copiar_numero_desde(cfg, cfg.estado_mecanico, 'D_punzados_tope', {'prof_punzado_tope_m'});
      cfg = copiar_numero_desde(cfg, cfg.estado_mecanico, 'D_punzados_base', {'prof_punzado_base_m'});
      if (~isfield(cfg, 'D_res') || ~es_numero(cfg.D_res)) && isfield(cfg, 'D_midperf')
          cfg.D_res = cfg.D_midperf;
      end
  end

  % Caudal de gas. AOS usa Sm3/d en entrada/salida y m3/s estandar internamente.
  % IMPORTANTE GNU Octave / AOS 0.0.12:
  % - qiny_modo='fijo' tiene precedencia absoluta para cualquier valor ingresado, incluido 0.
  % - qiny_modo='automatico' impide que aliases historicos del .aosdat
  %   vuelvan a imponer el caudal configurado.
  % Esto evita que cualquier alias historico pise la seleccion fija del usuario.
  modo_qiny = '';
  if isfield(cfg, 'qiny_modo') && ischar(cfg.qiny_modo)
      modo_qiny = lower(strtrim(cfg.qiny_modo));
  end

  if strcmp(modo_qiny, 'fijo') && isfield(cfg, 'Q_iny') && es_numero(cfg.Q_iny)
      cfg.Q_iny = max(cfg.Q_iny, 0);
      cfg.Qiny_Sm3_d = cfg.Q_iny * 86400;
      cfg.Q_iny_Sm3_d = cfg.Qiny_Sm3_d;
      cfg.Qiny_MMscfd = cfg.Q_iny * 86400 / 0.028316846592 / 1e6;
  elseif strcmp(modo_qiny, 'automatico')
      % No importar ningun alias de caudal fijo. El motor calculara Qiny.
      if isfield(cfg, 'Q_iny'), cfg = rmfield(cfg, 'Q_iny'); end
  else
      [q_sm3d, ok] = primer_numero(cfg, {'Qiny_sim_Sm3_d','Qiny_Sm3_d','Q_iny_Sm3_d','Qiny_sm3d','Qiny_ref_Sm3_d'});
      if ok
          cfg.Q_iny = q_sm3d / 86400;
          cfg.Qiny_Sm3_d = q_sm3d;
      else
          [q_mmscfd, ok2] = primer_numero(cfg, {'Qiny_sim_MMscfd','Qiny_MMscfd','Q_iny_MMscfd','Qiny_ref_MMscfd'});
          if ok2
              cfg.Q_iny = q_mmscfd * 1e6 * 0.028316846592 / 86400;
              cfg.Qiny_Sm3_d = cfg.Q_iny * 86400;
          end
      end
  end

  % Campos de geometria con unidades explicitas.
  cfg = copiar_numero(cfg, 'A_n', {'A_n_m2'});
  cfg = copiar_numero(cfg, 'd_t', {'d_t_m'});

  % Canonicos de nombres y datos del pozo.
  if isfield(cfg, 'pozo') && ischar(cfg.pozo) && ~isfield(cfg, 'nombre_pozo')
      cfg.nombre_pozo = cfg.pozo;
  end
  if isfield(cfg, 'nombre') && ischar(cfg.nombre) && ~isfield(cfg, 'nombre_pozo')
      cfg.nombre_pozo = cfg.nombre;
  end

  % Presion de burbuja sin campo de unidad: mantener compatibilidad, pero
  % normalizar solo despues de haber considerado P_b_bar.
  if ~isfield(cfg, 'P_b_bar') && isfield(cfg, 'P_b') && es_numero(cfg.P_b)
      try
          cfg.P_b = aos_presion_burbuja_pa(cfg.P_b, 100);
      catch
          if cfg.P_b < 2000, cfg.P_b = cfg.P_b * 1e5; end
      end
  end
end

function cfg = promover(cfg, src, destino, aliases)
  if isfield(cfg, destino) && ~isempty(cfg.(destino)), return; end
  if ~isstruct(src), return; end
  for i = 1:length(aliases)
      [c, ok] = campo_real(src, aliases{i});
      if ok && ~isempty(src.(c))
          cfg.(destino) = src.(c);
          return;
      end
  end
end

function cfg = set_pa_desde_bar(cfg, destino, aliases)
  [v, ok] = primer_numero(cfg, aliases);
  if ok, cfg.(destino) = v * 1e5; end
end

function cfg = set_pa_desde_psi_si_falta_bar(cfg, destino, aliases_bar, aliases_psi)
  [~, hay_bar] = primer_numero(cfg, aliases_bar);
  if hay_bar, return; end
  % Un valor canonico ya expresado en Pa tiene prioridad sobre una columna
  % imperial informativa. Los valores menores que 2000 siguen siendo
  % ambiguos y pueden resolverse mediante el alias explicito en psi.
  if isfield(cfg, destino) && es_numero(cfg.(destino)) && abs(cfg.(destino)) >= 2000
      return;
  end
  [v, ok] = primer_numero(cfg, aliases_psi);
  if ok, cfg.(destino) = v * 6894.757293168; end
end

function cfg = copiar_numero(cfg, destino, aliases)
  [v, ok] = primer_numero(cfg, aliases);
  if ok, cfg.(destino) = v; end
end

function cfg = copiar_numero_desde(cfg, src, destino, aliases)
  [v, ok] = primer_numero(src, aliases);
  if ok, cfg.(destino) = v; end
end

function [v, ok] = primer_numero(s, campos)
  v = NaN; ok = false;
  if ~isstruct(s), return; end
  for i = 1:length(campos)
      [c, existe] = campo_real(s, campos{i});
      if existe && es_numero(s.(c))
          v = s.(c); ok = true; return;
      elseif existe && ischar(s.(c))
          n = str2double(s.(c));
          if ~isnan(n), v = n; ok = true; return; end
      end
  end
end

function [real, ok] = campo_real(s, solicitado)
  real = solicitado; ok = false;
  if ~isstruct(s), return; end
  if isfield(s, solicitado), ok = true; return; end
  nombres = fieldnames(s);
  idx = find(strcmpi(nombres, solicitado), 1);
  if ~isempty(idx), real = nombres{idx}; ok = true; end
end

function cfg = promover_escalares(cfg, src)
  if ~isstruct(src), return; end
  campos = fieldnames(src);
  for i = 1:length(campos)
      c = campos{i};
      if isfield(cfg, c) && ~isempty(cfg.(c)), continue; end
      v = src.(c);
      if (isnumeric(v) && isscalar(v) && isfinite(v)) || islogical(v) || ischar(v)
          cfg.(c) = v;
      end
  end
end

function tf = es_numero(x)
  tf = isnumeric(x) && isscalar(x) && isfinite(x);
end
