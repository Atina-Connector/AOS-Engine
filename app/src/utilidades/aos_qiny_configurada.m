function [Q_m3s, fuente] = aos_qiny_configurada(param)
% Busca Qiny configurado y lo devuelve en m3/s estandar.
% La seleccion fija del usuario tiene prioridad sobre cualquier alias del
% .aosdat, para cualquier valor >= 0.
  Q_m3s = [];
  fuente = '';
  if nargin < 1 || ~isstruct(param), return; end

  if isfield(param,'qiny_modo') && ischar(param.qiny_modo) && ...
     strcmpi(strtrim(param.qiny_modo),'automatico')
    fuente = 'automatico';
    return;
  end

  if isfield(param,'Q_iny') && isnumeric(param.Q_iny) && isscalar(param.Q_iny) && isfinite(param.Q_iny)
    Q_m3s = max(param.Q_iny,0);
    if isfield(param,'qiny_modo') && ischar(param.qiny_modo) && strcmpi(strtrim(param.qiny_modo),'fijo')
      fuente = 'Q_iny_usuario_fijo';
    else
      fuente = 'Q_iny';
    end
    return;
  end

  campos_sm3d = {'Qiny_sim_Sm3_d','Qiny_ref_Sm3_d','Qiny_Sm3_d','Q_iny_Sm3_d','Qiny_sm3d','Q_iny_sm3d'};
  for i = 1:length(campos_sm3d)
    c = campos_sm3d{i};
    if isfield(param,c) && isnumeric(param.(c)) && isscalar(param.(c)) && isfinite(param.(c))
      Q_m3s = param.(c) / 86400;
      fuente = c;
      return;
    end
  end

  campos_mmscfd = {'Qiny_MMscfd','Qiny_ref_MMscfd','Qiny_sim_MMscfd','Q_iny_MMscfd'};
  for i = 1:length(campos_mmscfd)
    c = campos_mmscfd{i};
    if isfield(param,c) && isnumeric(param.(c)) && isscalar(param.(c)) && isfinite(param.(c))
      Q_m3s = param.(c) * 1e6 * 0.028316846592 / 86400;
      fuente = c;
      return;
    end
  end
end
