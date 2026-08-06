function [tablas, composicion] = aos_report_apply_profile(tablas, perfil, overrides)
% AOS_REPORT_APPLY_PROFILE Asigna modos de presentacion a todas las tablas.
  if nargin<2||isempty(perfil),perfil='TECHNICAL';endif
  if nargin<3||~isstruct(overrides),overrides=struct();endif
  perfil=upper(strtrim(char(perfil)));
  validos={'EXECUTIVE','TECHNICAL','AUDIT','CUSTOM'};
  if ~any(strcmp(perfil,validos)),perfil='TECHNICAL';endif
  entrada=tablas(:)'; tablas=struct([]);
  for i=1:numel(entrada)
    t=aos_report_table_normalize(entrada(i),i);
    if isempty(tablas),tablas=t;else,tablas(end+1)=t;endif
    modo=tablas(end).render_mode;
    if isempty(modo), modo=modo_perfil_local(tablas(end),perfil); endif
    oid=tablas(end).id; oid_field=regexprep(oid,'[^A-Za-z0-9_]','_');
    if ~isempty(oid_field) && isletter(oid_field(1)) && isfield(overrides,oid_field)
      x=overrides.(oid_field);
      if ischar(x),modo=upper(strtrim(x));
      elseif isstruct(x)
        if isfield(x,'render_mode')&&ischar(x.render_mode),modo=upper(strtrim(x.render_mode));endif
        if isfield(x,'sample_step')&&isnumeric(x.sample_step)&&isscalar(x.sample_step),tablas(end).sample_step=max(1,round(x.sample_step));endif
      endif
    endif
    if ~modo_valido_local(modo),modo='FULL_BODY';endif
    tablas(end).render_mode=modo;
  endfor
  composicion=aos_report_composition_stats(tablas,perfil);
endfunction

function modo=modo_perfil_local(t,perfil)
  n=t.n_rows; cat=upper(t.category); pri=upper(t.priority);
  es_sens=strcmp(cat,'SENSITIVITY')||~isempty(strfind(upper(t.role),'SENS'));
  if es_sens
    modo='FULL_BODY'; return;
  endif
  if any(strcmp(perfil,{'TECHNICAL','CUSTOM'})) && ~isempty(t.default_mode)
    modo=t.default_mode; return;
  endif
  switch perfil
    case 'EXECUTIVE'
      if strcmp(pri,'PRIMARY')
        if n<=60,modo='FULL_BODY';else,modo='SUMMARY';endif
      elseif n<=12
        modo='FULL_BODY';
      elseif n<=100
        modo='SUMMARY';
      else
        modo='VIEWER_ONLY';
      endif
    case 'AUDIT'
      if n<=45,modo='FULL_BODY';else,modo='FULL_APPENDIX';endif
    otherwise % TECHNICAL / CUSTOM base
      if strcmp(pri,'PRIMARY')
        if n<=120,modo='FULL_BODY';else,modo='FULL_APPENDIX';endif
      elseif n<=30
        modo='FULL_BODY';
      elseif n<=120
        modo='FULL_APPENDIX';
      else
        modo='VIEWER_ONLY';
      endif
  endswitch
endfunction

function tf=modo_valido_local(m)
  tf=any(strcmp(upper(m),{'FULL_BODY','SUMMARY','SAMPLED','FULL_APPENDIX','VIEWER_ONLY','EXCLUDED_EXPORT'}));
endfunction
