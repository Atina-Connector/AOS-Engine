function h = mandriles_plot_v2(R)
  h=figure('Name','AOS - Diseno de Mandriles V2', ...
      'Position',[80 80 1200 650]);

  subplot(1,2,1);
  hold on;
  plot(R.casing_estatico.P/1e5,R.casing_estatico.MD,'--','LineWidth',1.8);
  plot(R.casing_dinamico.P/1e5,R.casing_dinamico.MD,'-','LineWidth',1.8);

  t0=mandriles_perfil_tubing_unloading(R.param,R.survey, ...
      R.nivel_inicial.MD_m,R.nivel_inicial.MD_m,0,0);
  plot(t0.P/1e5,t0.MD,':','LineWidth',1.5);

  for k=1:numel(R.valvulas)
    v=R.valvulas(k);
    t=mandriles_perfil_tubing_unloading(R.param,R.survey, ...
        R.nivel_inicial.MD_m,v.MD_m,v.Qg_perfil_m3d,v.Ql_perfil_m3d);
    if k==numel(R.valvulas)
      plot(t.P/1e5,t.MD,'LineWidth',2.2);
    else
      plot(t.P/1e5,t.MD,'LineWidth',1.0);
    endif
  endfor

  xl=xlim;
  plot(xl,[R.nivel_inicial.MD_m R.nivel_inicial.MD_m],':','LineWidth',1.3);
  for i=1:numel(R.valvulas)
    v=R.valvulas(i);
    plot(v.Pc_est_bar,v.MD_m,'ko','MarkerFaceColor','k');
    text(v.Pc_est_bar,v.MD_m,sprintf(' V%d',i));
  endfor
  set(gca,'YDir','reverse');
  grid on;
  xlabel('Presion (bar)');
  ylabel('MD (m)');
  title('Secuencia de unloading - perfiles compresibles');

  subplot(1,2,2);
  hold on;
  if ~isempty(R.valvulas)
    md=[R.valvulas.MD_m];
    use=100*[R.valvulas.utilizacion];
    stem(use,md,'filled');
    for i=1:numel(md)
      text(use(i),md(i),sprintf(' %.1f mm',R.valvulas(i).puerto_mm));
    endfor
  endif
  set(gca,'YDir','reverse');
  grid on;
  xlabel('Utilizacion capacidad (%)');
  ylabel('MD (m)');
  title('Galeria y puertos');
  drawnow;
endfunction
