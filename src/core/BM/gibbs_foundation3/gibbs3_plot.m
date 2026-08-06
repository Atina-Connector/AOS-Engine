function h = gibbs3_plot(res)
% GIBBS3_PLOT Genera cartas, sarta instalable, spacing y aparato.

  p = res.promedio;
  h1 = figure('Name', 'AOS BM - GF3 cartas y transmision', ...
    'NumberTitle', 'off');

  subplot(2,2,1);
  plot(p.u_superficie_plot_m, p.F_superficie_N/1000, 'LineWidth', 1.2);
  grid on; xlabel('Posicion PR (m)'); ylabel('Carga superficie (kN)');
  title('Carta de superficie');

  subplot(2,2,2);
  plot(p.u_piston_relativo_plot_m, p.F_bomba_N/1000, 'LineWidth', 1.2);
  grid on; xlabel('Posicion piston-barril (m)'); ylabel('Carga bomba (kN)');
  if res.param.tuberia_anclada
    title('Carta de fondo - tuberia anclada');
  else
    title('Carta de fondo - tuberia libre');
  end

  subplot(2,2,3);
  plot(p.t_s, p.u_superficie_plot_m, 'LineWidth', 1.1); hold on;
  plot(p.t_s, p.u_varilla_fondo_plot_m, 'LineWidth', 1.1);
  if ~res.param.tuberia_anclada
    plot(p.t_s, p.u_tuberia_fondo_plot_m, 'LineWidth', 1.1);
    plot(p.t_s, p.u_piston_relativo_plot_m, 'LineWidth', 1.1);
    leyenda = {'PR', 'Varilla fondo', 'Tuberia fondo', 'Piston relativo'};
  else
    plot(p.t_s, p.u_piston_relativo_plot_m, 'LineWidth', 1.1);
    leyenda = {'PR', 'Varilla fondo', 'Piston relativo'};
  end
  hold off; grid on; xlabel('Tiempo (s)'); ylabel('Desplazamiento (m)');
  legend(leyenda, 'Location', 'best'); title('Transmision de carrera');

  subplot(2,2,4);
  plot(p.t_s, p.F_superficie_N/1000, 'LineWidth', 1.1); hold on;
  plot(p.t_s, p.F_bomba_N/1000, 'LineWidth', 1.1); hold off;
  grid on; xlabel('Tiempo (s)'); ylabel('Carga (kN)');
  legend({'Superficie', 'Bomba'}, 'Location', 'best'); title('Cargas vs tiempo');

  h = h1;
  if isfield(res, 'diseno_sarta_espaciamiento')
    h2 = figura_diseno(res); h = [h, h2];
  end
  if isfield(res, 'verificacion_aparato')
    h3 = figura_aparato(res); h = [h, h3];
  end
  drawnow();
end

