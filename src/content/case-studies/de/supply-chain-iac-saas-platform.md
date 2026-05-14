---
title: "Software-Lieferketten-Kontrollen und Plattform-IaC-Rettung für einen Multi-Tenant-SaaS-Anbieter"
sector: "Multi-Tenant-SaaS-Anbieter"
engagementType: "Angewandte Plattform-Engineering-Arbeit · anonymisierte interne Referenz"
year: "2024"
region: "Europäische Union"
summary: "Rekonstruktion eines fünf Jahre alten Ansible/Semaphore IaC-Stacks end-to-end über vier Repositories — Orchestrierungs-Playbooks, produktiver nginx-Reverse-Proxy, PostgreSQL-Container, Analytics-Stack-Feature-Branch. Entwurf und Auslieferung einer gegateten Software-Lieferketten-Schicht (Composer/Satis, npm/Verdaccio, SQL/Redgate, Container/GitLab Registry) mit Pro-Paket statischer Analyse, Vulnerability-Scanning und Genehmigung, bevor ein Entwickler eine Drittpartei-Abhängigkeit überhaupt auflösen kann. Etwa 30% des Mandats; umgesetzt 2024, zwei Jahre vor CRA-Cliff-2 (11. Dezember 2027), wo SBOM und Lieferketten-Integrität zur EU-weiten regulatorischen Pflicht werden."
quickRead: |
  Ein Multi-Tenant-SaaS-Betreiber auf Hetzner Cloud benötigte drei Dinge auf einmal: einen **fünf Jahre alten Ansible/Semaphore IaC-Stack end-to-end wiederbelebt** (die ursprünglichen Ingenieure waren weitergezogen, die Plattform lief nicht mehr sauber), eine **interne Software-Lieferketten-Schicht** (PHP vom öffentlichen Packagist, JavaScript vom öffentlichen npm, SQL-Artefakte von Ad-hoc-Entwickler-Maschinen — kein interner Vertrauensanker, kein Vor-Integrations-Evaluations-Gate), und einen **Analytics-Stack** (Metabase + Grafana auf eigenen VMs, in dieselbe PKI wie der Rest der Plattform verkabelt).

  Über **vier miteinander verbundene Repositories und ~178 Commits** rekonstruierte das Mandat das Orchestrierungs- / IaC-Repository (~85 Commits — Semaphore-API-Integration, SSH-Key-Hygiene, docker-login-Flow, Zertifikat-Lifecycle), brachte den **produktiven nginx-Reverse-Proxy** wieder zum Laufen (~67 Commits, produktions-getaggt über mehrere veröffentlichte Versionen — WebSocket-Unterstützung für Grafana, Pro-Service-Auth-Routing, Custom-Error-Pages), arbeitete am **PostgreSQL-Container-Base-Image** (~20 Commits — Postgres-Logs, die Container-Grenzen zuverlässig überschreiten), und lieferte den **Analytics-Stack-Feature-Branch** (~6 Commits), der Metabase und Grafana in denselben Ansible/Semaphore-Provisionierungs-Pfad brachte.

  Das unterscheidende Element — etwa 30% des Mandats — war das **vier-stufige Vor-Integrations-Gate** für jeden Artefakt-Kanal: Entwickler fragt ein Paket an → statische Analyse (Composition-Scan, Lizenz-Inventar, Code-Level-Signal) → Vulnerability-Scan gegen CVE / GHSA / OSV → Genehmigung und Spiegelung in die interne Registry (**Satis für Composer**, **Verdaccio für npm**, **Redgate SQL Source Control** für Schema-Änderungen, **GitLab Container Registry** für Images). Es gibt keinen Resolver-Pfad, der die interne Registry umgeht.

  Das Muster bildet sich direkt auf **EN/IEC 62304 § 5.1.5 + § 8.1 (SOUP-Identifikation + Anomaly-Review), MDCG 2019-16, IEC 81001-5-1, NIS2 Artikel 21(2)(d) und CRA Artikel 13 + Anhang I Teil II(1)/(2)** ab — die Lieferketten-Kontrollen, die die Regulierung nun von Herstellern verlangt. Umgesetzt 2024, zwei Jahre bevor CRA Cliff 2 (Dezember 2027) sie zu vollen Pflichten macht.
