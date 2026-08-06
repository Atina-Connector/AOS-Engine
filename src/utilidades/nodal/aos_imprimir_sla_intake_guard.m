function aos_imprimir_sla_intake_guard(estado)
% Imprime una linea de diagnostico SLA intake.
  if nargin < 1 || ~isstruct(estado), return; end
  if ~isfield(estado, 'codigo') || strcmp(estado.codigo, 'OK')
      return;
  end
  fprintf('\n[%s] INTAKE / RESERVORIO (%s)\n', estado.color, estado.sistema);
  fprintf('%s\n', estado.mensaje);
  if isfield(estado, 'P_intake') && isfinite(estado.P_intake)
      fprintf('Presion intake/succion calculada: %.2f bar\n', estado.P_intake/1e5);
  end
  if isfield(estado, 'Ql') && isfinite(estado.Ql)
      fprintf('Caudal asociado: %.2f m3/d\n', estado.Ql*86400);
  end
end
