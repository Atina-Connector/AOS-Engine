function p2 = gibbs3_apply_weight_bars(p, cantidad)
% GIBBS3_APPLY_WEIGHT_BARS Reemplaza el extremo inferior por barras de peso.
% La longitud total de la sarta se conserva igual a la profundidad de bomba.

  p2 = gibbs3_defaults(p);
  cantidad = max(0, round(cantidad));
  if cantidad == 0
    p2.barras_peso_aplicadas_cantidad = 0;
    p2.barras_peso_aplicadas_longitud_m = 0;
    return;
  end

  Lbar = cantidad * p2.barras_peso_longitud_unitaria_m;
  if ~isfinite(Lbar) || Lbar <= 0 || Lbar >= p2.D_bomba
    error('Longitud de barras de peso invalida: %.3f m.', Lbar);
  end

  sec = p2.gibbs3_secciones_varillas;
  if isempty(sec)
    mat = struct('nombre', p2.rod_grade_name, ...
      'E_Pa', p2.gibbs3_E_Pa, 'rho_kg_m3', p2.gibbs3_rho_varilla_kg_m3, ...
      'Sut_MPa', p2.rod_Sut_MPa, 'Se_MPa', p2.rod_Se_MPa, ...
      'Sy_MPa', p2.rod_Sy_MPa);
    sec = crear_seccion(p2.D_bomba, p2.gibbs3_diam_varilla_mm, mat, 'varilla');
  else
    sec = normalizar_campos(sec, p2);
  end

  restante = Lbar;
  i = numel(sec);
  while restante > 1e-9 && i >= 1
    if sec(i).longitud_m > restante + 1e-9
      sec(i).longitud_m = sec(i).longitud_m - restante;
      restante = 0;
    else
      restante = restante - sec(i).longitud_m;
      sec(i) = [];
      i = i - 1;
    end
  end
  if restante > 1e-6
    error('La longitud de barras excede la sarta disponible.');
  end

  % La configuracion base de instalacion contiene solamente las varillas
  % restantes; las barras se informan en un apartado independiente.
  p2.gibbs3_secciones_varillas_base = sec;

  matbar = struct('nombre', 'BARRA_DE_PESO', ...
    'E_Pa', p2.barras_peso_E_Pa, 'rho_kg_m3', p2.barras_peso_rho_kg_m3, ...
    'Sut_MPa', p2.barras_peso_Sut_MPa, 'Se_MPa', p2.barras_peso_Se_MPa, ...
    'Sy_MPa', p2.barras_peso_Sy_MPa);
  barra = crear_seccion(Lbar, p2.barras_peso_diametro_mm, matbar, 'barra_peso');
  if isempty(sec)
    sec = barra;
  else
    sec(end+1) = barra;
  end

  ajuste = p2.D_bomba - sum([sec.longitud_m]);
  sec(end).longitud_m = sec(end).longitud_m + ajuste;
  p2.gibbs3_secciones_varillas = sec;
  p2.barras_peso_aplicadas_cantidad = cantidad;
  p2.barras_peso_aplicadas_longitud_m = Lbar;
end

function sec = normalizar_campos(sec, p)
  for i = 1:numel(sec)
    if ~isfield(sec(i),'E_Pa'), sec(i).E_Pa = p.gibbs3_E_Pa; end
    if ~isfield(sec(i),'rho_kg_m3'), sec(i).rho_kg_m3 = p.gibbs3_rho_varilla_kg_m3; end
    if ~isfield(sec(i),'grado'), sec(i).grado = p.rod_grade_name; end
    if ~isfield(sec(i),'Sut_MPa'), sec(i).Sut_MPa = p.rod_Sut_MPa; end
    if ~isfield(sec(i),'Se_MPa'), sec(i).Se_MPa = p.rod_Se_MPa; end
    if ~isfield(sec(i),'Sy_MPa'), sec(i).Sy_MPa = p.rod_Sy_MPa; end
    if ~isfield(sec(i),'tipo'), sec(i).tipo = 'varilla'; end
  end
end

function s = crear_seccion(L, d, mat, tipo)
  s = struct('longitud_m', L, 'diametro_mm', d, 'E_Pa', mat.E_Pa, ...
    'rho_kg_m3', mat.rho_kg_m3, 'grado', mat.nombre, ...
    'Sut_MPa', mat.Sut_MPa, 'Se_MPa', mat.Se_MPa, ...
    'Sy_MPa', mat.Sy_MPa, 'tipo', tipo);
end
