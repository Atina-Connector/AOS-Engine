function [prun,accion] = bes3_seleccionar_estado_operativo(param)
% Seleccion explicita de frecuencia. 0 Hz activa el solver de flujo natural.
  p=bes3_defaults(param);prun=p;accion='cancelar';
  fcfg=p.frecuencia;
  if isfield(p,'bes3_frecuencia_configurada_Hz') && isnumeric(p.bes3_frecuencia_configurada_Hz) && ...
      ~isempty(p.bes3_frecuencia_configurada_Hz) && isfinite(p.bes3_frecuencia_configurada_Hz(1))
    fcfg=max(p.bes3_frecuencia_configurada_Hz(1),0);
  endif
  fprintf('\n--- CONDICION OPERATIVA BES3 ---\n');
  fprintf('Frecuencia configurada: %.2f Hz\n',fcfg);
  fprintf('1 - Usar frecuencia configurada\n');
  fprintf('2 - Forzar frecuencia manual para esta corrida (admite 0 Hz)\n');
  fprintf('3 - Bomba apagada / flujo natural (0 Hz)\n');
  fprintf('4 - Comparar bomba apagada vs bomba encendida\n');
  fprintf('0 - Cancelar\n');
  op=input('Seleccione: ');if isempty(op),op=1;endif
  switch op
    case 1
      f=fcfg;accion='simular';modo='configurada';
    case 2
      f=input(sprintf('Frecuencia solicitada en Hz [%.2f]: ',fcfg));
      if isempty(f),f=fcfg;endif
      if ~isnumeric(f)||~isscalar(f)||~isfinite(f)||f<0
        fprintf('Frecuencia invalida. Operacion cancelada.\n');return;
      endif
      accion='simular';modo='manual_forzada';
    case 3
      f=0;accion='simular';modo='bomba_apagada';
    case 4
      f=fcfg;if f<=0,f=60;endif
      v=input(sprintf('Frecuencia para el caso encendido [%.2f Hz]: ',f));if ~isempty(v),f=v;endif
      if ~isnumeric(f)||~isscalar(f)||~isfinite(f)||f<=0
        fprintf('La comparacion requiere una frecuencia encendida mayor que cero.\n');return;
      endif
      accion='comparar';modo='comparacion_on_off';
    otherwise
      return;
  endswitch
  prun.bes3_frecuencia_configurada_Hz=fcfg;
  prun.bes3_frecuencia_solicitada_Hz=max(f,0);
  prun.bes3_frecuencia_efectiva_Hz=max(f,0);
  prun.bes3_modo_frecuencia=modo;
  prun.frecuencia=max(f,0);
  prun.bes3_frecuencia_on_comparacion_Hz=max(f,0);
  if prun.frecuencia<=0
    prun.bes3_estado_bomba='apagada';
  else
    prun.bes3_estado_bomba='encendida';
  endif
  prun=bes3_defaults(prun);
endfunction
