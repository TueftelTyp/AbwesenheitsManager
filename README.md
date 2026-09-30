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

# Funktionsumfang

## Zentrale Abwesenheitsvorlagen

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

## Frei definierbare Variablen

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
