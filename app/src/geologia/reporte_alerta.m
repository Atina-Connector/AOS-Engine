function diagnostico = reporte_alerta(Ql, geol, param)
% Reporte geologico operativo AOS.
% Si los datos son incompletos, construye un modelo generico trazable,
% informa escenarios y evita convertir estimaciones en limites operativos.

  if nargin < 2 || isempty(geol)
      global geologia;
      if isempty(geologia), error('No hay geologia cargada.'); end
      geol = geologia;
  end
  if nargin < 3, param = struct(); end
  crit = calcular_caudales_criticos(geol, Ql, param);
  diagnostico = crit;
  factor_d=86400; Ql_d=Ql*factor_d;
  Qa=crit.Q_arena*factor_d; Qe=crit.Q_erosion*factor_d; Qs=crit.Q_seguro*factor_d;
  ra=Ql>crit.Q_arena; re=Ql>crit.Q_erosion; rs=Ql>crit.Q_seguro;
  ma=(1-Ql_d/max(Qa,1e-9))*100; me=(1-Ql_d/max(Qe,1e-9))*100; ms=(1-Ql_d/max(Qs,1e-9))*100;

  fprintf('\n================ REPORTE GEOLOGICO / INTEGRIDAD AOS ================\n');
  fprintf('Caudal actual de liquido : %.2f m3/d\n', Ql_d);
  c=crit.confianza_geologica;
  fprintf('Tipo de modelo geologico : %s\n', c.tipo);
  fprintf('Confianza geologica      : %s (%d %%)\n', c.nivel, c.puntaje);
  if ~c.uso_operativo
      fprintf('Uso recomendado          : screening rapido y priorizacion de estudios.\n');
      fprintf('Uso no recomendado       : limite operativo final o dimensionamiento automatico de choke.\n');
  end

  if isfield(crit,'distribucion_punzados') && ~isempty(crit.distribucion_punzados)
      d=crit.distribucion_punzados;
      fprintf('---------------------------------------------------------------------\n');
      fprintf('APORTE DISTRIBUIDO POR INTERVALO (midperf solo referencia)\n');
      fprintf(' Tramo MD (m)        Tiros  Frac.   Ql(m3/d) Qo(m3/d) Qw(m3/d) Ql/tiro\n');
      for i=1:length(d.tramos)
          x=d.tramos(i);
          fprintf('%7.1f-%7.1f  %5d  %5.1f%%  %8.3f %8.3f %8.3f %8.4f\n', ...
              x.MD_desde_m,x.MD_hasta_m,x.n_tiros,100*x.fraccion_aporte, ...
              x.Ql_m3d,x.Qo_m3d,x.Qw_m3d,x.Ql_por_tiro_m3d);
      end
      fprintf('TOTAL                 %5d 100.0%%  %8.3f %8.3f %8.3f\n', ...
          d.n_tiros_total,d.Ql_total_m3d,d.Qo_total_m3d,d.Qw_total_m3d);
  end

  fprintf('---------------------------------------------------------------------\n');
  fprintf('LIMITES EVALUABLES / PROVISIONALES\n');
  fprintf('Arenamiento : %.2f m3/d  %s  margen %+.0f %%\n',Qa,semaforo(ma,ra),ma);
  fprintf('Erosion     : %.2f m3/d  %s  margen %+.0f %%\n',Qe,semaforo(me,re),me);
  if crit.conificacion_vinculante
      Qc=crit.Q_conifica*factor_d; rc=Ql>crit.Q_conifica; mc=(1-Ql_d/max(Qc,1e-9))*100;
      fprintf('Conificacion: %.2f m3/d  %s  margen %+.0f %%\n',Qc,semaforo(mc,rc),mc);
  else
      g=crit.conificacion_generica;
      fprintf('Conificacion: ANALISIS GENERICO NO VINCULANTE\n');
      fprintf('  Escenario conservador : %.4f m3/d\n',g.Q_conservador_m3d);
      fprintf('  Escenario probable    : %.4f m3/d\n',g.Q_probable_m3d);
      fprintf('  Escenario favorable   : %.4f m3/d\n',g.Q_favorable_m3d);
      fprintf('  Estado                 : %s\n',g.estado);
      fprintf('  Interpretacion         : %s\n',g.interpretacion);
  end
  fprintf('Caudal seguro provisional (FS=%.2f): %.2f m3/d\n',geol.factor_seguridad,Qs);
  fprintf('Mecanismo vinculante evaluado       : %s\n',crit.mecanismo_vinculante);
  if crit.Q_seguro_provisional
      fprintf('ADVERTENCIA: el caudal seguro es provisional por incertidumbre geologica.\n');
  end

  fprintf('---------------------------------------------------------------------\n');
  if rs
      fprintf('ESTADO GLOBAL: PRECAUCION. El caudal supera un limite evaluable.\n');
  else
      fprintf('ESTADO GLOBAL: dentro de los limites evaluables, sujeto a incertidumbre.\n');
  end

  if isfield(crit,'conificacion_generica')
      fprintf('\nDATOS QUE MAS REDUCIRIAN LA INCERTIDUMBRE:\n');
      est=crit.conificacion_generica.estudios_recomendados;
      for i=1:length(est), fprintf(' - %s\n',est{i}); end
  end

  if rs && crit.recomendar_choke && exist('dimensionar_choke','file')==2
      [dc,alerta]=dimensionar_choke(Qs,param);
      fprintf('\nRECOMENDACION DE CHOKE (solo por modelo especifico de alta confianza)\n');
      fprintf('Diametro estimado: %.1f mm\n',dc);
      if ~isempty(alerta), fprintf('%s\n',alerta); end
  elseif rs
      fprintf('\nNo se recomienda choke automatico: la geologia no tiene confianza suficiente.\n');
  end
  fprintf('=====================================================================\n');
end

function s=semaforo(m,r)
  if r, s='ROJO'; elseif m<10, s='AMARILLO'; else s='VERDE'; end
end
