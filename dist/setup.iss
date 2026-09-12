[Setup]
AppName=YZBJFPV
AppVersion=0.0.1.2
AppPublisher=YZBJFPV
DefaultDirName={localappdata}\Programs\YZBJFPV
DefaultGroupName=YZBJFPV
Uninstallable=yes
OutputDir=d:\yzbjfpv-app\dist
OutputBaseFilename=YZBJFPV-Setup-V0.0.1.2Beta
Compression=lzma2/max
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
SetupIconFile=d:\yzbjfpv-app\assets\icon\icon.ico
DisableProgramGroupPage=yes

[Files]
Source: "d:\yzbjfpv-app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{userdesktop}\YZBJFPV"; Filename: "{app}\yzbjfpv.exe"
Name: "{group}\YZBJFPV"; Filename: "{app}\yzbjfpv.exe"
Name: "{group}\Uninstall YZBJFPV"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\yzbjfpv.exe"; Description: "Launch YZBJFPV"; Flags: nowait postinstall skipifsilent
