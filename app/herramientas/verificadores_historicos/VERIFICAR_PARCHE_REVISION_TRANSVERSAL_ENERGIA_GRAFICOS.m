function VERIFICAR_PARCHE_REVISION_TRANSVERSAL_ENERGIA_GRAFICOS()
% Verifica contrato energetico canonico y registro de 3 graficos.
  fprintf('\n=== VERIFICACION TRANSVERSAL ENERGIA + GRAFICOS ===\n');
  iniciar_aos;
  requeridos={'aos_balance_energia_sla','aos_metricas_energia_sla', ...
    'aos_imprimir_balance_energia_sla','aos_registro_graficos', ...
    'aos_rpt_exportar_graficos_sensibilidad','sens_auditar_indice_jgl_gl'};
  for i=1:numel(requeridos)
    assert(exist(requeridos{i},'file')==2,sprintf('Falta %s',requeridos{i}));
  endfor

  p=struct('D_iny',1800,'D_res',2600,'T_sup',25,'T_fondo',90, ...
    'GLR',120,'Bo',1.08,'P_iny_sup',110e5,'rho_g_std',0.85,'Z_gas',0.9);
  ql=150/86400;qo=90/86400;qiny=22000/86400;
  sj=struct('Ps',55e5,'Pd',78e5,'Pm',135e5, ...
    'potencia_disponible',20000,'potencia_transferida',6000);
  ej=aos_balance_energia_sla('JGL',p,ql,qo,qiny,sj);
  mj=aos_metricas_energia_sla(ej,'JGL');
  assert(isfinite(mj.indice_energetico_bruto_fondo_pct));
  assert(abs(mj.eficiencia_interna_jet_pct-30)<1e-8);
  assert(~strcmp(mj.estado_indice_energetico_bruto,'NO_EVALUABLE'));

  sg=struct('Ps',78e5,'Pm',135e5);
  eg=aos_balance_energia_sla('GL',p,ql,qo,qiny,sg);
  mg=aos_metricas_energia_sla(eg,'GL');
  assert(isfinite(mg.indice_energetico_bruto_fondo_pct));
  assert(~isfinite(mg.eficiencia_interna_jet_pct));

  e0=aos_balance_energia_sla('JGL',p,ql,qo,0,sj);
  m0=aos_metricas_energia_sla(e0,'JGL');
  assert(~isfinite(m0.indice_energetico_bruto_fondo_pct));
  assert(strcmp(m0.estado_indice_energetico_bruto,'NO_APLICABLE_QINY_CERO'));
  fprintf('Contrato energetico GL/JGL: OK.\n');

  aud=sens_auditar_indice_jgl_gl([0 10000 20000],[NaN 120 130],[NaN 110 135],1e-6);
  assert(aud.n_jgl_menor_gl==1);
  fprintf('Auditoria comparativa sin clamp: OK.\n');

  aos_registro_graficos('reset','VERIFICADOR_3_GRAFICOS');
  figs=[];tmp='';fid=-1;toolkits={};
  try
    toolkits=available_graphics_toolkits();
  catch
    toolkits={};
  end_try_catch
  if isempty(toolkits)
    fprintf('PRUEBA GRAFICA OMITIDA: no hay toolkit grafico disponible.\n');
    fprintf('Repita esta prueba en una sesion Octave con toolkit grafico.\n');
  else
    try
      for k=1:3
        h=figure('Visible','off');figs(end+1)=h;
        plot(1:5,(1:5)*k);title(sprintf('Verificador grafico %d',k));
        aos_registro_graficos('add',h,sprintf('verificador_%02d',k), ...
          sprintf('Verificador grafico %d',k),'SENSIBILIDAD','VERIFICADOR_3_GRAFICOS');
      endfor
      ar=aos_registro_graficos('audit','VERIFICADOR_3_GRAFICOS');
      assert(ar.n_registrados==3 && ar.n_handles_validos==3);
      tmp=[tempname '.aosrpt'];fid=fopen(tmp,'w');assert(fid>=0);
      paq=struct('columnas',{{1:5}});
      ex=aos_rpt_exportar_graficos_sensibilidad(fid,paq,struct(),'JGL_GL',tmp);
      fclose(fid);fid=-1;
      assert(ex.n_generados==3);
      assert(ex.n_sensibilidad_exportados==3);
      txt=fileread(tmp);
      assert(~isempty(strfind(txt,'figuras_registradas=3')));
      assert(~isempty(strfind(txt,'figuras_sensibilidad_exportadas=3')));
      fprintf('Registro y exportacion de 3 graficos: OK.\n');
    catch err
      if fid>=0
        try
          fclose(fid);
        catch
        end_try_catch
      endif
      for k=1:numel(figs)
        try
          close(figs(k));
        catch
        end_try_catch
      endfor
      if ~isempty(tmp)&&exist(tmp,'file')==2,delete(tmp);endif
      rethrow(err);
    end_try_catch
  endif
  for k=1:numel(figs)
    try
      close(figs(k));
    catch
    end_try_catch
  endfor
  if ~isempty(tmp)&&exist(tmp,'file')==2,delete(tmp);endif

  archivos={'sens_Qiny','sens_Qiny_GL','sens_Qiny_JGL','sens_balance_energetico'};
  for i=1:numel(archivos)
    f=which(archivos{i});assert(~isempty(f));txt=fileread(f);
    assert(~isempty(strfind(txt,'Indice_energetico_bruto')) || ...
      ~isempty(strfind(txt,'IndiceBruto')) || ~isempty(strfind(txt,'IndiceJ')));
  endfor
  fprintf('Integracion de sensibilidades: OK.\n');

  % Verificacion acumulativa de normalizacion Qiny.
  assert(exist('aos_resolver_qiny_configurado','file')==2,'Falta normalizador Qiny');
  assert(exist('aos_aplicar_opcion_qiny','file')==2,'Falta propagador Qiny');
  assert(exist('aos_menu_qiny','file')==2,'Falta menu Qiny');
  pq=struct('Qiny_efectivo_Sm3_d',19334);
  [qq,mq,fq]=aos_resolver_qiny_configurado(pq);
  assert(abs(qq*86400-19334)<1e-8);
  assert(strcmp(mq,'fijo'));
  assert(~isempty(fq));
  [pq2,iq]=aos_aplicar_opcion_qiny(pq,1,[]);
  assert(abs(pq2.Q_iny*86400-19334)<1e-8);
  assert(abs(iq.q_sm3d-19334)<1e-8);
  fprintf('Normalizacion y propagacion Qiny: OK.\n');

  % Verificacion no interactiva del analizador tecnico/economico.
  assert(exist('sens_optimo_inyeccion','file')==2,'Falta sens_optimo_inyeccion');
  assert(exist('sens_configurar_economia_inyeccion','file')==2,'Falta configurador economico');
  econ=struct('habilitado',true,'moneda','USD','valor_petroleo_por_m3',100, ...
    'costo_gas_por_1000Sm3',5,'costo_fijo_diario',0);
  oo=sens_optimo_inyeccion([0 10000 20000 30000],[NaN 100 115 110], ...
    [100 130 145 148],[50 65 72 74],[true true true true],econ);
  assert(strcmp(oo.estado,'OK'));
  assert(isfield(oo,'economico') && oo.economico.habilitado);
  fprintf('Optimo tecnico y economia de inyeccion: OK.\n');
  fprintf('\nVERIFICACION TRANSVERSAL FINALIZADA.\n');
endfunction
