#define MyAppName "Repuestos POS"
#define MyAppVersion "1"
#define MyAppExeName "repuestos_pos.exe"
#define MyReleaseDir "..\..\build\windows\x64\runner\Release"
#define MyAppId "{{B0D11753-95F1-4292-ADD9-B878C57E0AB9}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVerName={#MyAppName} version {#MyAppVersion}
AppVersion={#MyAppVersion}
AppPublisher=Repuestos POS
AppPublisherURL=https://github.com/hviera01/RepuestosPOS
AppSupportURL=https://github.com/hviera01/RepuestosPOS
AppUpdatesURL=https://github.com/hviera01/RepuestosPOS/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=force
RestartApplications=yes
OutputDir=Output
OutputBaseFilename=RepuestosPOS{#MyAppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion={#MyAppVersion}.0.0.0
VersionInfoProductVersion={#MyAppVersion}.0.0.0
VersionInfoProductName={#MyAppName}
VersionInfoDescription=Instalador de {#MyAppName} versión {#MyAppVersion}

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el Escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "{#MyReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion; Excludes: "data\*"
Source: "{#MyReleaseDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir {#MyAppName}"; Flags: nowait postinstall

[Code]
function VersionYaInstalada(): Integer;
var
  sVersion: String;
  clave: String;
begin
  Result := 0;
  clave := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1';
  if RegQueryStringValue(HKCU, clave, 'DisplayVersion', sVersion) then
    Result := StrToIntDef(sVersion, 0)
  else if RegQueryStringValue(HKLM64, clave, 'DisplayVersion', sVersion) then
    Result := StrToIntDef(sVersion, 0);
end;

function InitializeSetup(): Boolean;
var
  instalada: Integer;
begin
  instalada := VersionYaInstalada();
  Result := instalada < StrToInt('{#MyAppVersion}');
  if not Result then
    MsgBox('Ya está instalada la versión ' + IntToStr(instalada) + ', que es igual o más nueva que este instalador (versión {#MyAppVersion}).' + #13#10 + #13#10 +
      'Descarga de nuevo el instalador más reciente o usa "Buscar actualización" dentro del programa.',
      mbError, MB_OK);
end;
