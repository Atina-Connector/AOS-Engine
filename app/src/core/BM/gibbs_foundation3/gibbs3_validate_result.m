function [ok, mensajes] = gibbs3_validate_result(res)
% GIBBS3_VALIDATE_RESULT Comprueba finitud, cierre y periodicidad.
  mensajes={}; ok=true;
  requeridos={'t','U','V','F_superficie_N','F_bomba_N','promedio','metricas', ...
    'diseno_sarta_espaciamiento','verificacion_aparato'};
  for k=1:numel(requeridos)
    if ~isfield(res,requeridos{k})
      mensajes{end+1}=sprintf('Falta el campo %s.',requeridos{k}); %#ok<AGROW>
      ok=false;
    end
  end
  if ~ok, return; end
  if any(~isfinite(res.U(:))) || any(~isfinite(res.F_superficie_N(:))) || ...
      any(~isfinite(res.F_bomba_N(:)))
    mensajes{end+1}='El resultado contiene NaN o Inf.';
    ok=false;
  end
  tol=res.param.gibbs3_tolerancia_cierre_m;
  if abs(res.promedio.u_superficie_m(1)-res.promedio.u_superficie_m(end))>tol
    mensajes{end+1}='La carta superficial no cierra numericamente.';
    ok=false;
  end
  if abs(res.promedio.u_bomba_m(1)-res.promedio.u_bomba_m(end))>tol
    mensajes{end+1}='La carta de fondo no cierra numericamente.';
    ok=false;
  end
  if ~res.metricas.periodicidad_aprobada
    mensajes{end+1}=sprintf('Periodicidad fuera de tolerancia: %.5g.', ...
      res.metricas.error_periodicidad_rel);
  end
  % Convencion fisica de tubing libre: elongacion positiva, movimiento del
  % barril hacia abajo y posicion relativa piston-barril por diferencia.
  if isfield(res, 'param') && isfield(res.param, 'tuberia_anclada') && ...
      ~logical(res.param.tuberia_anclada)
    tol_signo = max(tol, 1e-10);
    tiene_campos = isfield(res, 'tuberia') && isstruct(res.tuberia) && ...
      isfield(res.tuberia, 'elongacion_m') && ...
      isfield(res.tuberia, 'u_fondo_m') && ...
      isfield(res.tuberia, 'rigidez_axial_N_m') && ...
      isfield(res.promedio, 'u_tuberia_fondo_m') && ...
      isfield(res.promedio, 'u_varilla_fondo_m') && ...
      isfield(res.promedio, 'u_piston_relativo_m');
    if ~tiene_campos
      mensajes{end+1} = ...
        'Tuberia libre sin campos de signo fisico GF3 v1.8.';
      ok = false;
    else
      elong = res.tuberia.elongacion_m(:);
      utub = res.promedio.u_tuberia_fondo_m(:);
      urod = res.promedio.u_varilla_fondo_m(:);
      urel = res.promedio.u_piston_relativo_m(:);
      F = res.promedio.F_bomba_N(:);
      kax = res.tuberia.rigidez_axial_N_m;
      if numel(elong) ~= numel(utub) || numel(utub) ~= numel(urod) || ...
          numel(urod) ~= numel(urel) || numel(F) ~= numel(elong)
        mensajes{end+1} = ...
          'Vectores de tubing libre con longitudes incompatibles.';
        ok = false;
      else
        escala_u = max([max(abs(elong)), max(abs(utub)), 1]);
        if any(~isfinite(elong)) || any(elong < -tol_signo) || ...
            max(abs(utub + elong)) > tol_signo*escala_u
          mensajes{end+1} = ...
            'Signo de tubing libre invalido: el barril debe bajar al elongarse.';
          ok = false;
        endif
        if max(abs(urel - (urod - utub))) > tol_signo*escala_u
          mensajes{end+1} = ...
            'Posicion piston-barril inconsistente con el movimiento del tubing.';
          ok = false;
        endif
        if ~isfinite(kax) || kax <= 0
          mensajes{end+1} = 'Rigidez axial de tubing no positiva.';
          ok = false;
        endif
        dF = diff(F);
        de = diff(elong);
        activo = abs(de) > tol_signo;
        if any(dF(activo).*de(activo) < -tol_signo)
          mensajes{end+1} = ...
            'Rigidez aparente de tubing negativa durante transferencia de carga.';
          ok = false;
        endif
        if any(activo)
          kobs = dF(activo)./de(activo);
          errk = max(abs(kobs-kax))/max(kax,eps);
          if any(~isfinite(kobs)) || any(kobs <= 0) || errk > 1e-8
            mensajes{end+1} = ...
              'Pendiente elastica del tubing no coincide con E*A/L.';
            ok = false;
          endif
        endif
      endif
    endif
  endif

  if isfield(res, 'diseno_sarta_espaciamiento') && ...
      isfield(res.diseno_sarta_espaciamiento, 'espaciamiento')
    e = res.diseno_sarta_espaciamiento.espaciamiento;
    % Acepta el contrato publico vigente y el alias historico. El flujo
    % normal migra antes de validar, pero esta tolerancia permite validar un
    % resultado residente sin depender del orden de llamada.
    flag_spacing = false;
    if isfield(e, 'valido_calculo') && ~isempty(e.valido_calculo)
      flag_spacing = logical(e.valido_calculo(1));
    elseif isfield(e, 'valido') && ~isempty(e.valido)
      flag_spacing = logical(e.valido(1));
    endif
    valido_spacing = flag_spacing && ...
      isfield(e, 'levantamiento_despues_sensar_mm') && ...
      isfinite(e.levantamiento_despues_sensar_mm) && ...
      e.levantamiento_despues_sensar_mm > 0;
    if ~valido_spacing
      detalle = 'Espaciamiento invalido: no existe un levantamiento finito y positivo.';
      if isfield(e, 'mensaje_validacion') && ischar(e.mensaje_validacion) && ...
          ~isempty(e.mensaje_validacion)
        detalle = ['Espaciamiento invalido: ' e.mensaje_validacion];
      elseif isfield(e, 'validacion') && ischar(e.validacion) && ...
          ~isempty(e.validacion)
        detalle = ['Espaciamiento invalido: ' e.validacion];
      end
      mensajes{end+1} = detalle;
      ok = false;
    elseif isfield(e, 'geometria_aprobada') && ~e.geometria_aprobada
      mensajes{end+1} = ...
        'El espaciamiento es finito, pero no cumple los clearances geometricos.';
      ok = false;
    end
  else
    mensajes{end+1} = 'No existe resultado de espaciamiento.';
    ok = false;
  end

  if isempty(mensajes), mensajes={'Resultado GF3 estructuralmente valido.'}; end
end
