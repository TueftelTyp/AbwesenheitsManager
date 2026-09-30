# Abwesenheits Manager

Zentrale Verwaltung und automatische Pflege von Abwesenheitsnotizen in Microsoft Exchange Online.

Der **Abwesenheits Manager** ist eine Windows-Anwendung für Unternehmen, die einheitliche interne und externe Abwesenheitsnotizen in Microsoft 365 bereitstellen und automatisch überwachen möchten.

Die Anwendung besteht aus einer grafischen Administrationsoberfläche und einem Windows-Dienst. Sie prüft Exchange-Online-Postfächer regelmäßig und stellt definierte Standardvorlagen wieder her, wenn feste Bestandteile einer Abwesenheitsnotiz verändert oder entfernt wurden.

Dabei dürfen definierte Variablen wie Datum, Vertretung, E-Mail-Adresse oder Telefonnummer individuell durch Mitarbeiter angepasst werden.

---

## Ziel des Projekts

In vielen Unternehmen werden Abwesenheitsnotizen individuell formuliert. Dadurch entstehen häufig:

- unterschiedliche Formulierungen
- fehlende Vertretungsinformationen
- unvollständige Abwesenheitsangaben
- uneinheitliche interne und externe Kommunikation
- versehentlich gelöschte Pflichtinformationen

Der Abwesenheits Manager stellt eine zentrale Vorlage bereit, ohne die Mitarbeiter bei der Pflege ihrer individuellen Urlaubsdaten unnötig einzuschränken.

Das System unterscheidet zwischen:

- **festen Textbestandteilen**, die nicht verändert werden sollen
- **Variablen**, die Mitarbeiter individuell ausfüllen dürfen

---

## Funktionsumfang

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

## Automatischer Betrieb

Die Anwendung besteht aus zwei wesentlichen Komponenten:

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

### Sammelbenachrichtigungen

Um unnötige E-Mail-Mengen zu vermeiden, werden Fehler eines Durchlaufs gesammelt.

Statt für jedes Postfach eine einzelne Nachricht zu senden, erhält der Administrator maximal eine zusammengefasste Meldung pro Lauf.

Beispiel:

```text
Abwesenheits Manager

Postfächer geprüft: 84
Fehler: 3

Fehler:

- user1@example.de konnte nicht gelesen werden
- user2@example.de konnte nicht aktualisiert werden
- Exchange-Zeitüberschreitung bei user3@example.de
```

---

## Sichere Speicherung von SMTP-Zugangsdaten

SMTP-Passwörter werden nicht im Klartext in der Konfigurationsdatei gespeichert.

Die Anwendung verwendet Windows DPAPI mit:

```text
DataProtectionScope.LocalMachine
```

Dadurch ist das gespeicherte Geheimnis an den jeweiligen Windows-Rechner gebunden.

---

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

## Projektstruktur

Das Projekt ist in mehrere Komponenten aufgeteilt.

```text
AbwesenheitsManager.sln
│
├── AbwesenheitsManager.Admin
│
├── AbwesenheitsManager.Service
│
├── AbwesenheitsManager.Core
│
├── AbwesenheitsManager.Exchange
│
└── AbwesenheitsManager.Tests
```

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

### AbwesenheitsManager.Service

Windows-Hintergrunddienst.

Aufgaben:

- zeitgesteuerte Prüfungen
- Starten der Exchange-Verarbeitung
- Zertifikatsüberwachung
- Fehlerbehandlung
- SMTP-Warnmeldungen

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

### AbwesenheitsManager.Exchange

Exchange-spezifische Verarbeitung.

Unter anderem:

- Exchange-Online-Verbindung
- PowerShell-Prozesssteuerung
- Mailboxabfrage
- AutoReply-Prüfung
- Änderung von Abwesenheitsvorlagen
- Ergebniszusammenfassung

### AbwesenheitsManager.Tests

Lokale Regressionstests für zentrale Schutzmechanismen und Vorlagenlogik.

---

## Technologien

Das Projekt verwendet unter anderem:

```text
.NET 9
C#
WPF
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

## Sicherheitskonzept

Mehrere Schutzmechanismen sollen unbeabsichtigte Änderungen verhindern.

### Aktive automatische Antworten

`Enabled` und `Scheduled` werden grundsätzlich übersprungen.

### Dry-Run

Änderungen können zunächst ausschließlich simuliert werden.

### Zweite Prüfung vor Änderungen

Vor einem Schreibvorgang kann der Zustand eines Postfachs erneut geprüft werden.

### Getrennte Vorlagenprüfung

Interne und externe Texte werden unabhängig bewertet.

### Zertifikatsauthentifizierung

Es werden keine Microsoft-365-Benutzerkennwörter für den automatischen Betrieb benötigt.

### DPAPI

SMTP-Geheimnisse werden nicht im Klartext gespeichert.

### Ausschlussliste

Sonderpostfächer können von der Verarbeitung ausgenommen werden.

---

## Bekannte technische Grenze

Exchange Online bietet für `Set-MailboxAutoReplyConfiguration` keine atomare Compare-and-Set-Operation.

Daher besteht theoretisch ein sehr kleines Zeitfenster zwischen der letzten Statusprüfung und einer anschließenden Änderung.

Die Anwendung reduziert dieses Risiko durch erneute Prüfungen unmittelbar vor Schreibvorgängen.

Für eine vollständig schreibfreie Prüfung steht der Dry-Run-Modus zur Verfügung.

---

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

## Status des Projekts

Das Projekt ist als internes Administrationswerkzeug für Microsoft-365-/Exchange-Online-Umgebungen konzipiert.

Vor einem produktiven Rollout sollte die Anwendung immer zunächst mit einem Testpostfach beziehungsweise einem begrenzten Empfängerbereich geprüft werden.

---

## Lizenz

MIT


---

## Haftungshinweis

Die Anwendung verändert Exchange-Online-Konfigurationen.

Vor dem produktiven Einsatz sollten:

- Dry-Run-Ergebnisse geprüft
- Berechtigungen auf das notwendige Minimum reduziert
- Vorlagen getestet
- Pilotpostfächer verwendet
- geeignete Sicherungs- und Betriebsprozesse festgelegt werden

Der Einsatz erfolgt in Verantwortung des jeweiligen Administrators.
