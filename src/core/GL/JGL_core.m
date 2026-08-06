function [Ql,Qo,Qgas_total,Qiny,Qiny_MMscfd,diagnostico,sol] = JGL_core(param)
% AOS 0.0.12 - fachada compatible del nuevo motor JGL.
  param=jgl_defaults(param);
  if isfield(param,'Q_iny')&&~isempty(param.Q_iny),Qiny=max(param.Q_iny,0);else,Qiny=jgl_calcular_qiny_automatico(param);end
  sol=jgl_ejecutar(param,Qiny,param.jgl_modo);
  Ql=sol.Ql; Qo=sol.Qo; Qgas_total=sol.Qgas_total; Qiny=sol.Qiny; Qiny_MMscfd=sol.Qiny_MMscfd;
  diagnostico=sprintf('Modo: %s | Estado: %s | Confianza: %s (%d/100) | DeltaP: %.3f bar | Iteraciones: %d', ...
    sol.modo_utilizado,sol.estado,sol.confianza.nivel,sol.confianza.puntaje,sol.deltaP/1e5,sol.iteraciones);
  if isfield(sol,'error_directo_iterativo')&&isfinite(sol.error_directo_iterativo)
    diagnostico=sprintf('%s | Error directo-iterativo: %.2f %%',diagnostico,100*sol.error_directo_iterativo);
  end
end
