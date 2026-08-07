function [q_m3s, modo, fuente, detalle] = aos_resolver_qiny_configurado(p)
% AOS_RESOLVER_QINY_CONFIGURADO Normaliza aliases historicos de Qiny.
% Devuelve Qiny en m3/s estandar, modo ('fijo'/'automatico'), fuente y detalle.
% Prioridad: corrida efectiva importada > configuracion explicita > aliases SI.
  q_m3s = [];
  modo = '';
  fuente = '';
  detalle = struct('q_sm3d',NaN,'q_m3s',NaN,'modo','','fuente','','candidatos',{{}});
  if nargin < 1 || ~isstruct(p), return; end

  % 1) Valores efectivos o de corrida en Sm3/d.
  grupos = {
    {'Qiny_efectivo_Sm3_d','Qiny_efectivo_VLP_Sm3_d','Qiny_usado_Sm3_d','Qiny_corrida_Sm3_d','caudal_gas_inyectado_Sm3_d'}, 'EFECTIVO';
    {'Qiny_sim_Sm3_d','Qiny_Sm3_d','Q_iny_Sm3_d','Qiny_sm3d','Q_iny_sm3d','gl_Qiny_Sm3_d','jgl_Qiny_Sm3_d'}, 'CONFIG';
    {'Qiny_ref_Sm3_d','Qiny_config_Sm3_d','Qiny_aosdat_Sm3_d'}, 'REFERENCIA'
  };
  ramas = {'','gl','jgl','config','config_importada','aosdat','ultima_corrida','corrida','resultado','resultados','audit'};
  for g=1:size(grupos,1)
    campos=grupos{g,1}; etiqueta=grupos{g,2};
    for r=1:numel(ramas)
      [s,pref]=rama_local(p,ramas{r});
      if isempty(s), continue; end
      [q,src]=buscar_sm3d_local(s,campos,pref);
      if ~isempty(q)
        q_m3s=q; fuente=[etiqueta ':' src];
        modo=resolver_modo_local(p,s);
        detalle=armar_detalle_local(q_m3s,modo,fuente);
        return;
      end
    end
  end

  % 2) Valores en MMscf/d.
  campos_mmscfd = {'Qiny_efectivo_MMscfd','Qiny_usado_MMscfd','Qiny_sim_MMscfd', ...
                   'Qiny_MMscfd','Q_iny_MMscfd','Qiny_ref_MMscfd','Qiny_config_MMscfd'};
  for r=1:numel(ramas)
    [s,pref]=rama_local(p,ramas{r});
    if isempty(s), continue; end
    [q,src]=buscar_mmscfd_local(s,campos_mmscfd,pref);
    if ~isempty(q)
      q_m3s=q; fuente=['MMscfd:' src]; modo=resolver_modo_local(p,s);
      detalle=armar_detalle_local(q_m3s,modo,fuente); return;
    end
  end

  % 3) Valores SI activos.
  campos_si = {'Q_iny','Qiny','Qiny_efectivo','Qiny_usado','gl_Qiny','jgl_Qiny','caudal_gas_inyectado'};
  for r=1:numel(ramas)
    [s,pref]=rama_local(p,ramas{r});
    if isempty(s), continue; end
    [q,src]=buscar_si_local(s,campos_si,pref);
    if ~isempty(q)
      q_m3s=q; fuente=['SI:' src]; modo=resolver_modo_local(p,s);
      detalle=armar_detalle_local(q_m3s,modo,fuente); return;
    end
  end

  % Si no hay valor pero el modo es automatico, conservar esa politica.
  modo=resolver_modo_local(p,p);
  detalle.modo=modo;
endfunction

function [s,pref]=rama_local(p,nombre)
  if isempty(nombre), s=p; pref=''; return; end
  if isfield(p,nombre) && isstruct(p.(nombre)), s=p.(nombre); pref=[nombre '.']; else, s=[]; pref=''; end
endfunction

function [q,fuente]=buscar_sm3d_local(s,campos,pref)
  q=[]; fuente='';
  for i=1:numel(campos)
    c=campos{i};
    if isfield(s,c) && valido_local(s.(c)) && s.(c)>=0
      q=s.(c)/86400; fuente=[pref c]; return;
    end
  end
endfunction

function [q,fuente]=buscar_mmscfd_local(s,campos,pref)
  q=[]; fuente='';
  for i=1:numel(campos)
    c=campos{i};
    if isfield(s,c) && valido_local(s.(c)) && s.(c)>=0
      q=s.(c)*1e6*0.028316846592/86400; fuente=[pref c]; return;
    end
  end
endfunction

function [q,fuente]=buscar_si_local(s,campos,pref)
  q=[]; fuente='';
  for i=1:numel(campos)
    c=campos{i};
    if isfield(s,c) && valido_local(s.(c)) && s.(c)>=0
      q=s.(c); fuente=[pref c]; return;
    end
  end
endfunction

function modo=resolver_modo_local(p,s)
  modo='fijo';
  campos={'qiny_modo','modo_Qiny','Qiny_modo','modo_qiny'};
  for bloque={s,p}
    b=bloque{1};
    if ~isstruct(b), continue; end
    for i=1:numel(campos)
      c=campos{i};
      if isfield(b,c) && ischar(b.(c))
        m=lower(strtrim(b.(c)));
        if ~isempty(strfind(m,'auto')), modo='automatico'; return; end
        if ~isempty(strfind(m,'fij')) || ~isempty(strfind(m,'manual')) || ~isempty(strfind(m,'forz')), modo='fijo'; return; end
      end
    end
  end
endfunction

function d=armar_detalle_local(q,modo,fuente)
  d=struct('q_sm3d',q*86400,'q_m3s',q,'modo',modo,'fuente',fuente,'candidatos',{{fuente}});
endfunction

function ok=valido_local(x)
  ok=isnumeric(x) && isscalar(x) && isfinite(x);
endfunction
