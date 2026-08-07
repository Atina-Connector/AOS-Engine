; AOS.iss - instalador Windows de AOS Suite (Inno Setup 6).
;
; No compila nada por si solo: espera que ya existan (armados por
; packaging/windows/scripts/prepare-octave-runtime.ps1, stage-app.ps1 y
; launcher/build.ps1):
;   build\windows\AOS.exe
;   build\windows\runtime\...      (runtime portable de Octave)
;   build\windows\app\...          (app/ filtrada, ver stage-app.ps1)
;
; Version real inyectada desde CI con /DAOSVersion=<version> (ver
; .github/workflows/windows-build.yml). El default de abajo es solo para
; poder abrir/editar este .iss manualmente en el IDE de Inno Setup.
#ifndef AOSVersion
  #define AOSVersion "0.0.0-local"
#endif

#define AOSPublisher "AESIR Oilfield Systems"
#define AOSAppName "AOS Suite"
; GUID fijo: identifica la aplicacion entre versiones para que Inno Setup
; reconozca upgrades en lugar de instalaciones paralelas. No regenerar.
#define AOSAppId "{{5B6C6E9B-6A9D-4B60-9F3C-6B2B9E3A6E10}"

[Setup]
AppId={#AOSAppId}
AppName={#AOSAppName}
AppVersion={#AOSVersion}
AppPublisher={#AOSPublisher}
DefaultDirName={autopf}\AOS
DefaultGroupName=AOS
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\AOS.exe
OutputDir=..\..\..\dist
OutputBaseFilename=AOS-Setup-{#AOSVersion}
Compression=lzma2/normal
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
WizardStyle=modern
; La carga util incluye el runtime completo de Octave (cientos de MB);
; sin esto Inno Setup limita el tamano combinado de un mismo volumen interno.
DiskSpanning=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\..\build\windows\AOS.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\..\build\windows\runtime\*"; DestDir: "{app}\runtime"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\..\build\windows\app\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\AOS"; Filename: "{app}\AOS.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall AOS"; Filename: "{uninstallexe}"
Name: "{autodesktop}\AOS"; Filename: "{app}\AOS.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Code]
{ Nota: se evitan a proposito los arrays "const ... = (...)" de Pascal
  Script -- el soporte de Inno Setup para constantes tipadas con
  inicializador estructurado es historicamente poco confiable. Con solo
  dos carpetas semilla ('datos_usuario', 'intercambio') y dos vacias
  ('salida', 'logs'), es mas seguro llamar cada una explicitamente. }

function GetUserAOSRoot(): string;
begin
  Result := ExpandConstant('{userdocs}\AOS');
end;

function CreateJunction(const LinkPath, TargetPath: string): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec(ExpandConstant('{cmd}'),
    Format('/c mklink /J "%s" "%s"', [LinkPath, TargetPath]),
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

{ Deja LinkPath (dentro de la instalacion) como junction hacia TargetPath
  (dentro de Documents\AOS). Primera instalacion: mueve el contenido
  semilla que [Files] acaba de copiar. Reinstalacion/upgrade: conserva el
  dato real del usuario en Documents\AOS y descarta cualquier carpeta
  semilla nueva que haya quedado en LinkPath. }
procedure MigrateToUserDataAndLink(const RelName: string);
var
  LinkPath, TargetPath: string;
begin
  LinkPath := ExpandConstant('{app}\app\') + RelName;
  TargetPath := GetUserAOSRoot() + '\' + RelName;

  ForceDirectories(GetUserAOSRoot());

  if not DirExists(TargetPath) then
  begin
    if DirExists(LinkPath) then
      RenameFile(LinkPath, TargetPath)
    else
      ForceDirectories(TargetPath);
  end
  else if DirExists(LinkPath) then
  begin
    { TargetPath ya es la carpeta real del usuario de una instalacion
      anterior; lo que haya en LinkPath es semilla nueva sin usar. }
    DelTree(LinkPath, True, True, True);
  end;

  if not DirExists(LinkPath) then
    CreateJunction(LinkPath, TargetPath);
end;

procedure EnsureEmptyUserFolder(const RelName: string);
begin
  ForceDirectories(GetUserAOSRoot() + '\' + RelName);
end;

{ Octave avisa "time stamp for '...' is in the future" para cualquier .m
  cuyo mtime quede por delante del reloj de la maquina que lo lee. Los
  archivos instalados conservan el mtime del checkout de CI (build en
  GitHub Actions); si el reloj de la maquina de destino esta atrasado
  (comun en VMs recien creadas o sin sincronizar), Octave los ve como
  "del futuro" en cada arranque. Se resetea el mtime de todo app\ al
  momento de la instalacion -- usando el reloj LOCAL de esa misma
  maquina, asi nunca puede quedar en el futuro respecto de si misma. }
procedure NormalizeInstalledTimestamps();
var
  ResultCode: Integer;
  Cmd: string;
begin
  Cmd := '-NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath ''' +
    ExpandConstant('{app}\app') +
    ''' -Recurse -File | ForEach-Object { $_.LastWriteTime = Get-Date }"';
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Cmd, '',
    SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    { Antes de crear las junctions: Get-ChildItem -Recurse las atraviesa,
      asi que si esto corriera despues tocaria el LastWriteTime de los
      archivos reales del usuario en Documents\AOS en cada upgrade. Antes
      de migrar, datos_usuario/intercambio todavia son la semilla recien
      copiada por [Files], nunca el dato real del usuario. }
    NormalizeInstalledTimestamps();
    MigrateToUserDataAndLink('datos_usuario');
    MigrateToUserDataAndLink('intercambio');
    EnsureEmptyUserFolder('salida');
    EnsureEmptyUserFolder('logs');
  end;
end;

{ rmdir sin /s sobre una junction borra solo el punto de union, nunca el
  contenido real al que apunta -- es la forma segura de "desvincular". Se
  hace ANTES de que Inno empiece a borrar los archivos que recuerda haber
  instalado bajo app\<carpeta>\...: si no se saca la junction primero,
  Inno borraria a traves de ella y destruiria los datos reales del
  usuario en Documents\AOS. }
procedure RemoveJunctionSafely(const LinkPath: string);
var
  ResultCode: Integer;
begin
  if DirExists(LinkPath) then
    Exec(ExpandConstant('{cmd}'), Format('/c rmdir "%s"', [LinkPath]),
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    RemoveJunctionSafely(ExpandConstant('{app}\app\datos_usuario'));
    RemoveJunctionSafely(ExpandConstant('{app}\app\intercambio'));
  end;
end;
