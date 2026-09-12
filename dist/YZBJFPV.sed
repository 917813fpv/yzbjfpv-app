[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=CreateAppMenu
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressedInstall=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles

[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=YZBJFPV Windows V0.0.1.2Beta installed. Shortcut created on desktop.
TargetName=D:\YZSETUP.EXE
FriendlyName=YZBJFPV Windows Installer
AppLaunched=install.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="install.cmd"
FILE1="payload.zip"

[SourceFiles]
SourceFiles0=d:\yzbjfpv-app\dist\pkg\
[SourceFiles0]
%FILE0%=
%FILE1%=
