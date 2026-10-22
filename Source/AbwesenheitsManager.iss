; ============================================================
; AbwesenheitsManager – Installationspaket
;
; Vorbereitung:
;   .\Scripts\Publish.ps1
;
; Anschließend mit Inno Setup 6 kompilieren.
; Alternativ erledigt .\Scripts\Build-Setup.ps1 beide Schritte.
; ============================================================

[Setup]

; ------------------------------------------------------------
; Programmidentität
; ------------------------------------------------------------

; Diese ID bei Updates beibehalten!
; Sie identifiziert die Anwendung für Installation/Deinstallation.
AppId={{463A2FCB-39DC-46AC-A671-18D04B3A14CF}

AppName=AbwesenheitsManager

; Bei einer neuen Veröffentlichung entsprechend erhöhen.
AppVersion=1.5.0

; ------------------------------------------------------------
; Herausgeber und Kontakt
; ------------------------------------------------------------

; Wird in den Windows-Programminformationen angezeigt.
AppPublisher=TüftelTyp

; Optionale Links: eigene Adressen einsetzen und ";" entfernen.
AppPublisherURL=https://github.com/TueftelTyp/AbwesenheitsManager
; AppSupportURL=https://www.deine-domain.de/support
AppUpdatesURL=https://github.com/TueftelTyp/AbwesenheitsManager/releases

; ------------------------------------------------------------
; Dateieigenschaften der erzeugten Setup-EXE
; ------------------------------------------------------------

VersionInfoCompany=TüftelTyp
VersionInfoDescription=Installation von AbwesenheitsManager
VersionInfoCopyright=Copyright (C) 2026 TüftelTyp

; Numerische Dateiversion mit vier Bestandteilen.
; Bei Versionsänderungen zusammen mit AppVersion aktualisieren.
VersionInfoVersion=1.5.0.0

; ------------------------------------------------------------
; Lizenz und optionale Hinweise
; ------------------------------------------------------------

; Zum Aktivieren eine Datei "Lizenz.txt" neben dieser ISS-Datei
; ablegen und das führende ";" entfernen.
; Unterstützt werden TXT (UTF-8) und RTF.
; Der Benutzer muss der angezeigten Lizenz zustimmen.
LicenseFile=LICENSE.txt

; Optionale zusätzliche Informationsseiten.
; Die jeweiligen Dateien müssen ebenfalls vorhanden sein.
; InfoBeforeFile=Hinweise-vor-Installation.txt
; InfoAfterFile=Hinweise-nach-Installation.txt

; ------------------------------------------------------------
; Installationsort und Berechtigungen
; ------------------------------------------------------------

; Fester Pfad: Dienstverwaltung und Wartungsskript verwenden
; ebenfalls diesen Installationsort.
; Nicht unabhängig von diesen Komponenten ändern!
DefaultDirName={autopf}\AbwesenheitsManager
DisableDirPage=yes
UsePreviousAppDir=no

; Administratorrechte für Dienstinstallation und Bereinigung.
PrivilegesRequired=admin

; Die veröffentlichten Programme sind für Windows x64 bestimmt.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; ------------------------------------------------------------
; Startmenü und Symbole
; ------------------------------------------------------------

DefaultGroupName=AbwesenheitsManager

; Symbol im Windows-Deinstallationseintrag.
UninstallDisplayIcon={app}\Admin\AbwesenheitsManager.Admin.exe

; Symbol der Setup-EXE.
SetupIconFile=..\Assets\icon.ico

; ------------------------------------------------------------
; Ausgabe und Komprimierung
; ------------------------------------------------------------

; Ausgabeordner relativ zur ISS-Datei.
OutputDir=..\setup-output

; Dateiname ohne ".exe".
; Optional eine Versionsnummer anhängen:
; OutputBaseFilename=AbwesenheitsManager-Setup-1.5.0
OutputBaseFilename=AbwesenheitsManager-Setup

Compression=lzma2
SolidCompression=yes

; ------------------------------------------------------------
; Verhalten bei laufenden Anwendungen
; ------------------------------------------------------------

CloseApplications=yes

; Anwendungen nach dem Setup nicht automatisch neu starten.
RestartApplications=no


[Languages]

; Deutscher Installationsassistent.
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

; Optional Englisch als weitere Sprache anbieten:
; Name: "english"; MessagesFile: "compiler:Default.isl"


[Files]

; Alle Programmdateien einschließlich Unterordner übernehmen.
; Vor dem Kompilieren müssen die Publish-Ausgaben vorhanden sein.
Source: "..\publish\Admin\*"; DestDir: "{app}\Admin"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\publish\Service\*"; DestDir: "{app}\Service"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\publish\Tray\*"; DestDir: "{app}\Tray"; Flags: ignoreversion recursesubdirs createallsubdirs

; Wartungsskript für die spätere Deinstallation installieren.
Source: "Maintenance.ps1"; DestDir: "{app}\Setup"; Flags: ignoreversion

; Zusätzlich im Setup einbetten, damit es bereits vor der
; Installation für die Update-Vorbereitung verfügbar ist.
Source: "Maintenance.ps1"; Flags: dontcopy

; Optional die Lizenz zusätzlich im Programmordner ablegen.
; Nur aktivieren, wenn Lizenz.txt vorhanden ist.
; Source: "Lizenz.txt"; DestDir: "{app}"; Flags: ignoreversion


[Icons]

; Ein gemeinsamer Startmenüeintrag für die Admin-Oberfläche.
; Dienst und Tray werden durch die Anwendung verwaltet.
Name: "{group}\AbwesenheitsManager"; Filename: "{app}\Admin\AbwesenheitsManager.Admin.exe"


[Code]

// Führt das mitgelieferte Wartungsskript aus.
// Verwendet die in Windows enthaltene Windows PowerShell.
// Wartet auf das Ende und prüft den Exitcode.
function RunMaintenance(Script: String; Mode: String): Boolean;
var
  ExitCode: Integer;
begin
  Result := Exec(
    ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' +
      Script + '" -Mode ' + Mode,
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ExitCode
  );

  Result := Result and (ExitCode = 0);
end;


// Bereitet die Installation beziehungsweise ein Update vor.
// Bei einem Fehler wird die Installation nicht fortgesetzt.
function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  ExtractTemporaryFile('Maintenance.ps1');

  if not RunMaintenance(
    ExpandConstant('{tmp}\Maintenance.ps1'),
    'Upgrade'
  ) then
    Result :=
      'Vorbereitung fehlgeschlagen. Admin-Fenster schließen ' +
      'und erneut versuchen. Details: ' +
      '%ProgramData%\AbwesenheitsManager-maintenance.log';
end;


// Führt die Bereinigung während der Deinstallation aus.
// Welche Komponenten und Daten entfernt werden, legt
// Maintenance.ps1 fest.
procedure CurUninstallStepChanged(
  CurUninstallStep: TUninstallStep
);
begin
  if CurUninstallStep = usUninstall then
  begin
    if not RunMaintenance(
      ExpandConstant('{app}\Setup\Maintenance.ps1'),
      'Uninstall'
    ) then
      RaiseException(
        'Bereinigung fehlgeschlagen. Admin-Fenster schließen ' +
        'und Deinstallation erneut ausführen. Details: ' +
        '%ProgramData%\AbwesenheitsManager-maintenance.log'
      );
  end;
end;