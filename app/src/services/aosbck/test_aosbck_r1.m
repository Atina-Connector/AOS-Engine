function ok = test_aosbck_r1()
% TEST_AOSBCK_R1 Round-trip basico no interactivo y limpieza segura.
  ok = false;
  raiz = aosbck_raiz();
  step = fullfile(raiz, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  if exist(step, 'file') ~= 2
    error('Falta STEP de prueba: %s', step);
  endif

  out = fullfile(tempdir(), [tempname_local('aosbck_test') '.aosbck']);
  estado_previo = [];
  try
    estado_previo = aosbck_estado('GET');
  catch
    estado_previo = [];
  end_try_catch

  unwind_protect
    meta = struct('part_number', 'DEMO-PART-001', ...
      'component_type', 'DEMO', ...
      'description', 'Componente demo', ...
      'manufacturer_id', 'AESIR-DEMO', ...
      'supplier_id', 'AESIR-DEMO', ...
      'material_id', 'MAT-DEMO');
    p = aosbck_crear_desde_step(step, meta, out, true);
    e = aosbck_abrir(p, true);
    r = aosbck_validar(e.manifest, e.carpeta_temporal, false);
    assert(r.ok);
    assert(strcmp(e.manifest.component.part_number, 'DEMO-PART-001'));

    placement = struct('source', 'XYZ_MANUAL', ...
      'position_m', [1 2 3], ...
      'coordinate_convention', 'RIGHT_HANDED_Z_UP', ...
      'inclination_deg', 0, ...
      'azimuth_deg', 0, ...
      'roll_deg', 0, ...
      'orientation_quaternion_wxyz', [1 0 0 0], ...
      'source_reference', 'SELFTEST');
    aosbck_agregar_instancia(placement, struct(), 'INST-DEMO-001', true);
    e = aosbck_estado('GET');
    assert(numel(e.manifest.instances) == 1);
    ok = true;
  unwind_protect_cleanup
    try
      aosbck_estado('CLEAR');
    catch
    end_try_catch
    if exist(out, 'file') == 2
      try
        delete(out);
      catch
      end_try_catch
    endif
    if isstruct(estado_previo) && isfield(estado_previo, 'paquete') && ...
        ~isempty(estado_previo.paquete) && exist(estado_previo.paquete, 'file') == 2
      try
        aosbck_abrir(estado_previo.paquete, true);
      catch
      end_try_catch
    endif
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aosbck_r1 APROBADO\n');
  endif
endfunction

function nombre = tempname_local(prefijo)
  [~, base] = fileparts(tempname());
  nombre = sprintf('%s_%s_%06d', prefijo, base, randi(999999));
endfunction
