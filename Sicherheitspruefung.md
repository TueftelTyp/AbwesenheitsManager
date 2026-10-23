# Sicherheitsprüfung – AbwesenheitsManager

Stand: 23.10.2026. Geprüft wurde der lokale Solution-Quellstand einschließlich Tray, ServiceSetup, PowerShell-Skripten und Inno-Setup-Vorlage. Änderungen betreffen den Quellcode, nicht eine bereits installierte Anwendung. Nach Übernahme neu veröffentlichen und das Setup neu erstellen.

## Befunde und Änderungen

| Priorität | Befund vor der Änderung | Behebung |
| --- | --- | --- |
| Hoch | SMTP-Test konnte bei ausgeschalteten Benachrichtigungen die TLS-Prüfung der Einstellungen umgehen und mit Benutzername ohne TLS senden. | Transportprüfung direkt in SmtpNotifier.Send, unabhängig vom Aufrufer und Enabled. |
| Hoch | Bereits vorhandene ProgramData-Verzeichnisse wurden ohne Eigentümer-/Verknüpfungsprüfung mit privilegierten Rechten übernommen. | Private Verzeichnisse mit restriktiven ACLs anlegen; bestehende Bäume auf Eigentümer, Schreibrechte und Reparse Points prüfen. Unsichere Altbestände werden abgewiesen statt automatisch übernommen. |
| Hoch | Konfigurierbare PowerShell-Ausführung und Modulsuche konnten benutzerbeschreibbare Programme oder Module privilegiert laden. | Programme/Skripte nur aus geschützten Programme-Verzeichnissen; ACL-/Eigentümerprüfung; feste maschinenweite PSModulePath-Liste; Ausschluss von CLR-Startup-/Profiler-Umgebungsvariablen; eigenes Arbeitsverzeichnis. |
| Hoch | Tray konnte die erhöhten Rechte der Admin-App erben. | Start über die vorhandene Explorer-Desktop-Automation; kein direkter erhöhter Fallback. Erstregistrierung des Autostarts erfolgt im Tray-Konto. |
| Mittel | Dienstverwaltung verließ sich auf den Dienstnamen allein. | Vor Änderung vorhandener Registrierungen exakten, quotierten ImagePath und LocalSystem prüfen; sichere Dienstdateien prüfen. Fremde Registrierung wird nicht verändert. |
| Mittel | Deinstallation beendete sämtliche gleichnamigen Tray-Prozesse und schrieb einen festen Logpfad in allgemein zugänglichem ProgramData. | Prozesspfad prüfen; Log unter geschütztem Programme-Verzeichnis mit Eigentümer-/ACL-Prüfung. Löschziele und Profile auf Verknüpfungen prüfen. Keine rekursive Löschung benutzergesteuerter Registry-Bäume. |
| Mittel | Datenzugriffe akzeptierten beliebige Dateinamen einschließlich Pfadbestandteilen; HTML-Kanonisierung hatte keine eigene Größen-/Tiefenbegrenzung. | Ausschluss von Traversal und NTFS-Streamsyntax, Verknüpfungsprüfung, maximal 1 MiB HTML und 128 Rekursionsebenen. Unverarbeitbare Postfächer führen zu Fehlern statt erzwungenen Änderungen. |

## Wichtige Änderungen für Installation und Betrieb

- Diese Fassung setzt eine geschützte Installation unter **Programme** voraus. Produktive Admin-/Dienst-/Tray-Ausführung aus Desktop-, Download- oder anderen benutzerbeschreibbaren Ordnern ist nicht mehr unterstützt. Build und lokale Tests bleiben im Quellordner möglich.
- PowerShell als maschinenweite Installation unter Programme bereitstellen. Der benutzerspezifische WindowsApps-Alias genügt für den privilegierten Exchange-Betrieb nicht.
- ExchangeOnlineManagement für alle Benutzer unter `Program Files\PowerShell\Modules` installieren. Persönliche Module und benutzergesteuerte Modulsuchpfade werden nicht berücksichtigt. Die Windows-Systemmodule bleiben für Zertifikatsverwaltung verfügbar.
- Vertrauenswürdige Eigentümer: SYSTEM, integrierte Administratorengruppe und TrustedInstaller. Unsichere vorhandene Daten-/Installationsordner zuerst administrativ prüfen und kontrolliert migrieren. Nicht pauschal Schreibrechte für Benutzer vergeben oder automatisch Besitz übernehmen.
- Die zuvor erzeugte ausführliche ISS mit individuellen Herausgeberangaben wurde nur im Chat ausgegeben. In einer eigenen angepassten ISS die neuen Änderungen an Maintenance.ps1 und dessen Logpfad übernehmen. Die beiliegende ISS enthält die aktualisierte Wartungsanbindung.
- Der Wartungslog liegt jetzt unter `%ProgramFiles%\AbwesenheitsManager-maintenance.log`.
- Wegen der nichtrekursiven Registry-Bereinigung kann ein leerer `Software\AbwesenheitsManager`-Schlüssel verbleiben. Dienst, Autostartwert und Programmeinstellungen werden gezielt entfernt.

## Verifikation

