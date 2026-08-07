function catalogo = gibbs3_rod_catalog()
% GIBBS3_ROD_CATALOG Carga materiales BM desde el catalogo AOS.
% Los valores del archivo son de pre-diseno y deben validarse contra el
% fabricante antes de una decision operativa.

  catalogo = [];
  if exist('cargar_materiales_varillas', 'file') == 2
    try
      mats = cargar_materiales_varillas();
      for k = 1:numel(mats)
        item = struct();
        item.nombre = mats(k).nombre;
        item.rho_kg_m3 = mats(k).densidad_kg_m3;
        item.E_Pa = mats(k).modulo_young_GPa * 1e9;
        item.Se_MPa = mats(k).limite_fatiga_MPa;
        item.Sut_MPa = mats(k).resistencia_ultima_MPa;
        item.Sy_MPa = 0.70 * item.Sut_MPa;
        item.origen = 'config/BM/materiales_varillas.txt';
        item.certificado = 0;
        catalogo = agregar(catalogo, item);
      end
    catch
      catalogo = [];
    end
  end

  if isempty(catalogo)
    catalogo = fallback_catalogo();
  end
end

function c = fallback_catalogo()
  c = [];
  c = agregar(c, crear('Acero Grado C', 7850, 210e9, 200, 620));
  c = agregar(c, crear('Acero Grado D', 7850, 210e9, 280, 793));
  c = agregar(c, crear('Acero Grado K', 7850, 210e9, 350, 860));
  c = agregar(c, crear('Fibra de Vidrio', 2100, 48e9, 100, 690));
end

function x = crear(nombre, rho, E, Se, Sut)
  x = struct();
  x.nombre = nombre;
  x.rho_kg_m3 = rho;
  x.E_Pa = E;
  x.Se_MPa = Se;
  x.Sut_MPa = Sut;
  x.Sy_MPa = 0.70 * Sut;
  x.origen = 'fallback_AOS_referencial';
  x.certificado = 0;
end

function a = agregar(a, x)
  if isempty(a)
    a = x;
  else
    a(end+1) = x;
  end
end
