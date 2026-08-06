function VERIFICAR_SENSIBILIDADES_AOS_0_0_12()
% Smoke test no interactivo de propagacion para GL, JGL, BES y BM.
% Ejecuta mallas pequenas y valida solicitado == efectivo.

  root=fileparts(mfilename('fullpath'));
  addpath(fullfile(root,'src'),'-begin'); iniciar_aos;
  global AOS_CIFRADO_ACTIVO; AOS_CIFRADO_ACTIVO=false;
  archivo=fullfile(root,'datos','ejemplos','MB01_15pts_2tercios_vertical.aosdat');
  if exist(archivo,'file')~=2, error('No se encontro el ejemplo MB01.'); end
  base=importar_aosdat(archivo); base=sens_preparar_base(base,'SENS_JGL');
  [qref,~]=aos_qiny_configurada(base); if isempty(qref),qref=16486/86400;end
  q=[0,qref,max(1.5*qref,30000/86400)];
  P=cell(1,numel(q));
  for i=1:numel(q),P{i}=aos_set_qiny(base,q(i)*86400,'fijo');end
  fallos=0;

  fprintf('\n=== SENSIBILIDADES GL/JGL ===\n');
  modos={'directo','iterativo','automatico'};
  for im=1:numel(modos)
      R=sens_jgl_gl_malla(P,q,modos{im});
      e1=max(abs(R.qiny_efectivo_GL-q));
      e2=max(abs(R.jgl.qiny_efectivo-q));
      fprintf('%-10s | error Qiny GL %.3g | error Qiny JGL %.3g | puntos iterativos %d\n', ...
          modos{im},e1,e2,sum(R.seleccion_iterativa));
      if e1>1e-9 || e2>1e-9, fallos=fallos+1; end
  end

  % Pwh y profundidad deben llegar al solver y conservar separacion SLA.
  p=base; p.P_wh=25e5; p=aos_set_profundidad(p,'JGL',2222); p=aos_set_qiny(p,qref*86400,'fijo');
  [~,~,~,~,~,~,sgl]=GL_puro_core(p); sj=jgl_solver_directo(p,qref);
  if abs(sgl.audit.P_wh_efectiva-25e5)>1 || abs(sj.audit.P_wh_efectiva-25e5)>1
      fprintf('[FALLO] Pwh solicitado no llego a GL/JGL.\n'); fallos=fallos+1;
  else
      fprintf('[OK] Pwh solicitado llega a GL/JGL.\n');
  end
  if abs(sgl.D_iny-2222)>1e-9 || abs(sj.audit.D_iny_efectiva-2222)>1e-9
      fprintf('[FALLO] D_iny solicitada no llego a GL/JGL.\n'); fallos=fallos+1;
  else
      fprintf('[OK] D_iny solicitada llega a GL/JGL.\n');
  end

  fprintf('\n=== SENSIBILIDAD BES ===\n');
  pb=sens_bes_preparar_base(base); pb=aos_set_profundidad(pb,'BES',1700);
  for f=[45,60]
      pp=pb; pp.frecuencia=f; rr=sens_bes_evaluar(pp);
      fprintf('f req %.1f | f eff %.1f | D bomba eff %.1f | estado %s\n', ...
          f,rr.audit.frecuencia_efectiva_Hz,rr.audit.D_bomba_efectiva_m,rr.estado);
      if abs(rr.audit.frecuencia_efectiva_Hz-f)>1e-9 || abs(rr.audit.D_bomba_efectiva_m-1700)>1e-9
          fallos=fallos+1;
      end
  end

  fprintf('\n=== BOMBEO MECANICO ===\n');
  bmfile=fullfile(root,'datos','ejemplos','test_bm_completo.aosdat');
  if exist(bmfile,'file')==2
      bm=importar_aosdat(bmfile); bm=aos_sincronizar_config(bm,'BM');
      for nspm=[4,8]
          bm.N_velocidad=nspm; bm=aos_sincronizar_config(bm,'BM');
          [~,~,~,~,det]=BM_core(bm);
          fprintf('SPM req %.1f | SPM eff %.1f | D bomba eff %.1f\n',nspm,det.audit.N_velocidad_efectiva,det.audit.D_bomba_efectiva);
          if abs(det.audit.N_velocidad_efectiva-nspm)>1e-9,fallos=fallos+1;end
      end
  else
      fprintf('AVISO: no se encontro test_bm_completo.aosdat; se omite smoke test numerico BM.\n');
  end

  if fallos>0,error('Fallo la verificacion de sensibilidades/SLA: %d fallo(s).',fallos);end
  fprintf('\nVERIFICACION DE SENSIBILIDADES Y SLA APROBADA.\n');
end
