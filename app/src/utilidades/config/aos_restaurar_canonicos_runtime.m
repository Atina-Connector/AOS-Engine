function cfg = aos_restaurar_canonicos_runtime(cfg, snap)
% Restaura valores canonicos capturados antes de interpretar aliases.
  if nargin < 1 || ~isstruct(cfg), cfg = struct(); end
  if nargin < 2 || ~isstruct(snap), return; end
  campos = fieldnames(snap);
  for i = 1:length(campos)
    cfg.(campos{i}) = snap.(campos{i});
  end
end
