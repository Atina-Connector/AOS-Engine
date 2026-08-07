function dis = gibbs3_rod_spacing_design(res)
% GIBBS3_ROD_SPACING_DESIGN Evalua sarta, barras e instruccion de spacing.

  p = res.param;
  U = res.promedio.U_m;
  ne = res.malla.n - 1;
  nt = size(U,1);
  Fint = zeros(nt,ne);
  for e = 1:ne
    Fint(:,e) = res.malla.k_e_N_m(e) .* (U(:,e)-U(:,e+1));
  end

  area = res.malla.area_m2(:);
  sigmax = max(Fint,[],1)' ./ area;
  sigmin = min(Fint,[],1)' ./ area;
  siga = 0.5*(sigmax-sigmin);
  sigm = 0.5*(sigmax+sigmin);
  xelem = 0.5*(res.malla.x_m(1:end-1)+res.malla.x_m(2:end));
  [Sut, Se] = resistencias_por_elemento(p, xelem);
  goodman = siga./(Se*1e6) + max(sigm,0)./(Sut*1e6);
  utiliz = p.rod_factor_seguridad .* goodman;

  dis = struct();
  dis.elementos = struct();
  dis.elementos.x_m = res.malla.x_m(1:end-1);
  dis.elementos.diametro_mm = res.malla.diametro_m(:)*1000;
  dis.elementos.Fmax_N = max(Fint,[],1)';
  dis.elementos.Fmin_N = min(Fint,[],1)';
  dis.elementos.sigma_max_MPa = sigmax/1e6;
  dis.elementos.sigma_min_MPa = sigmin/1e6;
  dis.elementos.sigma_alternante_MPa = siga/1e6;
  dis.elementos.sigma_media_MPa = sigm/1e6;
  dis.elementos.goodman = goodman;
  dis.elementos.utilizacion = utiliz;
  [dis.utilizacion_max, idx] = max(utiliz);
  dis.elemento_critico = idx;
  dis.aprobada_fatiga = dis.utilizacion_max <= 1.0;
  dis.modo_sarta = p.rod_design_mode;
  dis.grado_sarta = p.rod_grade_name;
  dis.candidata_seleccionada = p.rod_design_candidate_name;
  dis.motivo_seleccion = p.rod_design_selection_reason;
  dis.secciones = p.gibbs3_secciones_varillas;
  dis.plan_instalacion_sarta = construir_plan_sarta(p);
  dis.masa_total_varillas_kg = sum_campo(dis.plan_instalacion_sarta, 'masa_kg');
  dis.candidatos = resumen_candidatos(p);

  % Barras de peso: calcula longitud teorica y la convierte a una cantidad
  % entera de elementos comerciales.
  if p.barras_peso_habilitadas
    Flpp_desc = max(abs(min(res.promedio.F_LPP_N, 0)));
    Fcomp = max(0, -min(Fint(:,end)));
    Fres = p.barras_peso_margen * (p.gibbs3_friccion_descenso_N + ...
      Flpp_desc + Fcomp + p.barras_peso_tension_minima_N);
    rho_bar = p.barras_peso_rho_kg_m3;
    dbar = p.barras_peso_diametro_mm/1000;
    Abar = pi*dbar^2/4;
    bf = max(1-res.malla.rho_liquido_kg_m3/rho_bar, 0.05);
    peso_m = rho_bar*Abar*p.gibbs3_gravedad_m_s2*bf;
    Lreq = Fres/max(peso_m, eps);
    Lunit = max(p.barras_peso_longitud_unitaria_m, eps);
    nreq = max(0, ceil(Lreq/Lunit - 1e-12));
  else
    Flpp_desc = 0; Fcomp = 0; Fres = 0; peso_m = 0; Lreq = 0;
    Lunit = p.barras_peso_longitud_unitaria_m; nreq = 0;
    rho_bar = p.barras_peso_rho_kg_m3;
    Abar = pi*(p.barras_peso_diametro_mm/1000)^2/4;
    bf = max(1-res.malla.rho_liquido_kg_m3/rho_bar, 0.05);
  end

  ninst = max(0, round(p.barras_peso_aplicadas_cantidad));
  if ninst == 0 && nreq > 0 && ~p.barras_peso_integrar_en_GF3
    ninst = nreq;
  end
  Linst = ninst*Lunit;
  masa_unit = rho_bar*Abar*Lunit;
  peso_ap_unit_N = peso_m*Lunit;

  dis.barras_peso = struct();
  dis.barras_peso.habilitadas = logical(p.barras_peso_habilitadas);
  dis.barras_peso.fuerza_requerida_N = Fres;
  dis.barras_peso.componente_LPP_N = Flpp_desc;
  dis.barras_peso.componente_compresion_N = Fcomp;
  dis.barras_peso.peso_aparente_N_m = peso_m;
  dis.barras_peso.longitud_teorica_requerida_m = Lreq;
  dis.barras_peso.longitud_recomendada_m = nreq*Lunit;
  dis.barras_peso.diametro_mm = p.barras_peso_diametro_mm;
  dis.barras_peso.longitud_unitaria_m = Lunit;
  dis.barras_peso.cantidad_recomendada = nreq;
  dis.barras_peso.cantidad_instalada = ninst;
  dis.barras_peso.longitud_instalada_m = Linst;
  dis.barras_peso.masa_unitaria_aire_kg = masa_unit;
  dis.barras_peso.masa_total_aire_kg = ninst*masa_unit;
  dis.barras_peso.peso_aparente_unitario_N = peso_ap_unit_N;
  dis.barras_peso.peso_aparente_total_N = ninst*peso_ap_unit_N;
  dis.barras_peso.ubicacion = 'INMEDIATAMENTE_POR_ENCIMA_DE_LA_BOMBA';
  dis.barras_peso.instalar = logical(p.barras_peso_habilitadas && nreq > 0);
  if dis.barras_peso.instalar
    dis.barras_peso.resultado_operativo = ...
      sprintf('INSTALAR %d BARRAS DE PESO', max(ninst,nreq));
  elseif p.barras_peso_habilitadas
    dis.barras_peso.resultado_operativo = 'NO SE REQUIEREN BARRAS DE PESO';
  else
    dis.barras_peso.resultado_operativo = 'CALCULO DE BARRAS DE PESO DESHABILITADO';
  end

  % Espaciamiento diferencial entre el estado de sensado y la operacion.
  % La elongacion absoluta por peso propio se informa, pero no se suma de
  % nuevo al levantamiento porque ya existe cuando se sensa fondo.
  dis.espaciamiento = calcular_espaciamiento_diferencial(res, p);
