; Inno Setup script for SLYS. Build with:
;   iscc /DAppVersion=1.7.0 packaging\windows\slys.iss
; The CI passes the version taken from Cargo.toml (single source of truth).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\app\build\windows\x64\runner\Release"
#endif

[Setup]
; Never change this GUID: it identifies the app for upgrades and uninstall.
AppId={{B5C0A1F2-6D43-4C9B-8E5A-3A7F2D9E41C6}
AppName=SLYS
AppVersion={#AppVersion}
AppVerName=SLYS {#AppVersion}
AppPublisher=Gugeldot
AppPublisherURL=https://gugeldot.github.io/slys/
AppSupportURL=https://github.com/gugeldot/slys/issues
AppUpdatesURL=https://github.com/gugeldot/slys/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\SLYS
DefaultGroupName=SLYS
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
OutputDir=..\..\dist
OutputBaseFilename=Slys_Installer
SetupIconFile=..\..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\slys.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Per-user install by default (no admin prompt); the user can choose "all users" in the dialog.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Lets the installer upgrade a running copy instead of failing on locked files.
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\SLYS"; Filename: "{app}\slys.exe"
Name: "{autodesktop}\SLYS"; Filename: "{app}\slys.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\slys.exe"; Description: "{cm:LaunchProgram,SLYS}"; Flags: nowait postinstall skipifsilent

; Uninstalling does NOT remove your saved seeds list (%APPDATA%\slys): it is your data.
