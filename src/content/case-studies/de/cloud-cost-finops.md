---
title: "Cloud-Kostenanalyse für einen Multi-Installations-SaaS-Anbieter"
sector: "Industrieller Software-Anbieter"
engagementType: "40-Stunden festpreisige Beratung"
year: "2026"
region: "Nordeuropa"
summary: "Ein Anbieter, der ein Cloud-managed SaaS-Angebot für einen Tier-1-Enterprise-Kunden kalkulierte, benötigte ein belastbares Pro-Installations-Preismodell — ohne Zugang zur Hosting-Baseline des bestehenden Anbieters. Wir lieferten eine triangulierte Baseline, ein Mehrszenarien-Pricing-Playbook und einen kundenseitigen Kostenrechner."
publishedAt: "2026-05-09"
featured: true
---

## Kontext

Ein Multi-Installations-Anbieter industrieller Software bereitete ein Managed-SaaS-Angebot für einen Tier-1-Enterprise-Kunden vor. Das bestehende Deployment des Anbieters lief auf der Kunden-Infrastruktur über einen Managed-Services-Partner; die neue Vereinbarung würde die Verantwortung für Hosting und Betrieb auf den Anbieter selbst übertragen.

Die kommerzielle Frage war scheinbar einfach: *Was sollen wir pro Installation pro Monat berechnen?*

Die Komplikationen waren:

1. Die bestehende Hosting-Baseline war intransparent. Der Managed-Services-Partner des Kunden hatte sich geweigert, Rechnungen freizugeben, was die Frage *Was kostet das aktuell?* aus öffentlich verfügbaren Informationen nicht beantwortbar machte.
2. Das Workload-Sizing war unsicher. Die einzigen verfügbaren Performance-Daten stammten aus einer verkleinerten Testumgebung; die tatsächliche Produktions-Größe wurde erst mitten im Mandat bestätigt.
3. Der Deal trug erhebliche Nicht-Kosten-Überlegungen — regulatorische Compliance, Lieferketten-Risiko, SaaS-Enablement-Strategie — die neben der Kostenzahl stehen mussten, nicht dahinter.

Die Workload war telemetrie-intensiv. Größere Installationen ingestierten etwa **200.000 Zeilen pro Tag**, 24/7 von angeschlossenen Instrumenten über einen Node.js-Receiver erfasst; kleinere Installationen liefen mit rund 20.000 Zeilen/Tag. Der geplante Umfang waren zwölf Installationen über zwei Datenbank-Performance-Stufen, insgesamt **36 Server** über Produktion und Non-Produktion. Klein genug, dass per-Server-Fixkosten — bei Enterprise-Skala typischerweise vernachlässigbar — unverhältnismäßig wurden, was ein Grund dafür war, dass die Analyse sorgfältig statt benchmark-extrapoliert durchgeführt werden musste.

Der Anbieter benötigte ein vorstandsfähiges Dokument in etwa vier Wochen. Das interne Team war fähig, hatte aber keine Bandbreite, und die größere Beratungs-Alternative hätte eine mehrmonatige Discovery-Phase erfordert, die der Zeitplan nicht zuließ.

## Vorgehen

Wir verankerten die Analyse an Cloud-Ökonomie-, Observability- und DevOps-Literatur — Storment & Fuller, Majors, Nygard, Forsgren et al. — plus First-Party-Leitfäden von Azure / AWS / GCP zur Tier-Auswahl und DR-Kosten für die im Umfang stehenden Datenbank-Engines. Die Frameworks strukturierten eine Vier-Kategorien-Kostentaxonomie: fixer Overhead, Kompetenz, variabel, pro Server.

Innerhalb dieses Rahmens bauten wir:

