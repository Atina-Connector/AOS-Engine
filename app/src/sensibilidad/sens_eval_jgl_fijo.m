function [Ql,Qo,Qgas_total,Qiny_usado,sol] = sens_eval_jgl_fijo(base,Qiny,modo)
% Evaluacion JGL 0.0.12 con seleccion explicita de solver.
  p=sens_preparar_base(base,'SENS_JGL'); p=aos_set_qiny(p,max(Qiny,0)*86400,'fijo'); if nargin<3||isempty(modo),modo='directo';end
  sol=jgl_ejecutar(p,p.Q_iny,modo); Ql=sol.Ql;Qo=sol.Qo;Qgas_total=sol.Qgas_total;Qiny_usado=sol.Qiny;
end