end

function e = calcular_espaciamiento_diferencial(res, p)
% Calcula el levantamiento requerido usando diferencias de estado.
%
% Convencion de signo:
%   correccion positiva = el piston queda mas abajo respecto del barril
%   durante la operacion que durante el sensado de fondo.

  e = struct();
  e.modelo = 'diferencial_entre_sensado_y_operacion';
  e.modo = p.spacing_mode;
  e.valido = false;
  e.estado = 'ROJO';
  e.validacion = 'CALCULO_NO_COMPLETADO';

  % Geometria de referencia.
  carrera = res.metricas.carrera_piston_relativa_m;
  if p.bomba_lpp
    longitud_util = p.lpp_longitud_piston_m;
    referencia = 'PISTON_LPP';
  else
    longitud_util = p.longitud_barril_util_m;
    referencia = 'BARRIL';
  end

  % Compliance axial equivalente de la sarta final, incluyendo barras de
  % peso si ya fueron integradas en la malla.
  compliance = sum(1.0 ./ res.malla.k_e_N_m(:));
  elong_eq = res.equilibrio.u_m(1) - res.equilibrio.u_m(end);

  % La referencia de sensado se toma sin carga hidraulica transferida. Si el
  % usuario ingreso una carga de sensado, se respeta; de lo contrario se usa
  % la carga descendente del modelo de bomba. El peso propio ya esta incluido.
  if isfinite(p.spacing_carga_sensado_N)
    F_sensado = p.spacing_carga_sensado_N;
  elseif isfield(res, 'bomba') && isfield(res.bomba, 'F_down_N') && ...
      isfinite(res.bomba.F_down_N)
    F_sensado = res.bomba.F_down_N;
  else
    F_sensado = min(res.promedio.F_bomba_N(:));
  end

  F_ref = 0.0;
  if isfield(res, 'bomba') && isfield(res.bomba, 'F_ref_N') && ...
      isfinite(res.bomba.F_ref_N)
    F_ref = res.bomba.F_ref_N;
  end

  elong_peso = elong_eq - F_ref * compliance;
  elong_sensado = elong_peso + F_sensado * compliance;

  % Deformacion real ciclo a ciclo. U_superficie-U_fondo es la elongacion
  % instantanea de la sarta. Se resta la elongacion ya presente al sensar.
  U = res.promedio.U_m;
  deformacion_ciclo = U(:,1) - U(:,end);
  delta_rod_ciclo = deformacion_ciclo - elong_sensado;

  % Para spacing se usa la magnitud positiva de elongacion del tubing,
  % nunca la posicion axial firmada del barril. En GF3 positivo es hacia
  % arriba, por lo que una tuberia libre elongada tiene u_fondo_m < 0.
  if isfield(res, 'tuberia') && isfield(res.tuberia, 'elongacion_m')
    tub_ciclo = res.tuberia.elongacion_m(:);
  elseif isfield(res, 'tuberia') && isfield(res.tuberia, 'x_tuberia_m')
    % Compatibilidad: x_tuberia_m historicamente fue elongacion positiva.
    tub_ciclo = res.tuberia.x_tuberia_m(:);
  elseif isfield(res.promedio, 'elongacion_tuberia_m')
    tub_ciclo = res.promedio.elongacion_tuberia_m(:);
  elseif isfield(res.promedio, 'u_tuberia_fondo_m')
    % Compatibilidad con resultados residentes: spacing necesita magnitud.
    tub_ciclo = abs(res.promedio.u_tuberia_fondo_m(:));
  else
    tub_ciclo = zeros(size(delta_rod_ciclo));
  endif
  if numel(tub_ciclo) ~= numel(delta_rod_ciclo) || ...
      any(~isfinite(tub_ciclo))
    tub_ciclo = zeros(size(delta_rod_ciclo));
  endif
  tub_ciclo = max(tub_ciclo, 0.0);

  correccion_mecanica_ciclo = delta_rod_ciclo - tub_ciclo;
  correccion_mecanica_max = max(correccion_mecanica_ciclo);
  correccion_mecanica_min = min(correccion_mecanica_ciclo);

  % Descomposicion cuasiestatica para diagnostico. La diferencia entre el
  % maximo real y esta componente se informa como correccion dinamica.
  Fmax = max(res.promedio.F_bomba_N(:));
  deltaF = max(Fmax - F_sensado, 0.0);
  elong_dif_carga = deltaF * compliance;
  mov_tub_dif = max(tub_ciclo) - min(tub_ciclo);
  correccion_cuasistatica = elong_dif_carga - mov_tub_dif;
  correccion_dinamica = correccion_mecanica_max - correccion_cuasistatica;

  [term_rod, term_tub, term_neta, condicion_termica, term_ok, term_msg] = ...
    correccion_termica_diferencial(p, res);

  correccion_neta_ciclo = correccion_mecanica_ciclo + term_neta;
  correccion_neta_max = max(correccion_neta_ciclo);
  correccion_neta_min = min(correccion_neta_ciclo);
  correccion_requerida = max(correccion_neta_max, 0.0);

  componentes = [compliance, elong_eq, elong_peso, elong_sensado, ...
    correccion_mecanica_max, term_rod, term_tub, term_neta, ...
    correccion_neta_max, carrera, longitud_util, ...
    p.spacing_clearance_inferior_m, p.spacing_clearance_superior_m, ...
    p.spacing_margen_instalacion_m, p.spacing_tolerancia_ejecucion_m];
  finito = all(isfinite(componentes)) && term_ok;

  if strcmpi(p.spacing_mode, 'manual') && isfinite(p.spacing_offset_manual_m)
    spacing_raw = p.spacing_offset_manual_m;
    usa_manual = true;
  elseif strcmpi(p.spacing_mode, 'evaluacion') && ...
      isfinite(p.spacing_offset_manual_m)
    spacing_raw = p.spacing_offset_manual_m;
    usa_manual = true;
  else
    spacing_raw = p.spacing_clearance_inferior_m + ...
      p.spacing_margen_instalacion_m + correccion_requerida;
    usa_manual = false;
  end

  paso_mm = max(p.spacing_redondeo_mm, 1.0);
  if finito && isfinite(spacing_raw) && spacing_raw >= 0
    if usa_manual
      spacing = spacing_raw;
      spacing_mm = spacing * 1000.0;
    else
      spacing_mm = ceil(spacing_raw*1000.0/paso_mm - 1e-12)*paso_mm;
      spacing = spacing_mm/1000.0;
    end
  else
    spacing = NaN;
    spacing_mm = NaN;
  end

  % Clearances nominales y de peor caso por tolerancia de ejecucion.
  if isfinite(spacing)
    clear_inf_nom = spacing - correccion_requerida;
    clear_inf_peor = clear_inf_nom - p.spacing_tolerancia_ejecucion_m;
    clear_sup_nom = longitud_util - carrera - clear_inf_nom;
    clear_sup_peor = clear_sup_nom - p.spacing_tolerancia_ejecucion_m;
  else
    clear_inf_nom = NaN; clear_inf_peor = NaN;
    clear_sup_nom = NaN; clear_sup_peor = NaN;
  end

  capacidad_informada = isfinite(p.spacing_levantamiento_maximo_disponible_m) && ...
    p.spacing_levantamiento_maximo_disponible_m > 0;
  if capacidad_informada && isfinite(spacing)
    capacidad_aprobada = spacing <= p.spacing_levantamiento_maximo_disponible_m + 1e-12;
  else
    capacidad_aprobada = ~logical(p.spacing_exigir_capacidad_ajuste);
  end

  geometria_aprobada = finito && isfinite(spacing) && spacing >= 0 && ...
    clear_inf_peor >= p.spacing_clearance_inferior_m - 1e-9 && ...
    clear_sup_peor >= p.spacing_clearance_superior_m - 1e-9 && ...
    longitud_util >= carrera + p.spacing_clearance_inferior_m + ...
      p.spacing_clearance_superior_m && capacidad_aprobada;

  if ~finito
    estado = 'ROJO';
    validacion = ['Calculo invalido: existen componentes NaN/Inf. ' term_msg];
  elseif ~isfinite(spacing) || spacing < 0
    estado = 'ROJO';
    validacion = 'Levantamiento no finito o negativo. No usar en campo.';
  elseif capacidad_informada && ~capacidad_aprobada
    estado = 'ROJO';
    validacion = 'El levantamiento supera la capacidad de ajuste informada.';
  elseif geometria_aprobada
    estado = 'VERDE';
    if capacidad_informada
      validacion = 'Calculo diferencial finito, geometria y capacidad aprobadas.';
    else
      validacion = ['Calculo diferencial finito y geometria aprobada. ' ...
        'Capacidad de ajuste del vastago no informada.'];
    end
  elseif clear_inf_peor >= 0 && clear_sup_peor >= 0
    estado = 'AMARILLO';
    validacion = 'Geometria sin interferencia, pero no cumple todos los clearances objetivo.';
  else
    estado = 'ROJO';
    validacion = 'Geometria con interferencia o clearances negativos. No usar en campo.';
  end

  e.modelo = p.spacing_modelo;
  e.modo = p.spacing_mode;
  e.referencia = referencia;
  e.condicion_termica_sensado = condicion_termica;
  e.perfil_termico = p.spacing_perfil_termico;
  e.condicion_tubing = texto_tubing(p.tuberia_anclada);

  % Informacion absoluta: no se suma al levantamiento.
  e.elongacion_varillas_m = elong_eq;
  e.elongacion_absoluta_equilibrio_m = elong_eq;
  e.elongacion_absoluta_peso_propio_m = elong_peso;
  e.elongacion_estado_sensado_m = elong_sensado;
  e.peso_propio_ya_incluido_al_sensar = true;
  e.contribucion_peso_propio_al_levantamiento_m = 0.0;

  % Componentes diferenciales.
  e.compliance_sarta_m_N = compliance;
  e.carga_referencia_sensado_N = F_sensado;
  e.carga_maxima_bomba_N = Fmax;
  e.incremento_carga_bomba_N = deltaF;
  e.elongacion_diferencial_carga_m = elong_dif_carga;
  e.elongacion_tuberia_m = mov_tub_dif;
  e.movimiento_diferencial_tubing_m = mov_tub_dif;
  e.correccion_cuasistatica_m = correccion_cuasistatica;
  e.correccion_dinamica_m = correccion_dinamica;
  e.correccion_mecanica_max_m = correccion_mecanica_max;
  e.correccion_mecanica_min_m = correccion_mecanica_min;
  e.expansion_termica_varillas_m = term_rod;
  e.expansion_termica_tuberia_m = term_tub;
  e.expansion_termica_diferencial_varillas_m = term_rod;
  e.expansion_termica_diferencial_tuberia_m = term_tub;
  e.correccion_termica_neta_m = term_neta;
  e.correccion_neta_max_m = correccion_neta_max;
  e.correccion_neta_min_m = correccion_neta_min;
  e.correccion_requerida_m = correccion_requerida;
  % Alias historico, ahora representa solo la correccion diferencial neta.
  e.correccion_elastica_termica_m = correccion_requerida;

  e.recomendado_superficie_sin_redondear_m = spacing_raw;
  e.recomendado_superficie_m = spacing;
  e.levantamiento_despues_sensar_mm = spacing_mm;
  e.tolerancia_ejecucion_mm = 1000.0*p.spacing_tolerancia_ejecucion_m;
  e.longitud_util_m = longitud_util;
  e.carrera_relativa_m = carrera;
  e.clearance_inferior_estimado_m = clear_inf_nom;
  e.clearance_superior_estimado_m = clear_sup_nom;
  e.clearance_inferior_peor_caso_m = clear_inf_peor;
  e.clearance_superior_peor_caso_m = clear_sup_peor;
  e.clearance_inferior_objetivo_m = p.spacing_clearance_inferior_m;
  e.clearance_superior_objetivo_m = p.spacing_clearance_superior_m;
  e.margen_instalacion_m = p.spacing_margen_instalacion_m;
  e.longitud_requerida_m = carrera + clear_inf_nom + ...
    p.spacing_clearance_superior_m;
  e.capacidad_ajuste_informada = capacidad_informada;
  e.levantamiento_maximo_disponible_m = p.spacing_levantamiento_maximo_disponible_m;
  e.capacidad_ajuste_aprobada = capacidad_aprobada;
  e.geometria_aprobada = geometria_aprobada;
  e.valido = finito && isfinite(spacing) && spacing >= 0;
  % Contrato publico de espaciamiento. Los consumidores historicos y el
  % reporte transversal esperan valido_calculo/mensaje_validacion, mientras
  % que el productor interno utilizaba valido/validacion. Se publican ambos
  % pares como aliases equivalentes para evitar falsos rechazos.
  e.valido_calculo = e.valido;
  e.estado = estado;
  e.validacion = validacion;
  e.mensaje_validacion = validacion;
  e.schema = 'GF3_SPACING_RESULT_1_1';

  e.instruccion_1 = instruccion_previa(p.tuberia_anclada);
  e.instruccion_2 = 'Bajar la sarta lentamente hasta sensar fondo.';
  if e.valido && ~strcmpi(e.estado, 'ROJO')
    e.instruccion_3 = sprintf( ...
      'Levantar la sarta %.0f mm desde la posicion de fondo.', spacing_mm);
    e.instruccion_4 = 'Fijar la grampa del vastago pulido en esa posicion.';
    e.instruccion_5 = ...
      'Verificar una carrera completa sin contacto antes de poner en operacion.';
  else
    e.instruccion_3 = 'NO APLICAR ESPACIAMIENTO: el calculo no fue aprobado.';
    e.instruccion_4 = 'Revisar datos de sarta, temperatura, tubing y geometria de bomba.';
    e.instruccion_5 = 'No poner en operacion hasta obtener un resultado aprobado.';
  end
