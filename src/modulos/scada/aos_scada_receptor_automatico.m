function aos_scada_receptor_automatico(intervalo_s, ciclos)
% Receptor por carpeta. El servidor deposita paquetes en intercambio/scada/entrada.
% ciclos=0 mantiene el receptor activo hasta Ctrl+C.
  if nargin<1 || isempty(intervalo_s),intervalo_s=60;endif
  if nargin<2 || isempty(ciclos),ciclos=0;endif
  intervalo_s=max(5,round(intervalo_s));
  rutas=aos_scada_rutas();
  fprintf('\nRECEPTOR SCADA AOSDAT\n');
  fprintf('Entrada : %s\n',rutas.entrada);
  fprintf('Intervalo: %d s\n',intervalo_s);
  if ciclos==0,fprintf('Modo continuo. Detener con Ctrl+C.\n');endif
  n=0;
  while ciclos==0 || n<ciclos
    n=n+1;
    fprintf('\n[%s] Revision SCADA %d\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),n);
    aos_scada_procesar_bandeja(Inf);
    if ciclos==0 || n<ciclos,pause(intervalo_s);endif
  endwhile
endfunction
