function Qiny_vals = sens_agregar_qiny_referencia(Qiny_vals, base)
% Agrega al barrido el Qiny activo. Convencion unica: m3/s estandar.
  qref = NaN;
  if isfield(base, 'Qiny_plot') && isnumeric(base.Qiny_plot) && ~isempty(base.Qiny_plot)
      qref = base.Qiny_plot(1);
  elseif isfield(base, 'Q_iny') && isnumeric(base.Q_iny) && ~isempty(base.Q_iny)
      qref = base.Q_iny(1);
  else
      [qtmp, ~] = aos_qiny_configurada(base);
      if ~isempty(qtmp), qref = qtmp; end
  end
  if ~isfinite(qref), return; end
  vals = Qiny_vals(:)';
  if isempty(vals), return; end
  if qref >= min(vals) && qref <= max(vals)
      tol = 1e-10 * max(1, max(abs(vals)));
      if all(abs(vals - qref) > tol)
          Qiny_vals = sort([vals(:); qref])';
          fprintf('Se agrego Qiny de referencia: %s.\n', aos_formato_caudal_gas(qref));
      else
          Qiny_vals = vals;
      end
  else
      Qiny_vals = vals;
  end
end
