function VERIFICAR_ESTABILIZACION_AOS_0_0_12()
% Verificacion transversal no interactiva para GNU Octave.
% Valida precedencia runtime, aliases, profundidades SLA, Qiny y estructura.

  root = fileparts(mfilename('fullpath'));
  preparar(root);
  fprintf('\n=== VERIFICACION TRANSVERSAL AOS 0.0.12 ===\n');
  fallos = 0;

  % Canonicos runtime frente a aliases antiguos del .aosdat.
  cfg = struct('aos_config_normalizada',true, ...
      'P_res',210e5,'P_res_bar',100, ...
      'P_wh',22e5,'P_wh_bar',11.77, ...
      'P_iny_sup',230e5,'P_iny_sup_bar',86.7, ...
      'P_b',75e5,'P_b_bar',0, ...
      'IP',22/86400/1e5,'IP_m3_d_bar',8.737, ...
      'WC',0.41,'GLR',123,'D_iny',2100,'D_bomba',1600, ...
      'A_n',23e-6,'A_n_m2',12e-6,'d_t',0.047,'d_t_m',0.038, ...
      'frecuencia',55,'num_etapas',137,'N_velocidad',9,'S_carrera',2.1);
  out = aos_sincronizar_config(cfg,'JGL');
  fallos = fallos + comprobar_num('P_wh runtime',out.P_wh,22e5,1e-6);
  fallos = fallos + comprobar_num('P_iny_sup runtime',out.P_iny_sup,230e5,1e-6);
  fallos = fallos + comprobar_num('P_b runtime',out.P_b,75e5,1e-6);
  fallos = fallos + comprobar_num('IP runtime',out.IP,22/86400/1e5,1e-14);
  fallos = fallos + comprobar_num('A_n runtime',out.A_n,23e-6,1e-12);
  fallos = fallos + comprobar_num('d_t runtime',out.d_t,0.047,1e-12);
  fallos = fallos + comprobar_num('frecuencia BES runtime',out.frecuencia,55,1e-12);
  fallos = fallos + comprobar_num('etapas BES runtime',out.num_etapas,137,1e-12);
  fallos = fallos + comprobar_num('velocidad BM runtime',out.N_velocidad,9,1e-12);
  fallos = fallos + comprobar_num('carrera BM runtime',out.S_carrera,2.1,1e-12);

  % Qiny fijo: cualquier valor debe sobrevivir multiples normalizaciones.
  qvals = [0,3000,16486,30000,140000];
  for i=1:numel(qvals)
      p=struct('aos_config_normalizada',true,'Qiny_Sm3_d',18113, ...
          'Qiny_ref_Sm3_d',18113,'gl',struct('Qiny_Sm3_d',18113), ...
          'jgl',struct('Qiny_Sm3_d',18113));
      p=aos_set_qiny(p,qvals(i),'fijo');
      p=aos_sincronizar_config(p,'GL');
      p=aos_sincronizar_config(p,'JGL');
      fallos=fallos+comprobar_num(sprintf('Qiny fijo %.0f Sm3/d',qvals(i)),p.Q_iny*86400,qvals(i),1e-8);
  end

  % Qiny automatico se define por ausencia de imposicion fija.
  p=struct('aos_config_normalizada',true,'Qiny_Sm3_d',18113,'Qiny_ref_Sm3_d',18113);
  p=aos_set_qiny(p,0,'automatico');
  p=aos_sincronizar_config(p,'GL');
  if isfield(p,'Q_iny') || ~isfield(p,'qiny_modo') || ~strcmpi(p.qiny_modo,'automatico')
      fprintf('[FALLO] Qiny automatico fue recreado por aliases antiguos.\n'); fallos=fallos+1;
  else
      fprintf('[OK] Qiny automatico conserva ausencia de caudal fijo.\n');
  end

  % D_iny y D_bomba deben permanecer independientes.
  p=struct('aos_config_normalizada',true,'D_iny',2000,'D_bomba',1500);
  p=aos_set_profundidad(p,'JGL',2250);
  fallos=fallos+comprobar_num('JGL no pisa D_bomba',p.D_bomba,1500,1e-12);
  p=aos_set_profundidad(p,'BES',1700);
  fallos=fallos+comprobar_num('BES no pisa D_iny',p.D_iny,2250,1e-12);

  % La geometria derivada debe responder a A_n y d_t.
  g=jgl_defaults(struct('A_n',12e-6,'d_t',0.038,'jgl_geometria_modo','derivada'));
  g=jgl_actualizar_geometria(g,'derivada'); a1=g.a_eductor; b1=g.b_eductor;
  g.A_n=24e-6; g.d_t=0.050; g=jgl_actualizar_geometria(g,'derivada');
  if abs(g.a_eductor-a1)<1e-12 && abs(g.b_eductor-b1)<1e-12
      fprintf('[FALLO] La geometria JGL no cambia a_eductor/b_eductor.\n'); fallos=fallos+1;
  else
      fprintf('[OK] La geometria JGL recalcula a_eductor/b_eductor.\n');
  end

  % Menus y archivos anunciados.
  requeridos={'sens_Qiny_JGL','sens_Qiny_GL','sens_Qiny','sens_P_iny','sens_D_bomba', ...
      'sens_A_n','sens_d_t','sens_P_wh','sens_balance_energetico', ...
      'sens_P_wh_BES','sens_frecuencia_BES','sens_sumergencia_BES','sens_RunLife_BES','sens_etapas_BES'};
  for i=1:numel(requeridos)
      if exist(requeridos{i},'file')~=2
          fprintf('[FALLO] Falta modulo anunciado: %s\n',requeridos{i}); fallos=fallos+1;
      end
  end
  if fallos==0 || all(cellfun(@(x) exist(x,'file')==2,requeridos))
      fprintf('[OK] Todos los modulos de sensibilidad anunciados existen.\n');
  end

  % CFD no debe formar parte del runtime.
  cfd1=fullfile(root,'src','core','JGL','jgl_cfd_data.m');
  cfd2=fullfile(root,'src','core','JGL','jgl_cfd_interpolar.m');
  if exist(cfd1,'file')==2 || exist(cfd2,'file')==2
      fprintf('[FALLO] Persisten funciones CFD dentro del runtime JGL.\n'); fallos=fallos+1;
  else
      fprintf('[OK] CFD fuera del runtime JGL.\n');
  end

  % Nombres duplicados que antes dependian del orden del path.
  conocidos={'aos_vlp_info','cargar_intervalos_punzados','aos_presion_bar_a_pa', ...
      'aos_reparar_discontinuidad_local','aos_sla_intake_guard'};
  for i=1:numel(conocidos)
      rutas=which(conocidos{i},'-all');
      if ischar(rutas), n=~isempty(rutas); else, n=numel(rutas); end
      if n>1
          fprintf('[FALLO] Funcion duplicada en path: %s\n',conocidos{i}); fallos=fallos+1;
      end
  end
  fprintf('[OK] Chequeo de duplicados conocidos completado.\n');

  fprintf('\nResultado estructural: %d fallo(s).\n',fallos);
  if fallos>0, error('La estabilizacion transversal no paso la verificacion.'); end
  fprintf('VERIFICACION TRANSVERSAL APROBADA.\n');
end

function preparar(root)
  addpath(fullfile(root,'src'),'-begin');
  iniciar_aos;
end

function n=comprobar_num(nombre,actual,esperado,tol)
  if ~isnumeric(actual) || isempty(actual) || ~isfinite(actual(1)) || abs(actual(1)-esperado)>tol
      fprintf('[FALLO] %s: esperado %.12g, obtenido %.12g\n',nombre,esperado,actual(1)); n=1;
  else
      fprintf('[OK] %s.\n',nombre); n=0;
  end
end
