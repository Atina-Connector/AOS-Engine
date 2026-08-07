function R=jgl_sensibilidad_hibrida(p,Qvals)
% Directo en toda la malla; iterativo en extremos, optimo, baja confianza y cambios bruscos.
  n=length(Qvals); D=cell(1,n); qd=NaN(1,n);
  for i=1:n,D{i}=jgl_solver_directo(p,Qvals(i));qd(i)=D{i}.Ql;end
  sel=false(1,n); if n>0,sel([1 n])=true;end
  [~,io]=max(qd*(1-p.WC)); if ~isempty(io),sel(io)=true;end
  for i=1:n
    if ~strcmp(D{i}.confianza.nivel,'ALTA'),sel(i)=true;end
    if i>1&&i<n
      curv=abs(qd(i+1)-2*qd(i)+qd(i-1))/max(abs(qd(i)),1e-12); if curv>0.10,sel(i)=true;end
    end
  end
  S=D; for i=find(sel), it=jgl_solver_iterativo(p,Qvals(i)); it.verificado_iterativo=true; it.error_directo_iterativo=abs(D{i}.Ql-it.Ql)/max(abs(it.Ql),1e-12); it.resultado_directo=D{i};it.confianza=jgl_confianza(p,it);S{i}=it;end
  R=struct('Qiny',Qvals,'soluciones',{S},'seleccion_iterativa',sel,'Ql',cellfun(@(x)x.Ql,S),'Qo',cellfun(@(x)x.Qo,S));
end
