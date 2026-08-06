function r = mandriles_capacidad_orificio(param,Pup_g_bar,Pdown_g_bar,T_K,Qobj_m3d)
% Selección de puerto genérico por capacidad Thornhill-Craver.
  p=mandriles_defaults(param); ports=p.mand_puertos_mm(:)';
  cap=zeros(size(ports)); crit=false(size(ports));
  gamma=p.mand_kappa; R=287.05/max(p.mand_gamma_g,0.1);
  for i=1:numel(ports)
    mdot=thornhill_craver(Pup_g_bar*1e5,Pdown_g_bar*1e5,T_K,ports(i)/1000,R,gamma,p.mand_Cd);
    rho_std=101325/(R*288.15);
    cap(i)=mdot/max(rho_std,1e-9)*86400;
    crit(i)=(Pdown_g_bar/max(Pup_g_bar,1e-9)) <= (2/(gamma+1))^(gamma/(gamma-1));
  end
  ix=find(cap>=Qobj_m3d,1,'first');
  if isempty(ix), ix=numel(ports); estado='CAPACIDAD_INSUFICIENTE'; else, estado='OK'; end
  r=struct('puerto_mm',ports(ix),'capacidad_m3d',cap(ix), ...
      'utilizacion',Qobj_m3d/max(cap(ix),1e-9),'critico',crit(ix),'estado',estado, ...
      'puertos_mm',ports,'capacidades_m3d',cap);
end