- **Eine triangulierte Baseline.** Wo Rechnungen nicht verfügbar waren, konstruierten wir einen geschätzten aktuellen Spend aus verifizierten öffentlichen Cloud-Listenpreisen (gegen die Pricing-API des Cloud-Anbieters gegengeprüft) multipliziert mit dem typischen Partner-Margen-Band für die Deployment-Skala des Kunden.
- **Eine Szenario-Matrix.** Drei aktive Cloud-Pfade (Azure SQL Managed Instance, AWS RDS für SQL Server, GCP Cloud SQL — alle License-Included nach einer kundenseitigen Entscheidung, die Lizenz-Transfer-Pfade ausschloss), jeweils auf drei Bindungsstufen (PAYG, einjährig reserviert, dreijährig reserviert). Plus vier ausgeschlossene Szenarien, zur Vollständigkeit dokumentiert.
- **Ein Pricing-Playbook.** Was der Anbieter pro Installation pro Monat berechnen müsste, um verifizierte Cloud-Kosten plus eine Ziel-Marge zu decken, modelliert auf drei Margen-Niveaus und zwei Personal-Aufstellungen (dedizierte FTE versus absorbierte Operations).
- **Einen kundenseitigen Rechner.** Ein Tabellenblatt, das der Kunde mit seinen tatsächlichen bestehenden Kosten füllen konnte, um zu testen, ob das Angebot des Anbieters bei jeder gegebenen Marge wettbewerbsfähig war.
- **Ein NFR-Compliance-Scoreboard.** Bildete die vorgeschlagene Architektur auf den bestehenden Non-Functional-Requirements-Katalog des Kunden ab, mit expliziter Aufschiebung von fünf offenen Klärungen, die die kommerzielle Phase-1-Entscheidung nicht blockierten.

Wir identifizierten zusätzlich einen kostenfreien SQL-Konfigurations-Fix in der Testumgebung (eine parallelitäts-bezogene Einstellung, die einen scheinbaren Bedarf nach Tier-Upgrade trieb) — ein Befund, der potenziell die gesamte Sizing-Konversation umrahmte und als Priorität-1-Aktionspunkt markiert wurde.

## Was wir lieferten

- Einen etwa vierzig-seitigen strategischen Kostenanalyse-Bericht
- Ein separates sechsundzwanzig-Blatt Kostenmodell-Spreadsheet, einschließlich des Live-Kundenrechners
- Eine Migrations- und Wiederherstellungs-Zusammenfassung auf strategischer Ebene
- Ein NFR-Compliance-Scoreboard
- Explizite Out-of-Scope-Erklärungen für Implementierung, Runbooks, IaC, tiefe Code-Analyse, Sicherheits-Audits und Proof-of-Concept-Arbeit

## Ergebnis

Der Anbieter ging in das nächste Kunden-Meeting mit einem belastbaren Pro-Installations-Preismodell, das an verifizierbaren öffentlichen Preisen verankert war, einer sauberen Trennung zwischen kommerziellem Preis und Infrastruktur-Kosten und einem Rechner, den der Kunde selbst ausführen konnte. Die Frage *Gibt es überhaupt eine Marge?* — die zuvor unbeantwortbar gewesen war — wurde als SaaS-Premium-Konversation umrahmt, gestützt durch eine quantifizierte Baseline.

Der während des Mandats identifizierte Konfigurations-Befund ist für sich allein in der Lage, die Tier-Auswahl-Konversation vollständig zu verändern.

## Was wir nicht lieferten

Implementierung. Terraform / IaC. Tiefe Code-Analyse. Sicherheits-Audit. Migrations-Ausführungsplan. Proof-of-Concept. Diese wurden bei Mandatsdefinition als Out-of-Scope erklärt und blieben es. Die Lieferung war Entscheidungs-Unterstützung, nicht Umsetzung.

## Mandatsform

Vierzig-Stunden festpreisiges Beratungsmandat über etwa vier Wochen, mit drei Arbeits-Sessions plus asynchroner Lieferung. Single-Principal-Mandat (kein Lieferteam). Materialien über das Kollaborationssystem des Kunden geteilt; Lieferobjekte beim Kunden verbleibend.