end

function [drod, dtub, dneta, condicion, ok, mensaje] = ...
    correccion_termica_diferencial(p, res)
% Calcula solo la diferencia termica entre sensado y operacion.

  condicion = lower(strtrim(p.spacing_condicion_termica_sensado));
  drod = 0.0; dtub = 0.0; dneta = 0.0;
  ok = true; mensaje = '';

  if strcmp(condicion, 'estabilizada')
    % Sensado y operacion con el mismo perfil termico: no hay diferencial.
    return;
  elseif strcmp(condicion, 'manual')
    dneta = p.spacing_correccion_termica_manual_m;
    drod = dneta;
    dtub = 0.0;
    ok = isfinite(dneta);
    if ~ok, mensaje = 'Correccion termica manual no finita.'; end
    return;
  elseif ~strcmp(condicion, 'fria')
    ok = false;
    mensaje = ['Condicion termica de sensado no reconocida: ' condicion];
    return;
  end

  % Perfil lineal por profundidad. Para un perfil lineal la integral es la
  % longitud por la diferencia de temperaturas medias.
  Top_rod = 0.5*(p.temperatura_superficie_C + p.temperatura_fondo_C);
  Ttag_rod = 0.5*(p.spacing_temperatura_sensado_superficie_C + ...
    p.spacing_temperatura_sensado_fondo_C);
  drod = p.alpha_termica_varilla_1_C * p.D_bomba * (Top_rod - Ttag_rod);

  if p.tuberia_anclada
    dtub = 0.0;
  else
    Ltub = p.D_bomba;
    if isfield(res, 'tuberia') && isfield(res.tuberia, 'longitud_m') && ...
        isfinite(res.tuberia.longitud_m) && res.tuberia.longitud_m > 0
      Ltub = res.tuberia.longitud_m;
    elseif isfield(p, 'longitud_tuberia_m') && ...
        isfinite(p.longitud_tuberia_m) && p.longitud_tuberia_m > 0
      Ltub = p.longitud_tuberia_m;
    end
    Top_tub = Top_rod;
    Ttag_tub = Ttag_rod;
    dtub = p.alpha_termica_tuberia_1_C * Ltub * (Top_tub - Ttag_tub);
  end
  dneta = drod - dtub;
  ok = all(isfinite([drod, dtub, dneta]));
  if ~ok, mensaje = 'Correccion termica diferencial no finita.'; end
