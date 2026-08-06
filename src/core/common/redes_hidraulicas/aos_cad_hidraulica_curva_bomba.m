function [head_m, adv, diag] = aos_cad_hidraulica_curva_bomba(curva, Ql_m3s, cfg)
% AOS_CAD_HIDRAULICA_CURVA_BOMBA Interpolacion lineal head(Q) con saturacion.
%   [head_m, adv, diag] = aos_cad_hidraulica_curva_bomba(curva, Ql_m3s, cfg)
% curva: struct con Q_m3d / H_m (o alias) o vectores numericos; valores pueden
%        ser aos_aoscad_campo. Interpolacion lineal, sin splines.
% Advertencias: CURVA_INSUFICIENTE_PUNTOS, CURVA_EXTRAPOLADA,
%               CURVA_NO_MONOTONA, CURVA_HEAD_NEGATIVO_CLAMPEADO.
  if nargin < 3, cfg = struct(); endif %#ok<NASGU>
  head_m = 0;
  adv = {};
  diag = struct('n_puntos', 0, 'Q_eval_m3d', [], 'saturado', false, ...
                'fuente', '', 'Q_min_m3d', [], 'Q_max_m3d', []);

  [Q, H] = extraer_QH_local(curva);
  diag.n_puntos = numel(Q);
  if numel(Q) < 2 || numel(H) < 2 || numel(Q) ~= numel(H)
    adv{end+1} = 'CURVA_INSUFICIENTE_PUNTOS';
    return;
  endif

  % Ordenar por caudal
  [Q, ord] = sort(Q(:));
  H = H(ord);
  H = H(:);

  % Colapsar caudales duplicados (promedio de head)
  [Qu, ~, ic] = unique(Q, 'stable');
  if numel(Qu) < numel(Q)
    Hu = zeros(size(Qu));
    for i = 1:numel(Qu)
      Hu(i) = mean(H(ic == i));
    endfor
    Q = Qu; H = Hu;
  endif
  if numel(Q) < 2
    adv{end+1} = 'CURVA_INSUFICIENTE_PUNTOS';
    return;
  endif

  diag.n_puntos = numel(Q);
  diag.Q_min_m3d = Q(1);
  diag.Q_max_m3d = Q(end);
  if isstruct(curva) && isfield(curva, 'fuente')
    diag.fuente = char(curva.fuente);
  endif

  % Monotonia decreciente (advertencia auditable; se usa igual)
  dH = diff(H);
  if any(dH > 1e-12)
    adv{end+1} = 'CURVA_NO_MONOTONA';
  endif

  if isempty(Ql_m3s) || ~isfinite(Ql_m3s)
    Qd = Q(1);
  else
    Qd = abs(Ql_m3s) * 86400;
  endif
  diag.Q_eval_m3d = Qd;

  if Qd < Q(1) - 1e-12 || Qd > Q(end) + 1e-12
    diag.saturado = true;
    adv{end+1} = 'CURVA_EXTRAPOLADA';
    if Qd < Q(1)
      head_m = H(1);
    else
      head_m = H(end);
    endif
  else
    head_m = interp1(Q, H, Qd, 'linear');
  endif

  if ~isfinite(head_m)
    head_m = 0;
    adv{end+1} = 'CURVA_INSUFICIENTE_PUNTOS';
    return;
  endif

  if head_m < 0
    head_m = 0;
    adv{end+1} = 'CURVA_HEAD_NEGATIVO_CLAMPEADO';
  endif
endfunction

function [Q, H] = extraer_QH_local(curva)
  Q = []; H = [];
  if isempty(curva), return; endif
  if isnumeric(curva) && size(curva, 2) >= 2
    Q = curva(:, 1); H = curva(:, 2);
    return;
  endif
  if ~isstruct(curva), return; endif

  Q = primer_campo_local(curva, {'Q_m3d', 'curva_Q_m3d', 'Q', 'q'});
  H = primer_campo_local(curva, {'H_m', 'curva_H_m', 'H', 'h', 'head_m'});
  Q = vector_num_local(Q);
  H = vector_num_local(H);
endfunction

function v = primer_campo_local(s, nombres)
  v = [];
  for i = 1:numel(nombres)
    if isfield(s, nombres{i})
      v = s.(nombres{i});
      return;
    endif
  endfor
endfunction

function v = vector_num_local(x)
  v = [];
  if isempty(x), return; endif
  if isstruct(x)
    x = aos_aoscad_valor(x);
  endif
  if iscell(x)
    tmp = [];
    for i = 1:numel(x)
      xi = x{i};
      if isstruct(xi), xi = aos_aoscad_valor(xi); endif
      if isnumeric(xi) && ~isempty(xi)
        tmp(end+1:end+numel(xi)) = xi(:)'; %#ok<AGROW>
      endif
    endfor
    v = tmp(:);
    return;
  endif
  if isnumeric(x)
    v = x(:);
  endif
endfunction
