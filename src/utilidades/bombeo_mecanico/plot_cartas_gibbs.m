function plot_cartas_gibbs(diag)
  % plot_cartas_gibbs.m - Vista BM/Gibbs AOS v12.
  % Enfatiza lectura operativa: semaforos, transmision de carrera,
  % transmision de carga, cartas clasicas apaisadas y resumen.

  if nargin < 1 || isempty(diag)
      error('plot_cartas_gibbs requiere estructura diag.');
  end
  if ~isfield(diag, 'carta_sup') || ~isfield(diag, 'carta_fondo')
      error('diag debe incluir carta_sup y carta_fondo.');
  end

  carta_sup = diag.carta_sup;
  carta_fondo = diag.carta_fondo;
  n = min(size(carta_sup,1), size(carta_fondo,1));
  carta_sup = carta_sup(1:n,:);
  carta_fondo = carta_fondo(1:n,:);

  if isfield(diag, 't') && length(diag.t) >= n
      eje_t = diag.t(1:n);
      eje_t_label = 'Tiempo (s)';
  else
      eje_t = linspace(0, 1, n)';
      eje_t_label = 'Fase del ciclo (-)';
  end

  try
      figure('name', 'AOS BM / Gibbs - Vista operativa v12', 'numbertitle', 'off', 'position', [80 80 1500 850]);
  catch
      figure;
  end

  % 1) Lectura rapida por semaforos: spots de color, no solo texto.
  subplot(2,3,1);
  axis off;
  hold on;
  xlim([0 1]); ylim([0 1]);
  text(0.05, 0.95, 'Semaforos operativos', 'fontweight', 'bold', 'units', 'normalized');
  y = 0.84;
  if isfield(diag, 'semaforo') && isstruct(diag.semaforo)
      general = leer_campo_txt(diag.semaforo, 'general', 'S/D');
      dibujar_spot(0.08, y, general, 11);
      text(0.15, y, sprintf('GENERAL: %s', general), 'fontweight', 'bold', 'units', 'normalized');
      y = y - 0.10;
      if isfield(diag.semaforo, 'descripcion')
          text(0.05, y, diag.semaforo.descripcion, 'units', 'normalized');
          y = y - 0.11;
      end
      if isfield(diag.semaforo, 'items')
          for i = 1:length(diag.semaforo.items)
              it = diag.semaforo.items(i);
              nombre = leer_campo_txt(it, 'nombre', sprintf('item %d', i));
              estado = leer_campo_txt(it, 'estado', 's/d');
              dibujar_spot(0.08, y, estado, 9);
              text(0.15, y, sprintf('%s', nombre), 'units', 'normalized');
              text(0.72, y, estado, 'units', 'normalized');
              y = y - 0.080;
              if y < 0.05, break; end
          end
      end
  else
      text(0.05, y, 'Semaforo no disponible.', 'units', 'normalized');
  end
  hold off;

  % 2) Transmision de carrera: posicion vs tiempo/fase.
  subplot(2,3,2);
  plot(eje_t, carta_sup(:,1), '-', eje_t, carta_fondo(:,1), '-');
  xlabel(eje_t_label);
  ylabel('Posicion (m)');
  title('Transmision de carrera');
  legend('Superficie', 'Fondo');
  grid on;
  aplicar_aspecto_apaisado(1.60);

  % 3) Transmision de carga: carga vs tiempo/fase.
  subplot(2,3,3);
  plot(eje_t, carta_sup(:,2)/1000, '-', eje_t, carta_fondo(:,2)/1000, '-');
  xlabel(eje_t_label);
  ylabel('Carga (kN)');
  title('Transmision de carga');
  legend('Superficie', 'Fondo');
  grid on;
  aplicar_aspecto_apaisado(1.60);

  % 4) Carta dinamometrica de superficie.
  subplot(2,3,4);
  plot(carta_sup(:,1), carta_sup(:,2)/1000, '-');
  xlabel('Posicion punto pulido (m)');
  ylabel('Carga (kN)');
  title('Carta superficie');
  grid on;
  ajustar_ejes_carta(carta_sup);
  aplicar_aspecto_apaisado(1.80);

  % 5) Carta dinamometrica de fondo.
  subplot(2,3,5);
  plot(carta_fondo(:,1), carta_fondo(:,2)/1000, '-');
  xlabel('Posicion piston/fondo (m)');
  ylabel('Carga (kN)');
  title('Carta fondo - Gibbs');
  grid on;
  ajustar_ejes_carta(carta_fondo);
  aplicar_aspecto_apaisado(2.10);

  % 6) Resumen numerico y notas.
  subplot(2,3,6);
  axis off;
  y = 0.95;
  escribir('Resumen BM / Gibbs', y, true); y = y - 0.10;
  if isfield(diag, 'S_superficie_m')
      escribir(sprintf('S superficie: %.3f m', diag.S_superficie_m), y, false); y = y - 0.075;
  end
  if isfield(diag, 'S_fondo_m')
      escribir(sprintf('S fondo: %.3f m', diag.S_fondo_m), y, false); y = y - 0.075;
  end
  if isfield(diag, 'S_superficie_m') && isfield(diag, 'S_fondo_m')
      tr = diag.S_fondo_m / max(diag.S_superficie_m, 1e-9);
      escribir(sprintf('Transmision: %.2f', tr), y, false); y = y - 0.075;
  end
  if isfield(diag, 'llenado_bomba')
      escribir(sprintf('Llenado: %.0f %%', diag.llenado_bomba * 100), y, false); y = y - 0.075;
  end
  if isfield(diag, 'Q_efectivo_m3s')
      escribir(sprintf('Q efectivo: %.1f m3/d', diag.Q_efectivo_m3s * 86400), y, false); y = y - 0.075;
  end
  if isfield(diag, 'espaciamiento') && isstruct(diag.espaciamiento) && isfield(diag.espaciamiento, 'recomendacion_m')
      escribir(sprintf('Espac.: %.2f m', diag.espaciamiento.recomendacion_m), y, false); y = y - 0.075;
  end
  if isfield(diag, 'modelo')
      y = y - 0.02;
      escribir(diag.modelo, y, false); y = y - 0.075;
  end
  escribir('Posicion + carga en tiempo = transmision dinamica.', y, false); y = y - 0.075;
  escribir('Cartas clasicas se mantienen para diagnostico tradicional.', y, false);