end

function plan = construir_plan_sarta(p)
  sec = secciones_base(p);
  if isempty(sec)
    mat = struct('longitud_m', p.D_bomba, ...
      'diametro_mm', p.gibbs3_diam_varilla_mm, ...
      'rho_kg_m3', p.gibbs3_rho_varilla_kg_m3, ...
      'grado', p.rod_grade_name, 'tipo', 'varilla');
    sec = mat;
  end

  plan = struct('indice', {}, 'desde_m', {}, 'hasta_m', {}, ...
    'longitud_m', {}, 'diametro_mm', {}, 'grado', {}, ...
    'longitud_comercial_m', {}, 'cantidad_varillas_completas', {}, ...
    'ajuste_pony_rod_m', {}, 'cantidad_elementos', {}, 'masa_kg', {});
  desde = 0;
  Lc = max(p.rod_longitud_comercial_m, eps);
  for i = 1:numel(sec)
    if isfield(sec(i),'tipo') && strcmpi(sec(i).tipo,'barra_peso')
      continue;
    end
    L = sec(i).longitud_m;
    nfull = floor(L/Lc + 1e-10);
    ajuste = L-nfull*Lc;
    if ajuste > 1e-8 && ajuste < p.rod_ajuste_minimo_m && nfull > 0
      nfull = nfull-1;
      ajuste = L-nfull*Lc;
    end
    nelt = nfull + double(ajuste > 1e-8);
    rho = p.gibbs3_rho_varilla_kg_m3;
    if isfield(sec(i),'rho_kg_m3'), rho = sec(i).rho_kg_m3; end
    A = pi*(sec(i).diametro_mm/1000)^2/4;
    grado = p.rod_grade_name;
    if isfield(sec(i),'grado'), grado = sec(i).grado; end
    item = struct();
    item.indice = numel(plan)+1;
    item.desde_m = desde;
    item.hasta_m = desde+L;
    item.longitud_m = L;
    item.diametro_mm = sec(i).diametro_mm;
    item.grado = grado;
    item.longitud_comercial_m = Lc;
    item.cantidad_varillas_completas = nfull;
    item.ajuste_pony_rod_m = ajuste;
    item.cantidad_elementos = nelt;
    item.masa_kg = rho*A*L;
    plan(end+1) = item;
    desde = item.hasta_m;
  end