function h2 = figura_diseno(res)
  d = res.diseno_sarta_espaciamiento;
  h2 = figure('Name', 'AOS BM - GF3 sarta, barras y espaciamiento', ...
    'NumberTitle', 'off');

  subplot(2,2,1);
  plot(d.elementos.utilizacion, d.elementos.x_m, 'LineWidth', 1.2); hold on;
  plot([1 1], [min(d.elementos.x_m) max(d.elementos.x_m)], '--', 'LineWidth', 1.0);
  hold off; set(gca, 'YDir', 'reverse'); grid on;
  xlabel('Utilizacion Goodman'); ylabel('Profundidad MD (m)');
  if d.aprobada_fatiga
    title(sprintf('Fatiga - VERDE (max %.3f)', d.utilizacion_max));
  else
    title(sprintf('Fatiga - REVISAR (max %.3f)', d.utilizacion_max));
  end

  subplot(2,2,2);
  stairs(d.elementos.diametro_mm, d.elementos.x_m, 'LineWidth', 1.5); hold on;
  if isfield(d,'barras_peso') && d.barras_peso.cantidad_instalada > 0
    y2 = res.param.D_bomba;
    y1 = max(0, y2-d.barras_peso.longitud_instalada_m);
    plot([d.barras_peso.diametro_mm d.barras_peso.diametro_mm], ...
      [y1 y2], 'LineWidth', 4);
    text(d.barras_peso.diametro_mm, 0.5*(y1+y2), ...
      sprintf('  %d barras de peso', d.barras_peso.cantidad_instalada));
  end
  hold off; set(gca, 'YDir', 'reverse'); grid on;
  xlabel('Diametro (mm)'); ylabel('Profundidad MD (m)');
  title(sprintf('Sarta %s - %d tramos', d.candidata_seleccionada, ...
    numel(d.plan_instalacion_sarta)));

  subplot(2,2,3);
  e = d.espaciamiento;
  if ~isfield(e,'valido') || ~e.valido || ...
      ~isfinite(e.clearance_inferior_estimado_m) || ...
      ~isfinite(e.clearance_superior_estimado_m)
    axis off;
    text(0.03,0.88,'ESPACIAMIENTO NO APROBADO','FontWeight','bold');
    text(0.03,0.70,local_txt_plot(e,'validacion','Calculo invalido.'));
    text(0.03,0.50,'No utilizar este resultado para instalacion.');
    title('Espaciamiento operativo - ROJO');
  else
    hold on;
    plot([0 0], [0 e.longitud_util_m], 'LineWidth', 4);
    y1 = e.clearance_inferior_estimado_m;
    y2 = y1 + e.carrera_relativa_m;
    plot([0.18 0.18], [y1 y2], 'LineWidth', 8);
    plot([-0.08 0.28], [0 0], 'LineWidth', 1.5);
    plot([-0.08 0.28], [e.longitud_util_m e.longitud_util_m], 'LineWidth', 1.5);
    text(0.32, y1, sprintf('PMI / clearance inf. %.3f m', y1));
    text(0.32, y2, sprintf('PMS / fin carrera %.3f m', y2));
    text(0.32, e.longitud_util_m, sprintf('Limite %.3f m', e.longitud_util_m));
    text(0.32, 0.60*e.longitud_util_m, sprintf('Sensar y levantar %.0f mm', ...
      e.levantamiento_despues_sensar_mm));
    if isfield(e,'correccion_requerida_m')
      text(0.32, 0.45*e.longitud_util_m, sprintf('Correccion diferencial %.0f mm', ...
        1000*e.correccion_requerida_m));
    end
    if isfield(e,'condicion_termica_sensado')
      text(0.32, 0.30*e.longitud_util_m, ...
        ['Termica al sensar: ' e.condicion_termica_sensado]);
    end
    hold off; grid on; xlim([-0.2 1.4]);
    ylim([min(-0.05,y1-0.05), max(e.longitud_util_m+0.05,y2+0.05)]);
    set(gca, 'XTick', []); ylabel('Longitud util (m)');
    title(['Espaciamiento diferencial - ' e.estado]);
  end

  subplot(2,2,4);
  if res.param.bomba_lpp
    plot(res.promedio.t_s, res.promedio.deltaP_LPP_Pa/1e5, 'LineWidth', 1.1); hold on;
    plot(res.promedio.t_s, res.promedio.F_LPP_N/1000, 'LineWidth', 1.1); hold off;
    grid on; xlabel('Tiempo (s)');
    legend({'DeltaP LPP (bar)', 'Carga LPP (kN)'}, 'Location', 'best');
    title('Efecto hidraulico LPP');
  else
    axis off;
    b = d.barras_peso;
    text(0.02,0.92,'INSTRUCCIONES DE INSTALACION','FontWeight','bold');
    text(0.02,0.78,sprintf('Sarta: %s', d.candidata_seleccionada));
    text(0.02,0.64,sprintf('Barras: %s', b.resultado_operativo));
    text(0.02,0.50,sprintf('Longitud por barra: %.2f m; total: %.2f m', ...
      b.longitud_unitaria_m, b.longitud_instalada_m));
    text(0.02,0.36,sprintf('Sensar fondo y levantar: %.0f mm', ...
      e.levantamiento_despues_sensar_mm));
    text(0.02,0.22,sprintf('Tolerancia de ejecucion: +/- %.0f mm', ...
      e.tolerancia_ejecucion_mm));
    text(0.02,0.08,sprintf('Estado spacing: %s', e.estado));
    title('Resumen instalable');
  end
end

function s = local_txt_plot(st, campo, defecto)
  s = defecto;
  if isstruct(st) && isfield(st,campo) && ischar(st.(campo))
    s = st.(campo);
  end
end

function h3 = figura_aparato(res)
  c = res.promedio.aparato;
  v = res.verificacion_aparato;
  h3 = figure('Name', 'AOS BM - GF3 aparato de bombeo', ...
    'NumberTitle', 'off');

  subplot(2,2,1);
  plot(c.t_s, c.posicion_m, 'LineWidth', 1.2); grid on;
  xlabel('Tiempo (s)'); ylabel('Posicion PR (m)');
  title(sprintf('%s - %s', v.tipo, v.modelo));

  subplot(2,2,2);
  plot(c.t_s, c.velocidad_m_s, 'LineWidth', 1.2); grid on;
  xlabel('Tiempo (s)'); ylabel('Velocidad PR (m/s)'); title('Velocidad superficial');

  subplot(2,2,3);
  plot(c.t_s, c.aceleracion_m_s2, 'LineWidth', 1.2); grid on;
  xlabel('Tiempo (s)'); ylabel('Aceleracion PR (m/s2)'); title('Aceleracion superficial');

  subplot(2,2,4);
  plot(c.angulo_rad*180/pi, v.torque_neto_kNm, 'LineWidth', 1.2); hold on;
  if isfinite(res.param.pumping_unit_gearbox_torque_kNm)
    lim = res.param.pumping_unit_gearbox_torque_kNm;
    plot([0 360], [lim lim], '--', 'LineWidth', 1.0);
    plot([0 360], [-lim -lim], '--', 'LineWidth', 1.0);
  end
  plot([0 360], [0 0], ':', 'LineWidth', 0.8);
  hold off; grid on; xlabel('Angulo manivela (deg)'); ylabel('Torque neto (kN.m)');
  title(sprintf('Torque - %s', v.estado));
end
