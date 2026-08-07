function [dp_Pa, r, adv] = aos_cad_hidraulica_dp_orientado(tramo, nodo_o, nodo_d, P_ref_Pa, Q_orientado_m3s, Qg_std_m3s, cfg, modelo)
% AOS_CAD_HIDRAULICA_DP_ORIENTADO Convencion de flujo reverso sin fisica nueva.
% Q_orientado > 0: sentido geometrico nodo_o -> nodo_d.
% Q_orientado < 0: se invierten extremos, se evalua |Q| y dp cambia de signo.
  if nargin < 8, modelo = struct(); endif
  if nargin < 7 || isempty(cfg), cfg = aos_cad_hidraulica_defaults(modelo); endif
  adv = {};
  cfg_eval = cfg;
  Q = Q_orientado_m3s;
  Qg = Qg_std_m3s;
  if ~isfinite(Qg), Qg = 0; endif

  if Q >= 0
    nodo_in = nodo_o; nodo_out = nodo_d;
    sentido = 'DIRECTO';
    if isfield(cfg_eval, 'sentido_flujo_reverso')
      cfg_eval = rmfield(cfg_eval, 'sentido_flujo_reverso');
    endif
    r = aos_cad_hidraulica_evaluar_tramo(tramo, nodo_in, nodo_out, ...
          P_ref_Pa, abs(Q), abs(Qg), cfg_eval, modelo);
    dp_Pa = r.dp_total_Pa;
  else
    nodo_in = nodo_d; nodo_out = nodo_o;
    sentido = 'REVERSO';
    cfg_eval.sentido_flujo_reverso = true;
    r = aos_cad_hidraulica_evaluar_tramo(tramo, nodo_in, nodo_out, ...
          P_ref_Pa, abs(Q), abs(Qg), cfg_eval, modelo);
    dp_Pa = -r.dp_total_Pa;
    if isfield(r, 'advertencias') && iscell(r.advertencias)
      for i = 1:numel(r.advertencias)
        adv{end+1} = r.advertencias{i}; %#ok<AGROW>
      endfor
    endif
  endif

  r.sentido_flujo = sentido;
  r.caudal_orientado_m3s = Q_orientado_m3s;
  if isfield(r, 'advertencias') && iscell(r.advertencias)
    for i = 1:numel(r.advertencias)
      if ~any(strcmp(adv, r.advertencias{i}))
        adv{end+1} = r.advertencias{i}; %#ok<AGROW>
      endif
    endfor
  endif
endfunction