end

function sec = secciones_base(p)
  sec = [];
  if isfield(p,'gibbs3_secciones_varillas_base') && ...
      isstruct(p.gibbs3_secciones_varillas_base) && ...
      ~isempty(p.gibbs3_secciones_varillas_base)
    sec = p.gibbs3_secciones_varillas_base;
  elseif isfield(p,'gibbs3_secciones_varillas')
    sec = p.gibbs3_secciones_varillas;
  end
end

function c = resumen_candidatos(p)
  c = [];
  if isfield(p,'rod_design_candidates') && isstruct(p.rod_design_candidates)
    c = p.rod_design_candidates;
  end
end

function suma = sum_campo(s, campo)
  suma = 0;
  if isempty(s), return; end
  for i = 1:numel(s)
    if isfield(s(i),campo) && isfinite(s(i).(campo))
      suma = suma+s(i).(campo);
    end
  end
end

function [Sut, Se] = resistencias_por_elemento(p, x)
  Sut = repmat(p.rod_Sut_MPa, numel(x), 1);
  Se = repmat(p.rod_Se_MPa, numel(x), 1);
  sec = p.gibbs3_secciones_varillas;
  if isempty(sec), return; end
  lim = cumsum([sec.longitud_m]);
  for i = 1:numel(x)
    k = find(x(i) <= lim, 1, 'first');
    if isempty(k), k = numel(sec); end
    if isfield(sec(k), 'Sut_MPa') && isfinite(sec(k).Sut_MPa)
      Sut(i) = sec(k).Sut_MPa;
    end
    if isfield(sec(k), 'Se_MPa') && isfinite(sec(k).Se_MPa)
      Se(i) = sec(k).Se_MPa;
    end
  end
end

function s = estado_spacing(ok, clear_sup)
  if ok
    s = 'VERDE';
  elseif clear_sup >= 0
    s = 'AMARILLO';
  else
    s = 'ROJO';
  end
end

function s = texto_tubing(anclada)
  if anclada, s = 'TUBERIA_ANCLADA'; else, s = 'TUBERIA_LIBRE'; end
end

function s = instruccion_previa(anclada)
  if anclada
    s = 'Fijar primero el ancla de tubing en su condicion definitiva.';
  else
    s = 'Dejar el tubing en su condicion final de operacion antes de espaciar.';
  end
end
