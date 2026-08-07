function aos_visualizar_roadmap()
  raiz=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  ruta=fullfile(raiz,'src','docs','assets','AOS_ROADMAP_INTEGRAL_0_1_3_R2.png');
  if exist(ruta,'file')~=2
    fprintf('Imagen de roadmap no encontrada: %s\n',ruta); return;
  endif
  try
    img=imread(ruta);
    figure('Name','AOS Roadmap Integral','NumberTitle','off');
    image(img); axis image off;
    title('AOS Roadmap Integral');
  catch err
    fprintf('No fue posible abrir la imagen: %s\n',err.message);
    fprintf('Ruta: %s\n',ruta);
  end_try_catch
endfunction