publishedAt: "2026-05-13"
featured: true
---

> **Hinweis zum Rahmen.** Diese Seite beschreibt Ausführungsarbeit, die an einen Multi-Tenant-SaaS-Betreiber geliefert wurde, anonymisiert und als Methodik-Referenz veröffentlicht. Keine Kunden-Identifikation, keine Tenant-Namen, nur Sektor-Deskriptor. Die Arbeit datiert vor die aktuelle festpreisige Beratungs-Form von Thinking Machine und ist auf der Fallstudien-Seite enthalten, weil sie drei der heutigen Spuren informiert: Cyber-Resilienz (Lieferkette), KI-Integration (das zugrunde liegende IaC-Muster) und die operative Realität von NIS2 / CRA-Evidenz-Paketen.

## Kontext

Der Betreiber betrieb eine Multi-Tenant-SaaS-Plattform auf Hetzner Cloud, organisiert um eine Master/Tenant-Architektur: eine zentrale Semaphore-UI, die Ansible-Playbooks gegen on-demand Entwickler- und Kunden-VMs orchestriert. Die Plattform war fünf bis sechs Jahre zuvor von Ingenieuren gebaut worden, die seither weitergezogen waren. Die IaC war strukturell solide, lief aber nicht mehr end-to-end. Die Dokumentation hinkte dem Code hinterher, die Semaphore-API-Automatisierung war aus der Synchronität mit der laufenden Version gedriftet, und mehrere Steuerebene-Komponenten (BIND9-Zonen-Dateien, OpenVPN-Client-Provisionierung, docker-login gegen die GitLab Container Registry) waren stillschweigend degradiert.

Darüber gelegt benötigte der Betreiber drei Erweiterungen:

1. **Eine Software-Lieferketten-Schicht.** Die Plattform konsumierte PHP-Pakete vom öffentlichen Packagist, JavaScript-Pakete vom öffentlichen npm und SQL-Artefakte von Ad-hoc-Entwickler-Maschinen. Es gab keinen internen Vertrauensanker und kein Vor-Integrations-Evaluations-Gate. Container-Images kamen bereits aus der GitLab Container Registry, aber der Credential-Flow war fragil.
2. **Einen Analytics-Stack.** Metabase für Tenant-Daten-BI; Grafana für operative Metriken. Jeder auf seiner eigenen Hetzner-VM, in dieselbe DNS-Zone und PKI wie der Rest der Plattform verkabelt.
3. **Resilienz-Verbesserungen bei der Provisionierung.** Idempotente Nutzer-Erstellung, kein SSH-Key-Sprawl über Kunden-VMs und ein funktionierender docker-login-Pfad für die Container Registry.

Das Team hatte keinen dedizierten Plattform-Ingenieur. Die Arbeit musste landen, bevor Kunden-Expansion Last auf die bestehenden Flows brachte.

## Vorgehen

Der Startzug war, den bestehenden Stack aus Kalt-Lektüre des geerbten Codes wieder end-to-end zum Laufen zu bringen. Kein Greenfield-Rebuild — die strukturell soliden Teile waren bergbar, die Kosten eines Komplett-Rewrites unwirtschaftlich. Arbeitswissen wurde rekonstruiert aus dem bestehenden Ansible-Orchestrierungs-Repository, der Inventar-Struktur (`group_vars`, `host_vars`, `playbooks`, `tasks`, `roles`, `templates`), den Semaphore-Template-Definitionen und dem docker-login-Flow gegen die GitLab Container Registry, und jeder Pfad anschließend mit echten Provisionierungs-Läufen gegen Hetzner geübt.

Das Mandat umspannte **vier miteinander verbundene Repositories**, mit rund einhundertachtundsiebzig Commits darüber als sichtbarer Trace:

