# PowerShell 7 und Kompilieren

### PowerShell 7 installieren und öffnen

PowerShell 7 wird zusätzlich zu Windows PowerShell 5.1 installiert. Ein bereits geöffnetes Fenster bleibt bei Version 5.1.

```powershell
winget install --id Microsoft.PowerShell --exact --source winget
```

Danach ein neues Terminal öffnen und PowerShell 7 starten:

```powershell
pwsh -NoProfile
```

Falls `pwsh` nicht gefunden wird, einen zur Installation passenden Pfad verwenden:

```powershell
& "$env:ProgramFiles\PowerShell\7\pwsh.exe"
# Alternativ bei der hier verwendeten WindowsApps-Installation:
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\Microsoft.PowerShell_8wekyb3d8bbwe\pwsh.exe"
```

Version prüfen – bei `Major` muss **7** stehen:

```powershell
$PSVersionTable.PSVersion
```

Falls beide Pfade fehlen, Installation und Speicherort prüfen:

```powershell
winget list --id Microsoft.PowerShell
where.exe /R "$env:LOCALAPPDATA" pwsh.exe
```

Weitere Installationsmöglichkeiten: [Microsoft – PowerShell unter Windows installieren](https://learn.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-windows).

### Alle Programme mit einem Befehl kompilieren

Voraussetzung: Das passende **.NET 9 SDK (9.0.3xx gemäß global.json)** ist installiert. Prüfen mit:

```powershell
dotnet --list-sdks
```

Die Projekt-ZIP entpacken. In PowerShell 7 in den Ordner wechseln, in dem **AbwesenheitsManager.sln** und der Unterordner **Scripts** liegen. Den Beispielpfad durch deinen tatsächlichen Ordner ersetzen:

```powershell
Set-Location -LiteralPath 'C:\Projekte\AbwesenheitsManager'
```

Dann **einmal** ausführen:

```powershell
.\Scripts\Publish.ps1
```

Dieser Aufruf kompiliert und veröffentlicht **Admin-App, Windows-Dienst und Tray-App gemeinsam**, einschließlich des Handbuchs. Du musst keine Dateien einzeln kompilieren.

Die fertigen Programme liegen danach hier:

```text
publish\Admin\AbwesenheitsManager.Admin.exe
publish\Service\AbwesenheitsManager.Service.exe
publish\Tray\AbwesenheitsManager.Tray.exe
```

Alle drei Ordner samt ihren weiteren Dateien zusammen an den endgültigen Installationsort kopieren. Das Tray anschließend über `Tray\AbwesenheitsManager.Tray.exe` starten. Der Windows-Dienst wird separat installiert; siehe **Build und Bereitstellung** in der [Programm-README](README.md).

**Nur die Solution bauen, ohne Veröffentlichung:**

```powershell
dotnet build .\AbwesenheitsManager.sln -c Release
```
