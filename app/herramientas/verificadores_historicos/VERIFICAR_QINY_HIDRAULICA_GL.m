function VERIFICAR_QINY_HIDRAULICA_GL()
% Prueba definitiva: muestra el Qiny que entra realmente a la VLP GL.
% No exige que Ql cambie; verifica el cableado de gas dentro del balance.

  root=fileparts(mfilename('fullpath'));
  addpath(fullfile(root,'src'),'-begin'); iniciar_aos;
  archivo=fullfile(root,'datos','ejemplos','MB01_15pts_2tercios_vertical.aosdat');
  if exist(archivo,'file')~=2
      archivo=fullfile(root,'datos','ejemplos','MB01_calibracion_factor1.aosdat');
  end
  if exist(archivo,'file')~=2
      error('No se encontro un caso MB01 de ejemplo para la prueba.');
  end
  global AOS_CIFRADO_ACTIVO;
  AOS_CIFRADO_ACTIVO=false;
  base=importar_aosdat(archivo);
  [qref,~]=aos_qiny_configurada(base);
  if isempty(qref) || ~isfinite(qref), qref=16486/86400; end
  q_sm3d=unique([0,8000,round(qref*86400),30000]);
  n=numel(q_sm3d); resultados=cell(1,n); ql=NaN(1,n); fallos=0;

  fprintf('\n=== TRAZA QINY DENTRO DE LA VLP GL ===\n');
  fprintf('Q req | Q VLP | Q form | Q total | Ql | Ps | P_req | Residuo | Estado\n');
  fprintf('(Sm3/d) | (Sm3/d) | (Sm3/d) | (Sm3/d) | (m3/d) | (bar) | (bar) | (bar) |\n');
  for i=1:n
      p=aos_set_qiny(base,q_sm3d(i),'fijo');
      p=aos_sincronizar_config(p,'GL');
      [Ql,~,~,~,~,~,sol]=GL_puro_core(p);
      resultados{i}=sol; ql(i)=Ql*86400;
      a=sol.audit;
      qvlp=leer(a,'Qiny_efectivo',NaN); qform=leer(a,'Qg_formacion_std',NaN);
      qtot=leer(a,'Qg_total_std',NaN); ps=leer(a,'P_s',NaN); preq=leer(a,'P_req',NaN);
      res=leer(a,'residuo',NaN);
      fprintf('%7.0f | %7.0f | %8.0f | %9.0f | %7.2f | %6.2f | %6.2f | %7.3f | %s\n', ...
          q_sm3d(i),qvlp*86400,qform*86400,qtot*86400,ql(i),ps/1e5,preq/1e5,res/1e5,sol.estado);
      if ~isfinite(qvlp) || abs(qvlp*86400-q_sm3d(i))>1e-6
          fprintf('[FALLO] El punto %.0f Sm3/d no llego igual a la VLP.\n',q_sm3d(i)); fallos=fallos+1;
      end
      if isfinite(qform) && isfinite(qtot) && abs(qtot-(qform+qvlp))>1e-10
          fprintf('[FALLO] Balance de gas inconsistente en punto %.0f Sm3/d.\n',q_sm3d(i)); fallos=fallos+1;
      end
  end
  assignin('base','VERIFICACION_QINY_GL_RESULTADOS',resultados);
  if max(ql)-min(ql) < max(0.5,0.005*max(abs(ql)))
      fprintf('\nAVISO: Qiny llega correctamente a la VLP, pero Ql es casi plano.\n');
      fprintf('Eso identifica insensibilidad del modelo/VLP en este caso, no una sobrescritura de Qiny.\n');
  end
  if fallos>0, error('Fallo la traza de Qiny dentro de la VLP GL.'); end
  fprintf('\nTRAZA QINY GL APROBADA: todos los valores solicitados llegaron al balance nodal.\n');
end

function v=leer(s,c,d)
  v=d; if isstruct(s)&&isfield(s,c)&&isnumeric(s.(c))&&isscalar(s.(c))&&isfinite(s.(c)),v=s.(c);end
end
