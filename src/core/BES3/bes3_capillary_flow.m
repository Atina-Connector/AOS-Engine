function r = bes3_capillary_flow(dp_fun,cap,rho,mu,param)
% Resuelve el caudal del capilar con presion disponible dependiente de Q.
  p=bes3_defaults(param);qlo=0;qhi=max(p.bes3_capilar_Q_max_m3_d/86400,1e-8);
  flo=res_local(qlo,dp_fun,cap,rho,mu,p);fhi=res_local(qhi,dp_fun,cap,rho,mu,p);
  if flo>=0
    q=0;
  elseif fhi<0
    q=qhi;
  else
    for k=1:70
      q=0.5*(qlo+qhi);fm=res_local(q,dp_fun,cap,rho,mu,p);
      if abs(fm)<100 || (qhi-qlo)*86400<1e-5,break;endif
      if fm>0,qhi=q;else,qlo=q;endif
    endfor
  endif
  loss=bes3_capillary_loss(q,rho,mu,cap,p);dp=max(dp_fun(q),0);
  r=loss;r.dP_disponible_Pa=dp;r.residuo_Pa=loss.dP_total_Pa-dp;
  r.estado='RESUELTO';if dp<=0,r.estado='SIN_PRESION_DISPONIBLE';elseif fhi<0,r.estado='LIMITADO_POR_Q_MAX_CAPILAR';endif
endfunction
function f=res_local(q,fun,cap,rho,mu,p)
  l=bes3_capillary_loss(q,rho,mu,cap,p);f=l.dP_total_Pa-max(fun(q),0);
endfunction
