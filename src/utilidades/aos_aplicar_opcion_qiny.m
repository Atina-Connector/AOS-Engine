function [p, info] = aos_aplicar_opcion_qiny(p, opcion, q_manual_sm3d)
% AOS_APLICAR_OPCION_QINY Aplica la politica comun de inyeccion GL/JGL.
% opcion 1: conserva el valor configurado/de referencia.
% opcion 2: fuerza el valor manual indicado (cualquier valor >= 0).
% opcion 3: calculo automatico.
% GNU Octave es el entorno objetivo.
  if nargin < 1 || ~isstruct(p), p=struct(); end
  if nargin < 2 || isempty(opcion), opcion=1; end
  if nargin < 3, q_manual_sm3d=[]; end
  opcion=round(opcion);
  info=struct('opcion',opcion,'modo','','q_sm3d',NaN,'fuente','');

  if opcion==1
    [qref, modo_ref, fuente]=aos_resolver_qiny_configurado(p);
    if isempty(qref)
      error(['No existe un Qiny configurado para conservar. ' ...
             'Seleccione la opcion 2 e ingrese un valor o la opcion 3 automatica.']);
    end
    qsm=qref*86400;
    p=aos_set_qiny(p,qsm,'fijo');
    p.Qiny_origen = fuente;
    p.Qiny_importado = ~isempty(strfind(upper(fuente),'EFECTIVO'));
    p.Qiny_modo_importado = modo_ref;
    info.modo='configurado'; info.q_sm3d=qsm; info.fuente=fuente;
  elseif opcion==2
    if isempty(q_manual_sm3d) || ~isnumeric(q_manual_sm3d) || ...
       ~isscalar(q_manual_sm3d) || ~isfinite(q_manual_sm3d) || q_manual_sm3d<0
      error('Qiny manual debe ser un numero escalar finito mayor o igual que cero, en Sm3/d.');
    end
    p=aos_set_qiny(p,q_manual_sm3d,'fijo');
    info.modo='manual'; info.q_sm3d=q_manual_sm3d; info.fuente='usuario';
  elseif opcion==3
    p=aos_set_qiny(p,0,'automatico');
    info.modo='automatico'; info.q_sm3d=NaN; info.fuente='modelo_presion_orificio';
  else
    error('Opcion Qiny invalida. Use 1, 2 o 3.');
  end
end
