function r = aos_gas_flow_nozzle(P0,T0,P2,A,Cd,param)
% Flujo compresible isentrópico por tobera/orificio.
% Devuelve m_dot [kg/s], Qstd [m3/s], velocidad y estado de choking.

  if nargin<6||~isstruct(param),param=struct();endif
  P0=max(P0,1.0e4);P2=max(min(P2,P0),1.0e4);T0=max(T0,150);
  A=max(A,1e-12);Cd=min(max(Cd,0.05),1.0);
  gp=aos_gas_props(P0,T0,param);k=gp.k;R=gp.R;Z=gp.Z;
  ratio=P2./P0;crit=(2./(k+1)).^(k./(k-1));
  if ratio<=crit
    phi=sqrt(k./(Z.*R.*T0)).*(2./(k+1)).^((k+1)./(2.*(k-1)));
    choked=true;
  else
    inside=2.*k./(k-1).*(ratio.^(2./k)-ratio.^((k+1)./k));
    phi=sqrt(max(inside,0)./(Z.*R.*T0));
    choked=false;
  endif
  mdot=Cd.*A.*P0.*phi;
  Qstd=mdot./max(gp.rho_std,1e-12);
  gp2=aos_gas_props(P2,T0,param);
  velocidad=mdot./max(gp2.rho.*A,1e-12);
  a=sqrt(k.*R.*T0.*Z);
  r=struct('m_dot',mdot,'Qstd',Qstd,'velocidad',velocidad,'Mach',velocidad./max(a,1), ...
           'choked',choked,'ratio_presion',ratio,'ratio_critico',crit,'props_up',gp,'props_down',gp2);
endfunction