end

function dibujar_spot(x, y, estado, tam)
  if nargin < 4, tam = 9; end
  c = color_estado(estado);
  plot(x, y, 'o', 'markersize', tam, 'markerfacecolor', c, 'markeredgecolor', [0 0 0]);
end

function c = color_estado(estado)
  e = upper(strtrim(estado));
  if strcmp(e, 'VERDE')
      c = [0.0 0.65 0.0];
  elseif strcmp(e, 'AMARILLO')
      c = [1.0 0.80 0.0];
  elseif strcmp(e, 'ROJO')
      c = [0.85 0.0 0.0];
  else
      c = [0.55 0.55 0.55];
  end
end

function aplicar_aspecto_apaisado(relacion)
  if nargin < 1, relacion = 1.6; end
  try
      pbaspect([relacion 1 1]);
  catch
      % pbaspect puede no estar disponible en versiones viejas de Octave.
  end
end

function ajustar_ejes_carta(carta)
  if isempty(carta) || size(carta,2) < 2, return; end
  x = carta(:,1);
  y = carta(:,2) / 1000;
  xmin = min(x); xmax = max(x);
  ymin = min(y); ymax = max(y);
  if isfinite(xmin) && isfinite(xmax) && xmax > xmin
      dx = max(0.06 * (xmax - xmin), 1e-6);
      xlim([xmin - dx, xmax + dx]);
  end
  if isfinite(ymin) && isfinite(ymax) && ymax > ymin
      dy = max(0.10 * (ymax - ymin), 1e-6);
      ylim([ymin - dy, ymax + dy]);
  end
end

function escribir(txt, y, negrita)
  if nargin < 3, negrita = false; end
  if y < 0.02, return; end
  if negrita
      text(0.02, y, txt, 'units', 'normalized', 'fontweight', 'bold');
  else
      text(0.02, y, txt, 'units', 'normalized');
  end
end

function val = leer_campo_txt(s, campo, defecto)
  val = defecto;
  if isstruct(s) && isfield(s, campo)
      [tmp, ok] = aos_texto_seguro(s.(campo), defecto);
      if ok && ~isempty(tmp), val = tmp; endif
  endif
endfunction
