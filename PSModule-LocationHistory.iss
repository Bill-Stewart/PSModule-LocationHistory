#if Ver < EncodeVer(6,3,1,0)
#error This script requires Inno Setup 6.3.1 or later
#endif

#define ModuleName "LocationHistory"
#define AppName "PowerShell Module - " + ModuleName
#define AppPublisher "Bill Stewart"
#define AppMajorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Version", "Major", "0")
#define AppMinorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Version", "Minor", "0")
#define AppPatchVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Version", "Patch", "0")
#define AppVersion AppMajorVersion + "." + AppMinorVersion + "." + AppPatchVersion
#define InstallPath "WindowsPowerShell\Modules\" + ModuleName
#define SetupCompany "Bill Stewart"
#define SetupVersion AppVersion + ".0"

[Setup]
AppId={{26450D0F-B5BD-40DC-AB08-FA83DDE89EC1}
AppName={#AppName}
AppVerName={#AppName} [{#AppVersion}]
AppPublisher={#AppPublisher}
AppVersion={#AppVersion}
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2/max
DefaultDirName={code:GetInstallDir}
DisableDirPage=yes
MinVersion=6.3
OutputBaseFilename=PSModule-{#ModuleName}-{#AppVersion}-setup
OutputDir=.
PrivilegesRequired=admin
SolidCompression=yes
UninstallFilesDir={code:GetInstallDir}\Uninstall
UninstallDisplayName={#AppName}
UninstallDisplayIcon={code:GetInstallDir}\Uninstall\{#ModuleName}.ico
VersionInfoCompany={#SetupCompany}
VersionInfoProductVersion={#AppVersion}
VersionInfoVersion={#SetupVersion}
WizardResizable=no
WizardStyle=modern

[Languages]
Name: english; InfoBeforeFile: "Readme.rtf"; LicenseFile: "License.rtf"; MessagesFile: "compiler:Default.isl"

[Files]
; 32-bit
Source: "License.txt";                 DestDir: "{commonpf32}\{#InstallPath}"
Source: "{#ModuleName}.psd1";          DestDir: "{commonpf32}\{#InstallPath}"
Source: "{#ModuleName}.psm1";          DestDir: "{commonpf32}\{#InstallPath}"
Source: "{#ModuleName}.format.ps1xml"; DestDir: "{commonpf32}\{#InstallPath}"
Source: "{#ModuleName}.ico";           DestDir: "{commonpf32}\{#InstallPath}\Uninstall"; Check: not Is64BitInstallMode()
; 64-bit
Source: "License.txt";                 DestDir: "{commonpf64}\{#InstallPath}"; Check: Is64BitInstallMode()
Source: "{#ModuleName}.psd1";          DestDir: "{commonpf64}\{#InstallPath}"; Check: Is64BitInstallMode()
Source: "{#ModuleName}.psm1";          DestDir: "{commonpf64}\{#InstallPath}"; Check: Is64BitInstallMode()
Source: "{#ModuleName}.format.ps1xml"; DestDir: "{commonpf64}\{#InstallPath}"; Check: Is64BitInstallMode()
Source: "{#ModuleName}.ico";           DestDir: "{commonpf64}\{#InstallPath}\Uninstall"; Check: Is64BitInstallMode()

[Code]
function GetInstallDir(Param: string): string;
begin
  if Is64BitInstallMode() then
    result := ExpandConstant('{commonpf64}\{#InstallPath}')
  else
    result := ExpandConstant('{commonpf32}\{#InstallPath}');
end;