- **Orchestrierungs- / IaC-Repository** (~85 Commits) — Ansible-Playbooks, Semaphore-Projekt-Konfiguration, die Per-Tenant-VM-Provisionierungs-Kette. Sichtbar im Trace als kleine, inkrementelle, Debugging-Grad-Messages — die Signatur iterativer Arbeit gegen eine wackelige externe API und eine Multi-VM-Provisionierungs-Kette. Cluster: Semaphore-API-Integration (JSON-Array-vs-Objekt-Mismatches, idempotente Nutzer-Erstellung, 400-on-create-user-Debugging), SSH-Key-Hygiene (Entwickler-Keys wurden stillschweigend auf jede provisionierte VM propagiert — Fix entfernt diesen Pfad und dokumentiert, warum die Änderung strukturell und nicht kosmetisch ist), docker-login gegen die GitLab Container Registry (zwei separate Login-Flows wurden konfundiert — Fix trennt sie und exponiert Credentials über ein Makefile-Target mit verifizierbarem Login-Schritt vor jedem Image-Pull), Zertifikat-Lifecycle (Wildcard-Zertifikat für die interne TLD, Pro-VM-Entwicklungs-Zertifikate, interne CA-Vertrauenskette).
- **Produktives nginx-Reverse-Proxy-Repository** (~67 Commits) — der TLS-terminierende Edge vor den internen Analytics-Tools (Grafana, Metabase, Redash). Die Arbeit konzentrierte sich auf WebSocket-Unterstützung für Grafana-Echtzeit-Dashboards, Pro-Service-Auth-Routing (manche Services benötigen keine Auth im internen Netzwerk), Custom-Error-Pages, Redirect-Loop-Fixes und PWA-Routing-Grenzfälle. **Über mehrere veröffentlichte Versionen produktions-getaggt**, sodass die Änderungen auf einem echten kunden-zugewandten Perimeter statt in einer Sandbox deployed wurden.
- **PostgreSQL-Container-Repository** (~20 Commits) — Base-Image-Arbeit am Datenbank-Container. Das wiederkehrende Thema war, Postgres-Logs zuverlässig über Container-Grenzen kommen zu lassen — Log-Datei-Ownership über Nutzer und Gruppen, `postgresql.conf`-Provisionierung beim Container-Build, Log-Dateien, die für Geschwister-Container lesbar sein müssen, und die kleine, aber reale DBA-seitige Toolchain.
- **Analytics-Stack-Feature-Branch** (~6 Commits) — eine Arbeitskopie, die verwendet wurde, um die Metabase/Grafana-VPS-Provisionierung zu entwickeln, bevor sie ins Haupt-Orchestrierungs-Repo gemerged wurde. Die Commits dokumentieren das Integrations-Debugging — Metabase über die interne Firewall mit einem GitLab-gehosteten Postgres zu verbinden —, das nicht im öffentlichen Commit-Log des finalen gemergten Playbooks auftaucht.

## Software-Lieferketten-Schicht

Etwa 30% des Mandats konzentrierte sich hier. Das Ziel war operativ einfach und regulatorisch konsequenzreich: **kein Drittpartei-Paket erreicht einen Tenant-Build ohne dokumentierte Vor-Integrations-Evaluation** gegen die Cybersecurity-Kontrollen, die inzwischen über EU-Medizinprodukte-Software, NIS2-Lieferkette und CRA-Herstellerpflichten kodifiziert sind.

Die Architektur ist ein Workflow, nicht nur eine statische Liste von Registries. Jeder Artefakt-Kanal, den die Plattform konsumierte — PHP-Pakete via Composer, JavaScript-Pakete via npm, SQL-Schema-Änderungen, Container-Images — passierte dasselbe vierstufige Gate, bevor ein Entwickler es auflösen konnte:

1. **Anfrage.** Ein Entwickler fragt ein neues Drittpartei-Paket an, mit Name, angefragter Version und der vorgesehenen Verwendung innerhalb des Tenant-Builds.
2. **Statische Analyse.** Das Kandidaten-Paket wird in einen isolierten Runner gezogen. Composition-Scanning enumeriert transitive Abhängigkeiten und Lizenz-Inventar. Das Lizenz-Inventar wird gegen die erlaubte Lizenz-Liste des Betreibers abgeglichen. Code-Level-Signale werden auf die offensichtlich unsicheren Muster geprüft (`eval`, dynamische Ausführung, Shell-out, Build-Zeit-Post-Install-Hooks, die das Netz erreichen).
3. **Vulnerability-Analyse.** Das Kandidaten-Paket und jede transitive Abhängigkeit werden in CVE-/GHSA-/OSV-Datenbanken in der angefragten Version nachgeschlagen. Pakete mit bekannten unpatched-und-ausnutzbaren Vulnerabilities werden direkt abgelehnt; Pakete mit gepatchten Vulnerabilities in einer höheren Version werden in der gepatchten Version genehmigt, nicht in der angefragten, mit angepasster `composer.json` oder `package.json`.
4. **Genehmigung und Spiegelung.** Wenn das Paket beide Gates passiert, wird es in die interne Registry gespiegelt — **Satis für Composer**, **Verdaccio für npm** — in der genehmigten Version, mit dem Evaluations-Datensatz neben dem Binary aufbewahrt. Erst dann kann ein `composer require` oder `npm install` des Entwicklers das Paket auflösen. Es gibt keinen Resolver-Pfad, der die interne Registry umgeht.

Dieselbe Form galt für **SQL-Schema-Artefakte** über Redgate SQL Compare und Source Control — jede Schema-Änderung wird zu einem reviewbaren Diff mit benanntem Genehmiger, bevor sie eine Tenant-Datenbank erreichen kann — und für **Container-Images** über die GitLab Container Registry als einzige autorisierte Image-Quelle für Tenant-VMs, mit dem docker-login-Flow als verifizierbarer Login-Schritt vor jedem Image-Pull im Ansible-Playbook.

Das Muster bildet sich direkt auf die regulatorische Landschaft ab, die anschließend kodifizierte, was bereits ausgeliefert war:

- **EN / IEC 62304 § 5.1.5 und § 8.1** — SOUP (Software of Unknown Provenance)-Identifikation und Anomaly-Review. Jedes Drittpartei-Element trägt seinen Inventar-Datensatz, beabsichtigte Verwendung und Known-Vulnerability-Review in der tatsächlich konsumierten Version.
- **MDCG 2019-16** — die EU-MDR-Cybersecurity-Leitlinien-Anforderung, eine "gründliche Evaluation von Drittpartei-Komponenten" *vor Integration* durchzuführen, ist operativ durch das Statische-Analyse-dann-Vuln-Scan-Gate erfüllt, nicht durch eine Nachträgliche-Attestierung.
- **IEC 81001-5-1** — Sicherheitsaktivitäten für Gesundheits-Software im Produkt-Lebenszyklus. Die Interne-Registry-als-einzige-Quelle-der-Wahrheit macht die SBOM- und Lieferanten-Evaluations-Anforderungen zu einem Nebenprodukt des Betriebs statt zu einem separat gepflegten Artefakt.
- **NIS2 Artikel 21(2)(d)** — Lieferketten-Sicherheit für wesentliche und wichtige Einrichtungen (der Gesundheitssektor ist in NIS2 Annex I). Das Gate IST die Lieferketten-Kontrolle: ein typosquatted Packagist-Paket kann keinen Tenant-Build erreichen, weil kein Resolver-Pfad die interne Registry umgeht.
- **CRA Artikel 13 und Anhang I Teil II(1) und (2)** — Hersteller-Pflichten, Komponenten zu identifizieren, eine SBOM zu produzieren und Vulnerabilities effektiv zu behandeln. Cliff 2 (11. Dezember 2027) macht diese zu vollen EU-weiten Pflichten. Die Registry produziert die SBOM als Nebenprodukt; das Evaluations-Log ist die Vulnerability-Handling-Evidenz.

