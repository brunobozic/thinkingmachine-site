---
title: "NFR-Compliance-Antwort für einen Tier-1-europäischen Energieanbieter"
sector: "Tier-1-europäischer Energieanbieter"
engagementType: "Vor-Vertrag-Due-Diligence — strukturierte NFR-Antwort"
year: "2026"
region: "Nordeuropa"
summary: "Eine multi-domänen NFR-Matrix eines Enterprise-Beschaffungsteams — rund fünfzig Punkte über Sicherheit und Datenarchitektur — erforderte eine strukturierte Antwort, die einer Beschaffungs-Prüfung standhielt. Wir produzierten das Compliance-Register, ein Vertiefungsblatt für die schwierigen Punkte und ein Quellen-Verifikations-Log."
quickRead: |
  **Wir haben in der Struktur gearbeitet, die das Beschaffungsteam vorgab — und die Struktur ergänzt, die es nicht vorgab.**

  Ein europäischer Tier-1-Energieversorger hatte eine fünfzigzeilige NFR-Matrix über die Domänen Cyber-Sicherheit, Datenarchitektur, technische Architektur und Business Continuity / DR ausgegeben — vorvertragliche Due Diligence für eine Software-Lieferantenbeziehung. Der Anbieter hatte ein funktionierendes Produkt und einen Azure-nativen Security-Stack. Was er brauchte, war eine Antwort, die eine kritische Beschaffungsprüfung Zeile für Zeile mit Evidenz übersteht — innerhalb eines festen Zeitfensters.

  Das Compliance-Register selbst lief mit einer Zeile pro Anforderung: Erfüllungsstatus (erfüllt / teilweise / nicht erfüllt / wünschenswert), Begründung, Quelle/Evidenzverweis, erforderliche Maßnahme, Kostenabschätzung, Zeitplan.

  Daneben fügten wir drei Artefakte hinzu, die der ursprüngliche Katalog nicht verlangte. Einen **Deep-Dive zu schwierigen Punkten** — sieben Zeilen, die mehr als eine Registerzeile brauchten, jede mit eigener Erzählseite. Ein **Quellen-Verifizierungs-Log**, das jede *Wir erfüllen X*-Aussage an ein konkretes Meeting, eine E-Mail oder ein Designdokument koppelt — und damit Compliance-Behauptungen in nachprüfbare Provenienz verwandelt. Eine **Kosten-Impact-Übersicht**, die die Kostenfolgen aller teilweise und nicht erfüllten Punkte konsolidiert und Nachverhandlungs-Trigger nach vorne holt statt mitten in die Beschaffung.

  Der Anbieter ging mit Compliance, Evidenz und Gap-Kosten im selben Artefakt in die Beschaffungsprüfung und erreichte den kommerziellen Abschluss ohne eine weitere NFR-Runde. Der Deep-Dive beantwortete im Voraus die Fragen, die eine kritische Beschaffungsprüfung gestellt hätte — und die Kosten-Impact-Übersicht legte **Nachverhandlungs-Trigger frei, bevor sie Nachverhandlung wurden.**
publishedAt: "2026-05-09"
featured: true
---

## Kontext

Ein Enterprise-Beschaffungsteam eines Tier-1-europäischen Energieanbieters hatte einen multi-domänen Non-Functional-Requirements-(NFR)-Katalog als Teil der Vor-Vertrag-Due-Diligence für eine Software-Anbieter-Beziehung herausgegeben. Der Katalog umfasste rund fünfzig Punkte über vier breite Domänen:

1. **Cyber-Sicherheit** — über alle Standard-Domänen hinweg: *Identität und Zugriff* (Authentifizierung, rollenbasierte Zugriffskontrolle, Multi-Faktor-Authentifizierung, Zugriffs-Reviews); *Datenschutz* (Datenklassifizierung, Verschlüsselung in Transit und im Ruhezustand, Schlüssel-Management, Data-Loss-Prevention, Backup-Sicherheit, DSGVO / Privacy); *Vulnerability- und Incident-Management* (Vulnerability-Management, Penetrationstests, Incident-Response, Patching, SIEM-Integration); *Netzwerk- und Anwendungssicherheit* (Netzwerksicherheit, Logging und Monitoring, sichere SDLC, Drittparteien-Risiko); *Business Continuity und Reporting* (Business Continuity, Compliance-Reporting); und *Mensch* (Sicherheits-Training).
2. **Datenarchitektur** — Governance, Qualität, ereignis-getriebene Architektur, Aufbewahrung, Lineage, Master-Data-Management, Microservice / lose Kopplung, API- und OpenAPI-Standards, duale Zugriffsmethoden.
3. **Technische Architektur / Anwendung** — Skalierbarkeit (horizontal und vertikal), Insel-Modus-Betrieb, Observability.
4. **Business Continuity / DR** — Recovery-Point- und Time-Objectives, Geo-Redundanz, Failover-Tests, Backup-Integrität.

