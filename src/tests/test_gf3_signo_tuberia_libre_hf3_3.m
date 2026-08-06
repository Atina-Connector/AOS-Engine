function ok = test_gf3_signo_tuberia_libre_hf3_3()
% Regression fisica GF3: tubing libre debe mostrar rigidez positiva.

  ok = false;
  try
    p = gibbs3_defaults(struct( ...
      'D_bomba', 1000, ...
      'longitud_tuberia_m', 1000, ...
      'tuberia_anclada', 0, ...
      'OD_tuberia_mm', 73, ...
      'ID_tuberia_mm', 62, ...
      'E_tuberia_Pa', 207e9));

    F = [0; 1000; 2000; 1000; 0];
    tub = gibbs3_tubing_motion(p, F);
    assert(isfield(tub, 'elongacion_m'));
    assert(isfield(tub, 'u_fondo_m'));
    assert(isfield(tub, 'rigidez_axial_N_m'));
    assert(isfield(tub, 'convencion_signo'));
    assert(all(tub.elongacion_m >= -1e-12));
    assert(max(abs(tub.x_tuberia_m-tub.elongacion_m)) < 1e-12);
    assert(max(abs(tub.u_fondo_m+tub.elongacion_m)) < 1e-12);

    urod = zeros(size(F));
    urel = urod - tub.u_fondo_m;
    kobs = diff(F(1:3))./diff(urel(1:3));
    kteo = p.E_tuberia_Pa*tub.area_metal_m2/tub.longitud_m;
    assert(all(isfinite(kobs)));
    assert(all(kobs > 0));
    assert(max(abs(kobs-kteo))/max(kteo,eps) < 1e-10);

    % Simula un resultado residente con la convencion incorrecta anterior.
    viejo = struct();
    viejo.param = p;
    viejo.version = 'GF3_ANTERIOR_SIGNO_INVERTIDO';
    viejo.modelo = 'TEST';
    viejo.promedio = struct();
    viejo.promedio.F_bomba_N = F;
    viejo.promedio.u_varilla_fondo_m = urod;
    viejo.promedio.u_tuberia_fondo_m = tub.elongacion_m; % error antiguo
    viejo.promedio.u_piston_relativo_m = urod-tub.elongacion_m;
    viejo.promedio.u_bomba_m = viejo.promedio.u_piston_relativo_m;
    viejo.tuberia = struct('x_tuberia_m', tub.elongacion_m);
    F_copia = viejo.promedio.F_bomba_N;

    [reparado, cambios, modificado] = ...
      gibbs3_repair_tubing_sign_result(viejo, false);
    assert(modificado);
    assert(~isempty(cambios));
    assert(max(abs(reparado.promedio.F_bomba_N-F_copia)) < 1e-12);
    assert(max(abs(reparado.promedio.u_tuberia_fondo_m+tub.elongacion_m)) < 1e-12);
    assert(max(abs(reparado.promedio.u_piston_relativo_m-urel)) < 1e-12);

    p.tuberia_anclada = 1;
    tub_a = gibbs3_tubing_motion(p, F);
    assert(all(abs(tub_a.elongacion_m) < 1e-12));
    assert(all(abs(tub_a.u_fondo_m) < 1e-12));

    ok = true;
    fprintf('RESULTADO: test_gf3_signo_tuberia_libre_hf3_3 APROBADO\n');
  catch err
    fprintf(2, 'FALLO test_gf3_signo_tuberia_libre_hf3_3: %s\n', err.message);
  end_try_catch
endfunction
