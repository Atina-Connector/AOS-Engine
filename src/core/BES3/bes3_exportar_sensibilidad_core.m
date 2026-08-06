function archivo=bes3_exportar_sensibilidad_core(contexto,archivo,enriquecido)
% DEV5.4: BES3 usa el exportador transversal con tablas nativas y diagnostico.
  if nargin<3,enriquecido=false;endif
  if ~isfield(contexto,'diagnostico')||~isstruct(contexto.diagnostico)
    contexto.diagnostico=aos_sensibilidad_diagnosticar(contexto.sensibilidad,'BES3',contexto.param);
  endif
  archivo=aos_exportar_sensibilidad_core(contexto,archivo,enriquecido);
endfunction
