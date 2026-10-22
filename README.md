# AbwesenheitsManager

Zentrale Verwaltung und automatische Pflege von Abwesenheitsnotizen in Microsoft Exchange Online.

Der **AbwesenheitsManager** ist eine Windows-Anwendung für Unternehmen, die einheitliche interne und externe Abwesenheitsnotizen in Microsoft 365 bereitstellen und automatisch überwachen möchten.

Die Anwendung besteht aus einer grafischen Administrationsoberfläche, einem Windows-Dienst und einer Tray-Anwendung. Sie prüft Exchange-Online-Postfächer regelmäßig und stellt definierte Standardvorlagen wieder her, wenn feste Bestandteile einer Abwesenheitsnotiz verändert oder entfernt wurden.

Dabei dürfen definierte Variablen wie Datum, Vertretung, E-Mail-Adresse oder Telefonnummer individuell durch Mitarbeiter angepasst werden.

---

## Inhaltsverzeichnis

- [Ziel des Projekts](#abschnitt-1)
- [Funktionsumfang](#abschnitt-2)
  - [Zentrale Abwesenheitsvorlagen](#abschnitt-3)
  - [Frei definierbare Variablen](#abschnitt-4)
  - [Intelligente Vorlagenprüfung](#abschnitt-5)
  - [Schutz aktiver Abwesenheitsnotizen](#abschnitt-6)
  - [Getrennte Prüfung von intern und extern](#abschnitt-7)
- [Dry-Run / Testmodus](#abschnitt-8)
- [Mailbox-Ausnahmen](#abschnitt-9)
- [Automatischer Betrieb](#abschnitt-10)
  - [Admin-Anwendung](#abschnitt-11)
  - [Tray-Anwendung](#abschnitt-12)
  - [Windows-Dienst](#abschnitt-13)
- [Microsoft 365 / Exchange Online](#abschnitt-14)
- [Zertifikatsauthentifizierung](#abschnitt-15)
  - [Zertifikatsüberwachung](#abschnitt-16)
- [SMTP-Benachrichtigungen](#abschnitt-17)
  - [Sammelbenachrichtigungen](#abschnitt-18)
- [Sichere Speicherung von SMTP-Zugangsdaten](#abschnitt-19)
- [Logging](#abschnitt-20)
- [Konfigurationsdaten](#abschnitt-21)
- [Projektstruktur](#abschnitt-22)
  - [AbwesenheitsManager.Admin](#abschnitt-23)
  - [AbwesenheitsManager.Service](#abschnitt-24)
  - [AbwesenheitsManager.Core](#abschnitt-25)
  - [AbwesenheitsManager.Exchange](#abschnitt-26)
  - [AbwesenheitsManager.Tests](#abschnitt-27)
- [Technologien](#abschnitt-28)
- [Voraussetzungen](#abschnitt-29)
- [Build und Bereitstellung](#abschnitt-30)
  - [1. Quellcode entpacken und Solution-Ordner finden](#abschnitt-31)
  - [2. .NET SDK prüfen](#abschnitt-32)
  - [3. In den Solution-Ordner wechseln](#abschnitt-33)
  - [4. Alle Programme in einer Ausführung erstellen](#abschnitt-34)
  - [5. Optional: Solution bauen und Schutztests ausführen](#abschnitt-35)
  - [6. Programme bereitstellen und Tray starten](#abschnitt-36)
- [Sicherheitskonzept](#abschnitt-37)
  - [Aktive automatische Antworten](#abschnitt-38)
  - [Dry-Run](#abschnitt-39)
  - [Zweite Prüfung vor Änderungen](#abschnitt-40)
  - [Getrennte Vorlagenprüfung](#abschnitt-41)
  - [Zertifikatsauthentifizierung](#abschnitt-42)
  - [DPAPI](#abschnitt-43)
  - [Ausschlussliste](#abschnitt-44)
- [Bekannte technische Grenze](#abschnitt-45)
- [Beispielhafter Ablauf](#abschnitt-46)
- [Empfohlene Inbetriebnahme](#abschnitt-47)
- [Status des Projekts](#abschnitt-48)
- [PowerShell 7 einrichten](#abschnitt-49)
- [Lizenz](#abschnitt-50)
- [Haftungshinweis](#abschnitt-51)

---


<a id="abschnitt-1"></a>

## Ziel des Projekts

In vielen Unternehmen werden Abwesenheitsnotizen individuell formuliert. Dadurch entstehen häufig:

- unterschiedliche Formulierungen
- fehlende Vertretungsinformationen
- unvollständige Abwesenheitsangaben
- uneinheitliche interne und externe Kommunikation
- versehentlich gelöschte Pflichtinformationen

Der AbwesenheitsManager stellt eine zentrale Vorlage bereit, ohne die Mitarbeiter bei der Pflege ihrer individuellen Urlaubsdaten unnötig einzuschränken.

Das System unterscheidet zwischen:

- **festen Textbestandteilen**, die nicht verändert werden sollen
- **Variablen**, die Mitarbeiter individuell ausfüllen dürfen

---

<a id="abschnitt-2"></a>

## Funktionsumfang

<a id="abschnitt-3"></a>

### Zentrale Abwesenheitsvorlagen

Für interne und externe automatische Antworten können vollständig getrennte Vorlagen definiert werden.

Beispiel:

> Vielen Dank für Ihre Nachricht.
>
> Ich befinde mich derzeit im Urlaub und bin bis einschließlich **[Datum]** nicht erreichbar. Ihre E-Mail wird nicht weitergeleitet und nach meiner Rückkehr schnellstmöglich bearbeitet.
>
> In dringenden Fällen wenden Sie sich bitte an **[Vertretung]** unter **[E-Mail-Adresse]** oder **[Telefonnummer]**.
>
> Vielen Dank für Ihr Verständnis.
>
> Mit freundlichen Grüßen

Interne und externe Texte können unabhängig voneinander verwaltet werden.

---

<a id="abschnitt-4"></a>

### Frei definierbare Variablen

Variablen sind nicht fest im Programm hinterlegt.

Administratoren können beliebig viele eigene Variablen erstellen.

Beispiele:

```text
[Datum]
[Vertretung]
[E-Mail-Adresse]
[Telefonnummer]
[Niederlassung]
[Abteilung]
[Vertretung-Telefon]
```

Für jede Variable können unter anderem definiert werden:

- Name
- Platzhalter
- Beschreibung
- optionale Validierungsregel
- optionaler regulärer Ausdruck

Damit kann beispielsweise für eine E-Mail-Adresse zusätzlich geprüft werden, ob der eingetragene Wert einem erwarteten Format entspricht.

---

<a id="abschnitt-5"></a>

### Intelligente Vorlagenprüfung

Die Anwendung vergleicht eine bestehende Abwesenheitsnotiz nicht einfach Zeichen für Zeichen mit der Vorlage.

Stattdessen werden die festen Bestandteile der Vorlage geschützt, während definierte Variablen verändert werden dürfen.

Vorlage:

```text
Ich befinde mich bis einschließlich [Datum] im Urlaub.
```

Zulässig:

```text
Ich befinde mich bis einschließlich 18.10.2026 im Urlaub.
```

Nicht zulässig:

```text
Bin bis zum 18.10. weg.
```

Im zweiten Fall wurde der feste Textbestandteil verändert. Die Anwendung kann deshalb die definierte Standardvorlage wiederherstellen.

---

<a id="abschnitt-6"></a>

### Schutz aktiver Abwesenheitsnotizen

Ein wichtiger Sicherheitsmechanismus ist die Prüfung des aktuellen Exchange-Status.

Postfächer mit:

```text
Enabled
```

oder:

```text
Scheduled
```

werden nicht verändert.

Nur Postfächer mit:

```text
Disabled
```

werden hinsichtlich ihrer Vorlagen geprüft.

Damit soll verhindert werden, dass eine aktuell verwendete oder bereits geplante Abwesenheitsnotiz während eines Urlaubs überschrieben wird.

---

<a id="abschnitt-7"></a>

### Getrennte Prüfung von intern und extern

Interne und externe automatische Antworten werden unabhängig voneinander geprüft.

Beispiel:

```text
Interne Vorlage:  korrekt
Externe Vorlage:  verändert
```

In diesem Fall muss nur die externe Vorlage korrigiert werden.

Die interne Abwesenheitsnotiz bleibt unverändert.

---

<a id="abschnitt-8"></a>

## Dry-Run / Testmodus

Vor produktiven Änderungen kann die Anwendung vollständig im **Dry-Run-Modus** betrieben werden.

Dabei wird Exchange Online tatsächlich ausgelesen, jedoch werden keine Postfächer verändert.

Eine Zusammenfassung kann beispielsweise anzeigen:

```text
Postfächer geprüft:                 87
Aktive/geplante Abwesenheiten:      9
Vorlage korrekt:                   71
Intern würde korrigiert:             3
Extern würde korrigiert:             4
Fehler:                              0
```

Dadurch kann die Konfiguration vor der produktiven Aktivierung überprüft werden.

---

<a id="abschnitt-9"></a>

## Mailbox-Ausnahmen

Bestimmte Postfächer können von der Verarbeitung ausgeschlossen werden.

Beispiele:

```text
info@example.de
bewerbung@example.de
geschaeftsfuehrung@example.de
```

Die Ausschlussliste arbeitet auf Basis der primären SMTP-Adresse.

Damit können beispielsweise Sonderpostfächer oder Postfächer mit individuellen Anforderungen ausgenommen werden.

---

<a id="abschnitt-10"></a>

## Automatischer Betrieb

Admin-Anwendung und Windows-Dienst übernehmen Konfiguration und automatische Verarbeitung. Ergänzend stellt die Tray-Anwendung den schnellen Zugriff über die Taskleiste bereit:

```text
AbwesenheitsManager.Admin
        │
        │ Konfiguration
        ▼
gemeinsame Einstellungen
        │
        ▼
AbwesenheitsManager.Service
        │
        │ regelmäßig
        ▼
Exchange Online
```

<a id="abschnitt-11"></a>

### Admin-Anwendung

Die grafische Oberfläche dient zur Konfiguration und Kontrolle.

Unter anderem können dort verwaltet werden:

- Microsoft-365-Verbindung
- Tenant
- App-ID
- Zertifikat
- interne Vorlage
- externe Vorlage
- Variablen
- Ausschlussliste
- SMTP
- Prüfintervall
- Logging
- Dry-Run
- Zertifikatsstatus

<a id="abschnitt-12"></a>

### Tray-Anwendung

`AbwesenheitsManager.Tray` läuft im angemeldeten Benutzerkonto unabhängig vom Windows-Dienst.

- Eigenes Programmicon mit grüner, gelber, roter oder grauer Statusmarkierung.
- Anzeige des Dienststatus sowie der letzten und nächsten Prüfung.
- Doppelklick öffnet die Admin-Oberfläche.
- **Jetzt prüfen** öffnet die manuelle Laufauswahl der Admin-App.
- **Beenden** schließt ausschließlich das Tray, niemals den Windows-Dienst.
- Benutzerautostart ist in der Admin-App ein- und ausschaltbar.

<a id="abschnitt-13"></a>

### Windows-Dienst

Der eigentliche automatische Betrieb erfolgt über einen Windows-Dienst.

Dadurch ist keine Benutzeranmeldung am Server erforderlich.

Der Dienst kann beispielsweise alle:

```text
24 Stunden
```

die Postfächer überprüfen.

Das Prüfintervall ist konfigurierbar.

---

<a id="abschnitt-14"></a>

## Microsoft 365 / Exchange Online

Die Kommunikation mit Exchange Online erfolgt über PowerShell und das Modul:

```text
ExchangeOnlineManagement
```

Die Anwendung verwendet eine Entra-App für die unbeaufsichtigte Authentifizierung.

Es wird kein dauerhaft angemeldetes Microsoft-365-Administratorkonto benötigt.

Verwendet werden:

```text
Tenant
App-ID
Zertifikat
```

Die Entra-App benötigt unter anderem die Exchange-Online-Anwendungsberechtigung:

```text
Exchange.ManageAsApp
```

Zusätzlich müssen passende Exchange-Verwaltungsrechte eingerichtet werden.

---

<a id="abschnitt-15"></a>

## Zertifikatsauthentifizierung

Die Anwendung unterstützt die Verwaltung eines Zertifikats für die Exchange-Online-Anmeldung.

Über die Administrationsoberfläche kann ein Zertifikat:

- erstellt
- geprüft
- angezeigt
- auf Ablauf kontrolliert
- als öffentliche `.cer`-Datei exportiert werden

Der private Schlüssel verbleibt im lokalen Zertifikatsspeicher des Servers.

Verwendeter Zertifikatsspeicher:

```text
LocalMachine\My
```

Die öffentliche `.cer`-Datei wird anschließend in der entsprechenden Entra-App registriert.

---

<a id="abschnitt-16"></a>

### Zertifikatsüberwachung

Die Anwendung überwacht die Restlaufzeit des verwendeten Zertifikats.

Beispiel:

```text
Zertifikat gültig bis: 30.09.2029
Restlaufzeit:           1095 Tage
```

Unterschreitet das Zertifikat einen konfigurierbaren Grenzwert, kann eine Warnung erzeugt werden.

Beispiel:

```text
WARNUNG:
Das Exchange-Zertifikat läuft in 30 Tagen ab.
```

---

<a id="abschnitt-17"></a>

## SMTP-Benachrichtigungen

Die Anwendung kann Administratoren über wichtige Ereignisse per SMTP informieren.

Konfigurierbar sind unter anderem:

- SMTP-Server
- Port
- STARTTLS
- Benutzername
- Passwort
- Absender
- Empfänger
- Meldungen bei Fehlern
- Meldungen bei Warnungen

Beispielsweise kann bei einem ablaufenden Zertifikat automatisch eine Nachricht versendet werden.

---

<a id="abschnitt-18"></a>

### Sammelbenachrichtigungen

Um unnötige E-Mail-Mengen zu vermeiden, werden Fehler eines Durchlaufs gesammelt.

Statt für jedes Postfach eine einzelne Nachricht zu senden, erhält der Administrator maximal eine zusammengefasste Meldung pro Lauf.

Beispiel:

```text
AbwesenheitsManager

Postfächer geprüft: 84
Fehler: 3

Fehler:

- user1@example.de konnte nicht gelesen werden
- user2@example.de konnte nicht aktualisiert werden
- Exchange-Zeitüberschreitung bei user3@example.de
```

---

<a id="abschnitt-19"></a>

## Sichere Speicherung von SMTP-Zugangsdaten

SMTP-Passwörter werden nicht im Klartext in der Konfigurationsdatei gespeichert.

Die Anwendung verwendet Windows DPAPI mit:

```text
DataProtectionScope.LocalMachine
```

Dadurch ist das gespeicherte Geheimnis an den jeweiligen Windows-Rechner gebunden.

---

<a id="abschnitt-20"></a>

## Logging

Das Logging ist konfigurierbar.

Verfügbare Stufen:

```text
Off
Error
Warning
Information
Debug
```

Standardmäßig wird empfohlen:

```text
Warning
```

Dadurch werden normale erfolgreiche Mailbox-Prüfungen nicht dauerhaft protokolliert.

Typische Einträge sind beispielsweise:

```text
[WARN] Zertifikat läuft in 20 Tagen ab.

[ERROR] Exchange Online konnte nicht erreicht werden.

[ERROR] Postfach user@example.de konnte nicht aktualisiert werden.
```

Die Protokolle befinden sich standardmäßig unter:

```text
C:\ProgramData\AbwesenheitsManager\Logs
```

beziehungsweise:

```text
%ProgramData%\AbwesenheitsManager\Logs
```

---

<a id="abschnitt-21"></a>

## Konfigurationsdaten

Die Anwendungsdaten werden standardmäßig unter:

```text
%ProgramData%\AbwesenheitsManager
```

gespeichert.

Beispielsweise:

```text
AbwesenheitsManager
│
├── settings.json
├── last-run.json
│
├── Logs
│   └── 2026-09.log
│
└── Jobs
```

---

<a id="abschnitt-22"></a>

## Projektstruktur

Das Projekt ist in mehrere Komponenten aufgeteilt.

```text
AbwesenheitsManager.sln
│
├── AbwesenheitsManager.Admin
│
├── AbwesenheitsManager.Service
│
├── AbwesenheitsManager.Tray
│
├── AbwesenheitsManager.Core
│
├── AbwesenheitsManager.Exchange
│
└── AbwesenheitsManager.Tests
```

<a id="abschnitt-23"></a>

### AbwesenheitsManager.Admin

WPF-basierte Administrationsoberfläche.

Aufgaben:

- Konfiguration
- Vorlagenverwaltung
- Variablenverwaltung
- Zertifikatsverwaltung
- SMTP-Einstellungen
- Testläufe
- Statusanzeige

<a id="abschnitt-24"></a>

### AbwesenheitsManager.Service

Windows-Hintergrunddienst.

Aufgaben:

- zeitgesteuerte Prüfungen
- Starten der Exchange-Verarbeitung
- Zertifikatsüberwachung
- Fehlerbehandlung
- SMTP-Warnmeldungen

<a id="abschnitt-25"></a>

### AbwesenheitsManager.Core

Gemeinsam verwendete Kernlogik.

Enthält unter anderem:

- Konfigurationsmodelle
- DPAPI
- Logging
- SMTP
- Zertifikatsverwaltung
- Vorlagenprüfung
- Variablenlogik

<a id="abschnitt-26"></a>

### AbwesenheitsManager.Exchange

Exchange-spezifische Verarbeitung.

Unter anderem:

- Exchange-Online-Verbindung
- PowerShell-Prozesssteuerung
- Mailboxabfrage
- AutoReply-Prüfung
- Änderung von Abwesenheitsvorlagen
- Ergebniszusammenfassung

<a id="abschnitt-27"></a>

### AbwesenheitsManager.Tests

Lokale Regressionstests für zentrale Schutzmechanismen und Vorlagenlogik.

---

<a id="abschnitt-28"></a>

## Technologien

Das Projekt verwendet unter anderem:

```text
.NET 9
C#
WPF
Windows Forms (Tray)
Windows Services
PowerShell 7
ExchangeOnlineManagement
Microsoft Entra ID
Exchange Online
Windows Certificate Store
Windows DPAPI
SMTP
HTML
Regex
```

---

<a id="abschnitt-29"></a>

## Voraussetzungen

Für Entwicklung und Build:

```text
Visual Studio 2022
.NET 9 SDK
.NET Desktop Development Workload
```

Für den Betrieb:

```text
Windows x64
PowerShell 7
ExchangeOnlineManagement
Internetzugriff zu Exchange Online
Entra-App
Exchange-Zertifikat
```

Für SMTP-Benachrichtigungen wird zusätzlich ein erreichbarer SMTP-Server bzw. SMTP-Relay benötigt.

---

<a id="abschnitt-30"></a>

## Build und Bereitstellung

Die folgenden Schritte benötigen PowerShell 7. Eine kurze Anleitung dazu steht am Ende dieser README im Abschnitt **PowerShell 7 einrichten**.

<a id="abschnitt-31"></a>

### 1. Quellcode entpacken und Solution-Ordner finden

Die ZIP-Datei vollständig entpacken. Der **Solution-Ordner** ist der Ordner, in dem die Datei `AbwesenheitsManager.sln` liegt. Er enthält auch den Ordner `Scripts` und die einzelnen Projektordner.

```text
AbwesenheitsManager
├── AbwesenheitsManager.sln
├── global.json
├── Scripts
│   ├── Build-Help.ps1
│   ├── Publish.ps1
│   └── Install-Service.ps1
├── AbwesenheitsManager.Admin
├── AbwesenheitsManager.Service
└── AbwesenheitsManager.Tray
```

Alle folgenden Projektbefehle werden in diesem Solution-Ordner ausgeführt, nicht innerhalb der ZIP und nicht im Ordner `C:\Windows\System32`.

<a id="abschnitt-32"></a>

### 2. .NET SDK prüfen

Der Quellstand verwendet `.NET 9` und legt in `global.json` SDK `9.0.300` mit `rollForward: latestPatch` fest. Benötigt wird daher ein SDK aus der Reihe **9.0.3xx**, beispielsweise `9.0.318`. Eine allein installierte .NET-Laufzeit reicht zum Bauen nicht aus.

Installierte SDKs anzeigen:

```powershell
dotnet --list-sdks
```

Für den Build über die Kommandozeile ist Visual Studio nicht erforderlich. Für die Arbeit in Visual Studio die oben genannten Entwicklungsvoraussetzungen installieren. Bei einer Meldung zum fehlenden SDK zuerst `global.json` und die installierte SDK-Liste vergleichen.

<a id="abschnitt-33"></a>

### 3. In den Solution-Ordner wechseln

Den tatsächlichen Pfad des entpackten Ordners einsetzen. Beispiel:

```powershell
Set-Location -LiteralPath 'C:\Projekte\AbwesenheitsManager'
```

Die Anführungszeichen sind auch für Pfade mit Leerzeichen oder `C#` geeignet. Anschließend prüfen:

```powershell
Test-Path -LiteralPath '.\AbwesenheitsManager.sln'
Test-Path -LiteralPath '.\Scripts\Publish.ps1'
```

Beide Befehle müssen `True` ausgeben.

<a id="abschnitt-34"></a>

### 4. Alle Programme in einer Ausführung erstellen

In **PowerShell 7** im Solution-Ordner ausführen:

```powershell
.\Scripts\Publish.ps1
```

Dieser eine Aufruf:

1. erzeugt das lokale HTML-Handbuch aus der README,
2. baut und veröffentlicht die Admin-Anwendung,
3. baut und veröffentlicht den Windows-Dienst,
4. baut und veröffentlicht die Tray-Anwendung.

Die Projekte müssen nicht einzeln erstellt werden. Der Vorgang benötigt beim erstmaligen Herunterladen der Pakete Internetzugriff und kann einige Minuten dauern. Bei einem Fehler die vollständige Fehlermeldung beachten; möglicherweise wurden dann erst einige der Programme erstellt.

Die fertigen Ausgaben liegen anschließend hier:

```text
publish
├── Admin
│   ├── AbwesenheitsManager.Admin.exe
│   ├── Help
│   └── weitere benötigte Dateien
├── Service
│   ├── AbwesenheitsManager.Service.exe
│   └── weitere benötigte Dateien
└── Tray
    ├── AbwesenheitsManager.Tray.exe
    └── weitere benötigte Dateien
```

Das Skript veröffentlicht für **Windows x64** mit enthaltener .NET-Laufzeit. **PowerShell 7 und das ExchangeOnlineManagement-Modul sind darin nicht enthalten** und werden für den Betrieb separat benötigt.

Alternativ kann das Skript aus einem älteren PowerShell-Fenster ausdrücklich mit PowerShell 7 gestartet werden, sofern `pwsh` gefunden wird:

```powershell
pwsh -NoProfile -File .\Scripts\Publish.ps1
```

<a id="abschnitt-35"></a>

### 5. Optional: Solution bauen und Schutztests ausführen

Für einen Entwicklungsbuild ohne Veröffentlichung:

```powershell
dotnet build .\AbwesenheitsManager.sln -c Release
```

Die vorhandenen lokalen Tests ausführen:

```powershell
dotnet run --project .\AbwesenheitsManager.Tests -c Release
.\Scripts\Test-Guards.ps1
```

Ein Build allein installiert keinen Dienst und aktiviert keinen Autostart. Für die gemeinsam bereitgestellten Admin-/Service-/Tray-Ordner den Publish-Aufruf aus Schritt 4 verwenden.

<a id="abschnitt-36"></a>

### 6. Programme bereitstellen und Tray starten

Die **gesamten drei Ausgabeordner** `Admin`, `Service` und `Tray` aus `publish` gemeinsam an einen festen Installationsort kopieren. Die Ordner müssen nebeneinander liegen; nicht nur die EXE-Dateien kopieren.

Beispiel:

```text
C:\Program Files\AbwesenheitsManager
├── Admin
├── Service
└── Tray
```

Die Admin-App über `Admin\AbwesenheitsManager.Admin.exe` öffnen und konfigurieren. Für das Tray-Symbol `Tray\AbwesenheitsManager.Tray.exe` im normalen Benutzerkonto starten. Das Symbol erscheint neben der Uhr oder im Überlaufmenü der Taskleiste.

In der Admin-App unter **Betrieb → Tray-Anwendung** den Schalter **Tray-Symbol bei der Anmeldung dieses Kontos starten** setzen und **Tray-Autostart übernehmen** anklicken. Vorher den endgültigen Installationsort festlegen, da der Autostart einen absoluten Pfad speichert.

Der Schalter gilt für das in der Admin-App angezeigte Benutzerkonto. Wenn die Admin-App mit Zugangsdaten eines anderen Administrators geöffnet wurde, den Autostart im gewünschten normalen Benutzerkonto setzen:

```powershell
.\Scripts\Set-TrayAutostart.ps1 -TrayPath 'C:\Program Files\AbwesenheitsManager\Tray\AbwesenheitsManager.Tray.exe'
```

Der Publish-Aufruf installiert den Windows-Dienst nicht. Die Dienstinstallation erfolgt separat in einer **als Administrator geöffneten PowerShell** aus dem Solution-Ordner:

```powershell
.\Scripts\Install-Service.ps1 -ServiceDirectory 'C:\Program Files\AbwesenheitsManager\Service'
```

Das Installationsskript startet den Dienst noch nicht. Erst die Konfiguration und den Dry-Run prüfen und anschließend starten:

```powershell
Start-Service AbwesenheitsManager
```

Der für den Dienst konfigurierte PowerShell-Pfad muss unter dessen Konto `LocalSystem` nutzbar sein. Ein benutzerspezifischer WindowsApps-Alias, der beim manuellen Build funktioniert, ist dafür kein ausreichender Nachweis. Auf dem Diensthost eine für den Dienst zugängliche PowerShell-Installation und das benötigte Exchange-Modul bereitstellen und den vollständigen PowerShell-Pfad in der Admin-App hinterlegen.

---

<a id="abschnitt-37"></a>

## Sicherheitskonzept

Mehrere Schutzmechanismen sollen unbeabsichtigte Änderungen verhindern.

<a id="abschnitt-38"></a>

### Aktive automatische Antworten

`Enabled` und `Scheduled` werden grundsätzlich übersprungen.

<a id="abschnitt-39"></a>

### Dry-Run

Änderungen können zunächst ausschließlich simuliert werden.

<a id="abschnitt-40"></a>

### Zweite Prüfung vor Änderungen

Vor einem Schreibvorgang kann der Zustand eines Postfachs erneut geprüft werden.

<a id="abschnitt-41"></a>

### Getrennte Vorlagenprüfung

Interne und externe Texte werden unabhängig bewertet.

<a id="abschnitt-42"></a>

### Zertifikatsauthentifizierung

Es werden keine Microsoft-365-Benutzerkennwörter für den automatischen Betrieb benötigt.

<a id="abschnitt-43"></a>

### DPAPI

SMTP-Geheimnisse werden nicht im Klartext gespeichert.

<a id="abschnitt-44"></a>

### Ausschlussliste

Sonderpostfächer können von der Verarbeitung ausgenommen werden.

---

<a id="abschnitt-45"></a>

## Bekannte technische Grenze

Exchange Online bietet für `Set-MailboxAutoReplyConfiguration` keine atomare Compare-and-Set-Operation.

Daher besteht theoretisch ein sehr kleines Zeitfenster zwischen der letzten Statusprüfung und einer anschließenden Änderung.

Die Anwendung reduziert dieses Risiko durch erneute Prüfungen unmittelbar vor Schreibvorgängen.

Für eine vollständig schreibfreie Prüfung steht der Dry-Run-Modus zur Verfügung.

---

<a id="abschnitt-46"></a>

## Beispielhafter Ablauf

```text
Windows-Dienst startet Prüfung
            │
            ▼
Zertifikat prüfen
            │
            ▼
Exchange Online verbinden
            │
            ▼
Mailboxen abrufen
            │
            ▼
      AutoReplyState?
      /      |       \
Disabled  Enabled  Scheduled
   │         │         │
   │         └──► überspringen
   │
   ▼
interne/externe Vorlage prüfen
          │
      ┌───┴───┐
      │       │
    gültig  verändert
      │       │
      │       ▼
      │    Vorlage
      │    korrigieren
      │
      ▼
 nächstes Postfach
```

---

<a id="abschnitt-47"></a>

## Empfohlene Inbetriebnahme

1. Entra-App konfigurieren
2. Zertifikat erstellen
3. Zertifikat in Entra hinterlegen
4. Exchange-Berechtigungen konfigurieren
5. Verbindung testen
6. Vorlagen konfigurieren
7. Variablen prüfen
8. Ausschlussliste pflegen
9. SMTP testen
10. Dry-Run durchführen
11. Ergebnisse prüfen
12. produktive Verarbeitung aktivieren
13. Windows-Dienst starten

---

<a id="abschnitt-48"></a>

## Status des Projekts

Das Projekt ist als internes Administrationswerkzeug für Microsoft-365-/Exchange-Online-Umgebungen konzipiert.

Vor einem produktiven Rollout sollte die Anwendung immer zunächst mit einem Testpostfach beziehungsweise einem begrenzten Empfängerbereich geprüft werden.

---

<a id="abschnitt-49"></a>

## PowerShell 7 einrichten

PowerShell 7 wird zusätzlich zur Windows PowerShell 5.1 installiert. Ein bereits geöffnetes Fenster bleibt bei seiner bisherigen Version.

**Installieren:**

```powershell
winget install --id Microsoft.PowerShell --exact --source winget
```

**Danach ein neues Terminal öffnen, PowerShell 7 starten und die Version prüfen:**

```powershell
pwsh -NoProfile
$PSVersionTable.PSVersion
```

Bei `Major = 7` ist die richtige Version geöffnet. Wird `pwsh` nicht gefunden, je nach Installation einen dieser Pfade verwenden:

```powershell
& "$env:ProgramFiles\PowerShell\7\pwsh.exe"
# Alternativ bei der hier verwendeten WindowsApps-Installation:
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\Microsoft.PowerShell_8wekyb3d8bbwe\pwsh.exe"
```

Falls beide Pfade fehlen, Installation und Speicherort prüfen:

```powershell
winget list --id Microsoft.PowerShell
where.exe /R "$env:LOCALAPPDATA" pwsh.exe
```

Weitere Installationsmöglichkeiten: [Microsoft – PowerShell unter Windows installieren](https://learn.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-windows).

---

<a id="abschnitt-50"></a>

## Lizenz

MIT


---

<a id="abschnitt-51"></a>

## Haftungshinweis

Die Anwendung verändert Exchange-Online-Konfigurationen.

Vor dem produktiven Einsatz sollten:

- Dry-Run-Ergebnisse geprüft
- Berechtigungen auf das notwendige Minimum reduziert
- Vorlagen getestet
- Pilotpostfächer verwendet
- geeignete Sicherungs- und Betriebsprozesse festgelegt werden

Der Einsatz erfolgt in Verantwortung des jeweiligen Administrators.


