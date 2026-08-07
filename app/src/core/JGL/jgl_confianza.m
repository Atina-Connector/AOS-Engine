function c = jgl_confianza(p,sol)
% Confianza numerica/fisica del resultado JGL. No depende de CFD.
  p=jgl_defaults(p); score=100; motivos={};
  if ~isfield(sol,'eductor') || ~isstruct(sol.eductor)
    score=20; motivos{end+1}='Sin detalle del eductor';
  else
    if isfield(sol.eductor,'estado') && ~any(strcmp(sol.eductor.estado,{'OK','SIN_GAS_MOTRIZ'}))
      score=score-35; motivos{end+1}=sol.eductor.estado;
    end
    if isfield(sol.eductor,'pot_trans') && isfield(sol.eductor,'pot_disp') && sol.eductor.pot_trans>sol.eductor.pot_disp*(1+1e-8)
      score=0; motivos{end+1}='Potencia transferida superior a disponible';
    end
    if isfield(sol.eductor,'eta') && sol.eductor.eta>0.60
      score=score-25; motivos{end+1}='Eficiencia de transferencia elevada';
    end
  end
  if isfield(sol,'estado') && any(strcmp(sol.estado,{'NO_CONVERGE','SIN_CRUCE','RESULTADO_NO_FISICO'}))
    score=score-40; motivos{end+1}=sol.estado;
  end
  if isfield(sol,'error_directo_iterativo') && isfinite(sol.error_directo_iterativo)
    er=sol.error_directo_iterativo;
    if er>0.10,score=score-40;motivos{end+1}='Error directo-iterativo mayor a 10%';
    elseif er>0.05,score=score-20;motivos{end+1}='Error directo-iterativo entre 5% y 10%';
    elseif er>0.02,score=score-8;motivos{end+1}='Error directo-iterativo entre 2% y 5%';end
  elseif isfield(sol,'modo_utilizado') && ~isempty(strfind(upper(sol.modo_utilizado),'DIRECTO'))
    score=score-15; motivos{end+1}='Resultado rapido sin verificacion iterativa';
  end
  score=max(0,min(100,round(score))); c=struct('puntaje',score,'motivos',{motivos});
  if score>=p.jgl_confianza_umbral_alta,c.nivel='ALTA';elseif score>=p.jgl_confianza_umbral_media,c.nivel='MEDIA';else,c.nivel='BAJA';end
end