Der Anbieter hatte eine anbieter-seitige Architektur, einen Azure-nativen Sicherheits-Stack und ein funktionierendes Produkt. Was er brauchte, war eine strukturierte Antwort, die einer Beschaffungs-Prüfung standhielt — Zeile für Zeile, mit Evidenz — innerhalb eines festen Fensters.

## Vorgehen

Wir arbeiteten in der Struktur, die das Beschaffungsteam vorgab, und ergänzten die Struktur, die es nicht vorgab.

Das Compliance-Register selbst lief mit einer Zeile pro Anforderung, mit Spalten für: Anforderungstext, Compliance-Status (einer von *compliant*, *partial*, *non-compliant*, *desirable*), Begründung, Quelle / Beweisreferenz, erforderliche Maßnahme, Kostenwirkungs-Schätzung und Zeitplan. Wo bestehende Produkt-Fähigkeit eine Anforderung abdeckte, verlinkte die Quellen-Spalte auf das Artefakt, das es nachwies. Wo Fähigkeit teilweise oder fehlend war, machten die Maßnahmen- und Kosten-Spalten die Lücke explizit und quantifiziert.

Um das Register herum ergänzten wir drei strukturelle Artefakte, die der ursprüngliche Katalog nicht angefordert hatte:

- **Eine "schwierige Punkte"-Vertiefung.** Rund sieben der Punkte erforderten mehr als eine Registerzeile — typischerweise weil sie über mehrere Domänen schnitten oder weil die Antwort von kunden-seitigen Entscheidungen abhing, die noch nicht getroffen waren. Jeder bekam eine eigene narrative Seite.
- **Ein Quellen-Verifikations-Log.** Rund dreißig Einträge, die spezifische Begründungen mit spezifischen Meetings, E-Mails oder Design-Dokumenten verknüpften. Dies wandelte *wir erfüllen X*-Behauptungen in auditierbare Provenienz um.
- **Eine Kostenwirkungs-Zusammenfassung.** Eine konsolidierte Sicht der Kostenimplikationen über alle partiellen und non-compliant Punkte, mit grobem Zeitplan. Beschaffungsteams entdecken diese Zahl typischerweise durch schmerzhafte Nachverhandlung; sie im Voraus offenzulegen verkürzte die Konversation.

Wir arbeiteten quer über den Standard-Azure-nativen Sicherheits-Stack — Entra ID, Key Vault, Defender, Purview, Sentinel, Event Hub, Log Analytics — die Methodik ist aber plattform-agnostisch. Das Artefakt hätte auf AWS- oder GCP-Äquivalenten gleich ausgesehen.

## Was wir lieferten

- Ein rund fünfzig-zeiliges Compliance-Register über Sicherheits-, Daten- und Architektur-Domänen
- Eine Vertiefungs-Narrative über die sieben Punkte, die mehr als eine Zeile erforderten
- Ein Dreißig-Einträge-Quellen-Verifikations-Log
- Eine Kostenwirkungs-Zusammenfassung mit grobem Zeitplan
- Explizite Identifikation von fünf offenen kunden-seitigen Klärungen, die die initiale Antwort nicht blockierten

## Ergebnis

Der Anbieter trat in die Beschaffungs-Prüfung mit einer strukturierten Antwort ein, die Compliance, Evidenz und Lücken-Kosten im selben Artefakt dokumentierte, und **ging in den kommerziellen Abschluss ohne eine zusätzliche NFR-Runde** — die Vertiefung der *schwierigen Punkte* beantwortete im Voraus die Fragen, die eine kritische Beschaffungs-Lesung gestellt hätte, und die Kostenwirkungs-Zusammenfassung legte Nachverhandlungs-Auslöser offen, bevor sie zu Nachverhandlung wurden.

Die fünf offenen kunden-seitigen Klärungen wurden an das Architektur-Team des Kunden als Teil der Antwort zurückgeleitet, was die nächste Frage-Runde verengte und ihren internen Review-Zyklus verkürzte.

## Was wir nicht lieferten

Einen Penetrationstest. Ein Sicherheits-Audit. ISO-27001-Dokumentation. Implementierung irgendwelcher partieller Compliance-Punkte. Die Lieferung war strukturierte Beratung, nicht Sicherheits-Arbeit.

## Mandatsform

Festpreisiges Mandat, Vor-Vertrag-Due-Diligence-Form, Single-Principal. Materialien produziert als strukturiertes Workbook im bevorzugten Dateiformat des Beschaffungsteams. Durchgehend vertraulich; keine öffentlichen Materialien produziert.