Umgesetzt 2024 — zwei Jahre vor den frühen CRA-Reporting-Pflichten (Cliff 1, September 2026) und drei Jahre vor dem vollen SBOM- und Komponenten-Identifikations-Mandat (Cliff 2, Dezember 2027).

## Analytics-Stack

Zwei weitere Hetzner-VMs wurden hinzugefügt — eine für Metabase, eine für Grafana — jede provisioniert durch denselben Ansible/Semaphore-Pfad, der für die Entwickler- und Kunden-VMs verwendet wird. Die Metabase-VM hostet das BI-Tool mit eigenem PostgreSQL-Metadaten-Store und einem Java Keystore für TLS-Terminierung. Die Grafana-VM verwendet dieselbe interne CA, persistiert Zustand unter `/grafana` und läuft das `grafana/grafana-oss`-Image in Docker hinter derselben DNS-Zonen-Namens-Konvention wie der Rest der Plattform. Beide Knoten sind nur innerhalb des OpenVPN-Overlays erreichbar; keiner ist im öffentlichen Internet exponiert. Der TLS-terminierende Reverse-Proxy davor ist das produktive nginx-Repository oben — WebSocket-Unterstützung für Grafana-Echtzeit, Pro-Service-Auth-Routing, Custom-4xx/5xx-Seiten.

## Ergebnis

Die Plattform-IaC läuft wieder end-to-end, mit den beweglichen Teilen dokumentiert (Architektur, Playbooks, Rollen, Workflows) auf einem Niveau, das das nächste Ingenieur-Rotations-Ereignis überlebt. Die Lieferketten-Schicht bedeutet, dass die Antwort auf *Können Sie beschreiben, wie ein typosquatted öffentliches Paket Produktion erreichen würde* lautet: "Es kann nicht, weil der Resolver-Pfad durch eine interne Registry vermittelt wird und jedes Kandidaten-Paket durch statische Analyse, Vulnerability-Scanning und eine dokumentierte Genehmigung gegangen ist, bevor es bedient werden kann." Der Analytics-Stack läuft neben dem Rest der Plattform, ohne die öffentliche Angriffsfläche zu erweitern. Der produktive Reverse-Proxy ist über mehrere Versionen getaggt-und-released, was auf NIS2 § 21(2) "sichere Entwicklung"-Erwartungen abbildet.

In der Sprache von CRA-Cliff-1 (11. September 2026) und CRA-Cliff-2 (11. Dezember 2027) produzierte dieser Korpus — zwei bis drei Jahre früher — genau die Art von Lieferketten-Integritäts-Evidenz-Paket, das die Verordnung nun von Herstellern verlangt, einem Regulierer oder einer Benannten Stelle auf Anfrage präsentieren zu können.

## Was die Arbeit nicht produzierte

Eine formale SBOM-Pipeline, die SPDX / CycloneDX emittiert (das SBOM-Format-Mandat datiert nach der Arbeit; die interne Registry war die Wahrheits-Quelle für das Komponenten-Inventar, das Export-Format aber betreiber-intern). Einen Drittparteien-Penetrationstest gegen die Registries. Eine Tenant-Daten-Schutz-Bewertung. Eine ISO/IEC-27001 Statement of Applicability. Die Arbeit war operative Verbesserung, nicht Compliance-Attestierung — aber die operativen Verbesserungen sind das Substrat, auf dem Compliance-Attestierung ruht.

## Form der Arbeit

Sole-Principal-Mandat über mehrere Monate, die Arbeit führend in Koordination mit dem kleinen Inhouse-Team des Betreibers. **Etwa 178 Commits über vier Repositories** als sichtbarer Trace: die Orchestrierungs-IaC, der produktive nginx-Reverse-Proxy, das PostgreSQL-Container-Base-Image und der Analytics-Stack-Feature-Branch. Plus das vierstufige Lieferketten-Gate und die Analytics-Stack-Provisionierung. Durchgehend vertraulich; diese Seite ist die einzige anonymisierte Referenz.