- Vollständiger Release-Build auf .NET 9: **0 Fehler, 0 Warnungen**.
- **44 C#-Tests bestanden**, einschließlich neuer Tests gegen SMTP ohne TLS, Dateipfad-Traversal/Streams und übergroßes/tief verschachteltes HTML.
- **10 PowerShell-Schutztests bestanden**, ohne Verbindung zu Exchange Online.
- Alle PowerShell-Skripte syntaktisch geprüft.
- Build mit `--no-restore -p:TargetPlatformMoniker=Windows%2CVersion=7.0`: Explizite Angabe des vorhandenen Windows-Ziels vermeidet die hier blockierte automatische SDK-Ordneranlage; das TargetFramework bleibt net9.0-windows.

## Grenzen und noch erforderliche Abnahme

Die Prüfung ist ein Quellcode-Review mit lokalen Tests, kein vollständiger Penetrationstest und keine Garantie für Fehlerfreiheit. Kein produktiver Dienst, keine Zertifikate, keine Autostarts und keine Benutzerprofile wurden auf diesem Rechner verändert.

Nicht ausgeführt: Inno-Setup-Kompilierung, Installation/Upgrade/Deinstallation, UAC-/Explorer-Interop-Test mit unterschiedlichen Benutzerkonten, Windows-Neustart, produktiver Exchange-/SMTP-Test sowie Angriffstests gegen ACLs/Verknüpfungsrennen auf einem separaten Windows-Testsystem. Diese Fälle müssen vor Freigabe abgenommen werden.

Der automatische NuGet-Schwachstellenscan konnte wegen des blockierten Zugriffs auf die NuGet-Benutzerkonfiguration nicht abgeschlossen werden. Ein zusätzlicher Direktabruf des offiziellen NuGet-Sicherheitsfeeds scheiterte an der TLS-Authentifizierung. Deshalb wird keine Aussage „alle Abhängigkeiten frei von bekannten Schwachstellen“ getroffen. Auf dem Build-Rechner ausführen:

```powershell
dotnet list .\AbwesenheitsManager.sln package --vulnerable --include-transitive
```

Lokale Administratoren können weiterhin Programmdateien, Konfiguration und Zertifikate ändern. Ein Schutz vor bereits kompromittierten Administrator-/SYSTEM-Konten ist nicht Ziel dieser Anwendung. DPAPI LocalMachine ist nur zusammen mit den Dateiberechtigungen vertraulich. Selbstsignierte Programmpakete/unsignierte Skripte ersetzen keine Release-Signatur; vor Verteilung vertrauenswürdigen Build und Codesignierung vorsehen.

Die bekannte Exchange-Grenze bleibt bestehen: Prüfung und anschließendes Set-MailboxAutoReplyConfiguration sind nicht atomar. Die vorhandenen Status-/Textprüfungen und Dry-Run-Schutzregeln bleiben erhalten.

## Referenz

Der Tray-Start über den bestehenden Desktop folgt dem von Microsoft beschriebenen Explorer-Broker-Prinzip: [Unelevated process from an elevated process](https://devblogs.microsoft.com/oldnewthing/20131118-00/?p=2643/).


## Nachtrag: zusätzliche Härtung vom 23.10.2026

Umgesetzt und lokal geprüft:

- Private ProgramData-Bäume werden auf unzulässige Lese- und Schreibrechte geprüft, einschließlich expliziter Rechte an bestehenden Dateien. Fehlende DACLs werden abgewiesen. Der öffentliche Statusordner bleibt gesondert lesbar.
- Private Zertifikatsschlüssel werden vor Nutzung auf SYSTEM-/Administrator-Zugriff, Besitzer und Reparse Points geprüft. Unterstützte Software-Provider: RSA-CSP und Microsoft Software KSP (CNG). Nicht prüfbare Provider werden abgewiesen. Importierte Schlüssel werden nicht verändert.
- PowerShell-Laufzeitskripte einschließlich Hilfsskripten werden gegen eingebettete SHA-256-Referenzen geprüft. Ausgabe-/Fehlerströme werden ohne unbeschränktes Sammeln im Speicher verworfen.
- Fremde Ausnahme-Freitexte werden nicht mehr in Laufberichte, Dienstlogs oder Fehlerdialoge der Admin-Anwendung übernommen. SMTP verwendet eine Positivliste aus Zeitpunkten und Zählern. Alte Logs bleiben bestehen und sind gesondert zu prüfen.
- Beide bisher unbegrenzten Regex-Zählungen durch literales Zählen ersetzt. Größen-/Variablen-/Regex-Limits gelten auch beim direkten Matching und vor der HTML-Traversierung.
- Neue EXCHANGE-RECHTE.md beschreibt den korrekten Weg über Exchange-PowerShell-Rollengruppen und Schreibbereiche. Breite Entra-Rollen werden nicht mehr als Standard empfohlen.

Validierung: 56 C#-Tests, 10 bestehende Exchange-Schutztests und 5 neue Tests mit synthetischen Schlüssel-ACLs bestanden; Release-Build ohne Fehler oder Warnungen. Das ist kein Test gegen reale Zertifikatschlüssel oder einen produktiven Tenant.

Weiter offen: Die tatsächlichen Tenant-Berechtigungen sind nicht geändert oder verifiziert. LocalSystem bleibt die Dienstidentität; ein separates Dienstkonto ist nicht implementiert. Paket-Schwachstellenscan und Installations-/Deinstallations-/UAC-/Neustarttests sowie die praktische CSP-/CNG-Abnahme bleiben offen. Daher sind nicht sämtliche Empfehlungen des Architekturreviews vollständig umgesetzt; die lokal ergänzte Härtung ist kein vollständiger Produktionsfreigabenachweis.
