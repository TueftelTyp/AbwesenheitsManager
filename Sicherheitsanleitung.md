# AbwesenheitsManager v2.0 – Sicherer Betrieb für Administratoren

Stand: 23.10.2026 · Zielgruppe: Windows- und Microsoft-365-Administratoren

Die wichtigsten Maßnahmen sind eingeschränkte Exchange-Rechte, ein geschützter Windows-Rechner und ausschließlich für Administratoren und SYSTEM zugängliche Geheimnisdateien. Die Anwendung bringt dafür Prüfungen mit. Die tatsächlichen Berechtigungen und die Betriebsumgebung muss der Administrator kontrollieren.

Diese Anleitung beschreibt den vorliegenden Quellcodestand. Die Bezeichnung v2.0 ist der vereinbarte Paketstand; sie bestätigt weder einen vollständigen Sicherheitstest noch eine Änderung sämtlicher interner Versionsangaben.

## Inhaltsverzeichnis

- [1. Vor dem produktiven Start](#1-vor-dem-produktiven-start)
- [2. Exchange-Rechte begrenzen](#2-exchange-rechte-begrenzen)
- [3. Windows und Installation schützen](#3-windows-und-installation-schützen)
- [4. Dateien und SMTP-Passwort schützen](#4-dateien-und-smtp-passwort-schützen)
- [5. Zertifikat und privaten Schlüssel schützen](#5-zertifikat-und-privaten-schlüssel-schützen)
- [6. SMTP und Berichte absichern](#6-smtp-und-berichte-absichern)
- [7. Einführung und Updates testen](#7-einführung-und-updates-testen)
- [8. Regelmäßige Kontrollen](#8-regelmäßige-kontrollen)
- [9. Vorgehen bei einem Sicherheitsverdacht](#9-vorgehen-bei-einem-sicherheitsverdacht)
- [10. Verbleibende Grenzen](#10-verbleibende-grenzen)

## 1. Vor dem produktiven Start

- [ ] Verantwortlichen Administrator und Vertretung festlegen.
- [ ] Dedizierte, gepflegte Windows-VM oder einen vergleichbar geschützten Rechner verwenden.
- [ ] Eigene Entra-App ausschließlich für den AbwesenheitsManager einsetzen.
- [ ] Exchange-Rollen und Zielpostfächer serverseitig einschränken.
- [ ] Daten- und Schlüsselrechte prüfen.
- [ ] SMTP mit TLS konfigurieren und Testmeldung prüfen.
- [ ] Dry-Run und Pilotlauf erfolgreich abnehmen.
- [ ] Installation, Neustart, Upgrade und Deinstallation auf einem Testsystem prüfen.
- [ ] Wiederherstellung und Zertifikatswechsel dokumentieren.

Solange Rechte oder Prüfungen unklar sind, automatische Dienstläufe deaktiviert lassen und zunächst im Dry-Run arbeiten.

## 2. Exchange-Rechte begrenzen

**Die App sollte keine pauschale Rolle Exchange Administrator oder Global Administrator erhalten.** Für diese PowerShell-Anwendung unterstützt Microsoft eigene Exchange-Rollengruppen mit eingeschränkten Befehlen und Empfänger-Schreibbereichen. Berechtigungen verschiedener Zuweisungen wirken zusammen; eine zusätzliche breite Rolle kann die gewünschte Einschränkung aufheben. [Microsoft: App-only-Authentifizierung, Schritt 5](https://learn.microsoft.com/powershell/exchange/app-only-auth-powershell-v2#step-5-assign-role-permissions-to-the-application).

Praktisches Vorgehen:

1. Der App `Exchange.ManageAsApp` mit Administratorzustimmung zuweisen.
2. Den Service Principal der Enterprise Application in Exchange zuordnen. Seine Objekt-ID nicht mit der Objekt-ID der App-Registrierung verwechseln.
3. Eigene Verwaltungsrollen und eine eigene Rollengruppe für die benötigten Lese- und Schreibbefehle erstellen. Benötigt werden `Get-EXOMailbox`, `Get-MailboxAutoReplyConfiguration` und `Set-MailboxAutoReplyConfiguration`. Die Rollenzuordnung der REST-Lesebefehle im Tenant prüfen.
4. Beim Schreibbefehl nur die benötigten Nachrichtenparameter und notwendigen gemeinsamen Parameter zulassen. Die Anwendung benötigt keine Berechtigung zum Ändern von Abwesenheitsstatus oder Zeitplan.
5. Einen Empfänger-Schreibbereich für die ausdrücklich freigegebenen Postfächer einrichten. Ein Schreibbereich beschränkt nicht automatisch das Lesen. [Microsoft: Bereiche von Rollenzuweisungen](https://learn.microsoft.com/Exchange/permissions-exo/role-groups).
6. Überflüssige breite Zuweisungen nach Prüfung entfernen und mit einer neuen App-Sitzung testen.

**Abnahme:** Ein autorisierter Pilot innerhalb des Bereichs muss funktionieren. Ein ausdrücklich freigegebener Negativtest auf einem Testpostfach außerhalb des Bereichs muss verweigert werden. Ein erfolgreicher Verbindungstest allein genügt nicht. Die lokale Ausschlussliste ersetzt keine serverseitige Berechtigungsgrenze.

Die Datei `EXCHANGE-RECHTE.md` in der Solution beschreibt die Zuordnung ausführlicher. Tenant-Änderungen sind nicht Bestandteil der automatischen Installation.

## 3. Windows und Installation schützen

- Möglichst einen dedizierten Rechner verwenden; keine gewöhnliche Arbeitsstation mit vielen wechselnden Benutzern.
- Windows, PowerShell 7 und das ExchangeOnlineManagement-Modul regelmäßig aktualisieren und Änderungen zunächst testen.
- Lokale Administratoren auf wenige zuständige Personen beschränken. Ein separates Administratorkonto verwenden; privilegierte Cloud-Anmeldungen nach Unternehmensvorgaben mit MFA absichern.
- Endpoint-Schutz aktiv halten. Keine pauschalen Ausnahmen für Programm-, PowerShell- oder Datenordner einrichten.
- Anwendung und PowerShell maschinenweit unter `C:\Program Files` installieren. Keine privilegierte Ausführung aus Downloads, Desktop, Freigaben oder benutzerbeschreibbaren Ordnern.
- ExchangeOnlineManagement für alle Benutzer im geschützten Modulpfad bereitstellen; keine Benutzer-Modulpfade in den Dienst einschleusen.
- Keine eingehenden Firewall-Ports allein für den AbwesenheitsManager öffnen. Er benötigt ausgehende Verbindungen zu den verwendeten Microsoft-Diensten und dem SMTP-Server; Proxy- und Firewallregeln im Pilotbetrieb prüfen.

Der Dienst läuft derzeit als **LocalSystem**. Ein anderes Konto ist in dieser Version kein unterstützter Konfigurationsschalter. Das Konto nicht einfach in der Diensteverwaltung umstellen: Installation, Schlüsselrechte und Datenzugriffe müssten gemeinsam angepasst und getestet werden. Ein separates Dienstkonto bleibt eine Entwicklungsaufgabe.

## 4. Dateien und SMTP-Passwort schützen

| Bereich | Erforderlicher Schutz |
|---|---|
| `%ProgramData%\AbwesenheitsManager` einschließlich Einstellungen, Jobs und Logs | Zugriff nur für SYSTEM und Administratoren |
| `%ProgramData%\AbwesenheitsManager.Status` | Benutzer dürfen Status lesen; nur privilegierte Konten dürfen schreiben |
| Installationsordner, Skripte, PowerShell und Exchange-Modul | Normale Benutzer dürfen keine Dateien oder Berechtigungen verändern |
| Sicherungen und alte Berichte | Mindestens ebenso streng schützen wie die Originaldaten |

Die Sicherheitsprüfung berücksichtigt auch explizite Rechte an untergeordneten Dateien. Bei einer Fehlermeldung keine pauschalen Vollzugriffsrechte für Benutzer vergeben und keine Prüfung auskommentieren. Ursache anhand von Besitzer, Vererbung und zusätzlichen Berechtigungseinträgen gezielt beheben.

Diese Befehle zeigen Rechte an und verändern nichts:

```powershell
icacls "$env:ProgramData\AbwesenheitsManager" /T
icacls "$env:ProgramData\AbwesenheitsManager.Status" /T
icacls "$env:ProgramFiles\AbwesenheitsManager" /T
```

Die Ausgabe ist eine Bestandsaufnahme, kein automatischer Sicherheitsnachweis. Auf einem Testsystem zusätzlich mit einem normalen Benutzer prüfen: Die private `settings.json` darf nicht lesbar sein; die Statusdatei darf lesbar, aber nicht beschreibbar sein.

Das SMTP-Passwort verwendet DPAPI mit `LocalMachine`. Andere Prozesse auf demselben Rechner können solche Daten grundsätzlich entschlüsseln, wenn sie an den verschlüsselten Inhalt gelangen. Deshalb sind die Dateirechte entscheidend. Die Einstellung nicht eigenmächtig auf `CurrentUser` umstellen, da GUI und Dienst unterschiedliche Identitäten verwenden. [Microsoft: DataProtectionScope](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.dataprotectionscope).

## 5. Zertifikat und privaten Schlüssel schützen

1. Ein eigenes Zertifikat ausschließlich für diese Anwendung verwenden. Bei der integrierten Erstellung bleibt der private Schlüssel nicht exportierbar im lokalen Computerspeicher.
2. Mit `certlm.msc` den Speicher **Persönlich → Zertifikate** öffnen.
3. Am richtigen Zertifikat **Alle Aufgaben → Private Schlüssel verwalten** prüfen: ausschließlich SYSTEM und Administratoren dürfen Zugriff erhalten. Auch den Besitzer prüfen lassen, wenn die Anwendung einen Rechtefehler meldet.
4. Für Entra nur den öffentlichen `.cer`-Teil exportieren. Keine PFX-Datei, privaten Schlüssel oder Geheimnisdateien an Supportmeldungen anhängen.
5. Zertifikatsablaufwarnungen aktivieren und den Wechsel beispielsweise 30 Tage vor Ablauf einplanen.
6. Neues Zertifikat in Entra hinterlegen, in der Anwendung auswählen und testen. Erst anschließend die alte Zuordnung nach Prüfung anderer Nutzungen entfernen.

Der Code prüft maschinenweite RSA-CSP-Software-Schlüssel und CNG-Schlüssel des Microsoft Software Key Storage Providers. Andere Provider werden abgewiesen. Ein vorhandener Hardware-Schlüssel ist damit derzeit nicht automatisch nutzbar. Importierte Schlüsselrechte werden nicht stillschweigend verändert.

Für eine Wiederherstellung auf einem anderen Rechner ein neues Zertifikat und neue SMTP-Anmeldedaten einplanen. Das Kopieren von `settings.json` allein stellt diese Geheimnisse nicht zuverlässig wieder her.

## 6. SMTP und Berichte absichern

- TLS auch bei einem Relay nach Möglichkeit aktivieren; bei SMTP-Anmeldung ist TLS zwingend.
- Zertifikatsprüfung nicht deaktivieren, um Verbindungsfehler zu umgehen.
- Ein eigenes Versandkonto oder eng beschränktes Relay verwenden. Zugriff, Absender und erlaubte Ziele nach Möglichkeit begrenzen.
- Sammelmeldungen nur an zuständige Administratoren oder ein geschütztes Funktionspostfach senden.
- Keine Geheimnisse in Betreff oder Einleitung eintragen; diese Texte werden versendet.
- Standardmäßig eine sparsame Logstufe verwenden. Debug nur gezielt aktivieren und anschließend zurückstellen.

Die aktuelle Sammelmeldung enthält Zeiten und Zähler. Lokale Berichte können weiterhin Postfachadressen enthalten. Ältere Logs werden nicht rückwirkend bereinigt; sie müssen gesondert geprüft, geschützt und nach der betrieblichen Aufbewahrungsregel gelöscht werden.

## 7. Einführung und Updates testen

1. Geschützte Sicherung der Konfiguration anlegen und Wiederherstellungsverfahren prüfen.
2. Zunächst Testtenant oder ausdrücklich freigegebene Pilotpostfächer nutzen.
3. Im Dry-Run geplante Änderungen kontrollieren.
4. Aktive und geplante Abwesenheiten sowie ausgeschlossene Postfächer testen: Sie dürfen nicht verändert werden.
5. Einen begrenzten echten Lauf prüfen und erst danach automatische Läufe aktivieren.
6. Deaktivieren und Speichern prüfen: Der Dienst muss inaktiv werden.
7. Admin-Fenster schließen und Tray-Verhalten prüfen. „Beenden“ im Tray darf den Dienst nicht stoppen.
8. Nach einem Neustart Dienstzustand und Benutzerautostart prüfen.
9. Upgrade und Deinstallation mit einem entbehrlichen Testsystem abnehmen; die Deinstallation entfernt auch Programmdaten.

Nur vertrauenswürdige Pakete verteilen. Für eigene Releases Setup und ausführbare Dateien signieren. Die eingebauten Skript-Hashes ersetzen keine vertrauenswürdige Release-Signatur. Skripte nicht nachträglich einzeln austauschen: Nach Änderungen müssen die Skripte und die Assembly mit ihren Referenz-Hashes gemeinsam neu gebaut werden.

Auf dem Build-Rechner den bislang offenen Paket-Schwachstellenscan durchführen und Befunde bewerten:

```powershell
dotnet list .\AbwesenheitsManager.sln package --vulnerable --include-transitive
```

Bei selbstenthaltender Veröffentlichung wird die .NET-Laufzeit mitgeliefert. Eine aktualisierte Systeminstallation allein aktualisiert diese Kopie nicht; ein aktualisiertes Paket neu veröffentlichen und installieren.

## 8. Regelmäßige Kontrollen

| Zeitpunkt | Kontrolle |
|---|---|
| Nach jedem Release oder Rechtewechsel | Dry-Run, Pilotlauf, Daten-/Schlüsselrechte und Dienststart prüfen |
| Mindestens wöchentlich | Letzten erfolgreichen Lauf, Fehler, Warnungen und fehlende Meldungen kontrollieren |
| Monatlich | Windows-/Runtime-/Modul-Updates, Paketbefunde und Zertifikatsrestlaufzeit prüfen |
| Vierteljährlich und bei Zuständigkeitswechsel | Lokale Administratoren, App-Rollen, Rollengruppen, Empfängerbereiche und SMTP-Zugänge überprüfen |
| Vor Zertifikatsablauf | Wechsel durchführen und Erfolg dokumentieren |

Für den Ausfall des Rechners oder SMTP-Servers eine unabhängige Überwachung vorsehen. Eine ausgebliebene Mail beweist keinen erfolgreichen Lauf. Die Zeitabstände sind ein organisatorischer Vorschlag und müssen zu den betrieblichen Vorgaben passen.

## 9. Vorgehen bei einem Sicherheitsverdacht

1. Automatische Läufe stoppen. Falls die GUI nicht nutzbar ist, den Dienst über die Windows-Diensteverwaltung stoppen und deaktivieren.
2. Bei Rechnerkompromittierung den Rechner nach dem betrieblichen Notfallplan isolieren. Nicht nur die Tray-App schließen.
3. Den Tenant-Administrator einschalten und die App-Zugriffe nach Notfallverfahren sperren; bloßes lokales Stoppen entzieht einem Angreifer keine bereits erlangten Cloud-Zugänge.
4. Logs, Zeitpunkte und betroffene Postfächer geschützt sichern. Geheimnisse nicht in Tickets kopieren.
5. Kompromittierte Zertifikatszuordnungen und SMTP-Zugänge ersetzen. Vorhandene Sitzungen/Tokens im Incident-Verfahren berücksichtigen; nicht von sofortiger Wirkung jeder Änderung ausgehen.
6. Erst nach Ursachenklärung, Wiederherstellung und erneuter Pilotabnahme freigeben.

## 10. Verbleibende Grenzen

- LocalSystem bleibt sehr privilegiert. Lokale Administratoren können auch Programmdateien und eingebettete Hashreferenzen ersetzen.
- Die tatsächlichen Tenant-Rechte wurden hier nicht geprüft oder geändert.
- Installation, UAC, Neustart, Upgrade, Deinstallation und reale CSP-/CNG-Schlüssel benötigen noch eine Abnahme auf einem Testsystem.
- Der Paket-Schwachstellenscan war in der Entwicklungsumgebung nicht abschließbar.
- Exchange-Prüfung und anschließendes Schreiben sind nicht atomar. Zwischen beiden Schritten bleibt ein kleines Zeitfenster für parallele Änderungen.

Der vorliegende Code wurde erfolgreich gebaut und mit 56 C#-Tests sowie 15 PowerShell-Tests geprüft. Diese Tests unterstützen die Abnahme, ersetzen aber keine Prüfung der konkreten Betriebsumgebung.
