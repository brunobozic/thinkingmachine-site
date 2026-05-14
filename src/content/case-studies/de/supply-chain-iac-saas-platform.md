---
title: "Software-Lieferketten-Kontrollen und Plattform-IaC-Rettung für einen Multi-Tenant-SaaS-Anbieter"
sector: "Multi-Tenant-SaaS-Anbieter"
engagementType: "Angewandte Plattform-Engineering-Arbeit · anonymisierte interne Referenz"
year: "2024"
region: "Europäische Union"
summary: "Wiederbelebung eines fünf Jahre alten Ansible/Semaphore IaC-Stacks end-to-end aus Rekonstruktion über vier Repositories — Orchestrierungs-Playbooks, produktiver nginx-Reverse-Proxy, PostgreSQL-Container-Base-Image, Analytics-Stack-Feature-Branch. Hinzufügung einer internen-Vertrauensanker Software-Lieferketten-Schicht (Composer/Satis, npm/Verdaccio, SQL/Redgate, Container/GitLab Registry) und eines Analytics-Stacks (Metabase + Grafana). Etwa 30% des Mandats war Software-Lieferketten-Management — direkt relevant für CRA Artikel 13 SBOM/Integritäts-Pflichten und NIS2 Artikel 21(2) Lieferketten-Kaskade."
publishedAt: "2026-05-13"
featured: true
---

> **Hinweis zum Rahmen.** Diese Seite beschreibt Ausführungsarbeit, die an einen Multi-Tenant-SaaS-Betreiber geliefert wurde, anonymisiert und als Methodik-Referenz veröffentlicht. Keine Kunden-Identifikation, keine Tenant-Namen, nur Sektor-Deskriptor. Die Arbeit datiert vor die aktuelle festpreisige Beratungs-Form von Thinking Machine und ist auf der Fallstudien-Seite enthalten, weil sie drei der heutigen Spuren informiert: Cyber-Resilienz (Lieferkette), KI-Integration (das zugrunde liegende IaC-Muster) und die operative Realität von NIS2 / CRA-Evidenz-Paketen.

## Kontext

Der Betreiber betrieb eine Multi-Tenant-SaaS-Plattform auf Hetzner Cloud, organisiert um eine Master/Tenant-Architektur: eine zentrale Semaphore-UI, die Ansible-Playbooks gegen on-demand Entwickler- und Kunden-VMs orchestriert. Die Plattform war fünf bis sechs Jahre zuvor von Ingenieuren gebaut worden, die seither weitergezogen waren. Die IaC war strukturell solide, lief aber nicht mehr end-to-end. Die Dokumentation hinkte dem Code hinterher, die Semaphore-API-Automatisierung war aus der Synchronität mit der laufenden Version gedriftet, und mehrere Steuerebene-Komponenten (BIND9-Zonen-Dateien, OpenVPN-Client-Provisionierung, docker-login gegen die GitLab Container Registry) waren stillschweigend degradiert.

Darüber gelegt benötigte der Betreiber drei Erweiterungen:

1. **Eine Software-Lieferketten-Schicht.** Die Plattform konsumierte PHP-Pakete vom öffentlichen Packagist, JavaScript-Pakete vom öffentlichen npm und SQL-Artefakte von Ad-hoc-Entwickler-Maschinen. Es gab keinen internen Vertrauensanker. Container-Images kamen bereits aus der GitLab Container Registry, aber der Credential-Flow war fragil.
2. **Einen Analytics-Stack.** Metabase für Tenant-Daten-BI; Grafana für operative Metriken. Jeder auf seiner eigenen Hetzner-VM, in dieselbe DNS-Zone und PKI wie der Rest der Plattform verkabelt.
3. **Resilienz-Verbesserungen bei der Provisionierung.** Idempotente Nutzer-Erstellung, kein SSH-Key-Sprawl über Kunden-VMs und ein funktionierender docker-login-Pfad für die Container Registry.

Das Team hatte keinen dedizierten Plattform-Ingenieur. Die Arbeit musste landen, bevor Kunden-Expansion Last auf die bestehenden Flows brachte.

## Vorgehen

Der Startzug war, den bestehenden Stack aus Rekonstruktion wieder end-to-end zum Laufen zu bringen. Kein Greenfield-Rebuild. Lesen des bestehenden Ansible-Codes im Orchestrierungs-Repository, der Inventar-Struktur (`group_vars`, `host_vars`, `playbooks`, `tasks`, `roles`, `templates`), der Semaphore-Template-Definitionen und des docker-login-Flows gegen die GitLab Container Registry, und dann jeden Pfad mit echten Provisionierungs-Läufen gegen Hetzner üben.

Das Mandat umspannte **vier miteinander verbundene Repositories**, mit rund einhundertachtundsiebzig Commits darüber als sichtbarer Trace:

- **Orchestrierungs- / IaC-Repository** (~85 Commits) — Ansible-Playbooks, Semaphore-Projekt-Konfiguration, die per-Tenant VM-Provisionierungs-Kette. Sichtbar im Trace als kleine, inkrementelle, Debugging-Grad-Messages — die typische Signatur des Arbeitens gegen eine wackelige externe API und eine Multi-VM-Provisionierungs-Kette. Cluster: Semaphore-API-Integration (JSON-Array-vs-Objekt-Mismatches, idempotente Nutzer-Erstellung, 400-on-create-user-Debugging), SSH-Key-Hygiene (Entwickler-Keys wurden stillschweigend auf jede provisionierte VM propagiert — Fix entfernt diesen Pfad und dokumentiert, warum die Änderung strukturell ist), docker-login gegen die GitLab Container Registry (zwei separate Login-Flows wurden konfundiert — Fix trennt sie und exponiert Credentials über ein Makefile-Target mit verifizierbarem Login-Schritt), Zertifikat-Lifecycle (Wildcard-Zertifikat für die interne TLD, Pro-VM-Entwicklungs-Zertifikate, interne CA-Vertrauenskette).
- **Produktives nginx-Reverse-Proxy-Repository** (~67 Commits) — der TLS-terminierende Edge vor den internen Analytics-Tools (Grafana, Metabase, Redash). Die Arbeit konzentrierte sich auf WebSocket-Unterstützung für Grafana-Echtzeit-Dashboards, Pro-Service-Auth-Routing (manche Services benötigen keine Auth im internen Netzwerk), Custom-Error-Pages, Redirect-Loop-Fixes und PWA-Routing-Grenzfälle. Über mehrere veröffentlichte Versionen produktions-getaggt, sodass die Änderungen auf einem echten kunden-zugewandten Perimeter statt in einer Sandbox deployed wurden.
- **PostgreSQL-Container-Repository** (~20 Commits) — Base-Image-Arbeit am Datenbank-Container. Das wiederkehrende Thema war, Postgres-Logs zuverlässig über Container-Grenzen kommen zu lassen — Log-Datei-Ownership über Nutzer und Gruppen, `postgresql.conf`-Provisionierung beim Container-Build, Log-Dateien, die für Geschwister-Container lesbar sein müssen, und die kleine aber reale DBA-seitige Toolchain (z. B. `nano` zum Base-Image hinzufügen, um In-Container-Debugging praktikabel zu machen).
- **Analytics-Stack-Feature-Branch** (~6 Commits) — eine Arbeitskopie, die verwendet wurde, um die Metabase/Grafana-VPS-Provisionierung zu entwickeln, bevor sie ins Haupt-Orchestrierungs-Repo gemerged wurde. Die Commits dokumentieren den typischen Schmerz, Metabase über die interne Firewall mit einem GitLab-gehosteten Postgres zu verbinden (ICMP-Restriktionen, Netzwerk-Namespacing) — die Art von Integrations-Debugging, die nicht im öffentlichen Commit-Log des finalen gemergten Playbooks auftaucht.

## Software-Lieferketten-Schicht

Etwa 30% des Mandats konzentrierte sich hier. Das Muster ist einfach zu beschreiben und operativ konsequenzreich: jeder Artefakt-Kanal, den die Plattform konsumierte, wurde hinter einem internen Vertrauensanker eingewickelt.

- **Composer / PHP-Pakete → Satis.** Privater Repository-Service für Composer. Interne Pakete und genehmigte Drittparteien-Spiegel werden aus Satis bedient; die `composer.json` der Plattform proxiet darüber statt direkt das öffentliche Packagist zu erreichen. Effekt: ein typosquatted Packagist-Paket kann nicht versehentlich in einen Tenant-Build landen.
- **npm / JavaScript-Pakete → Verdaccio.** Gleiche Form auf der JavaScript-Seite. Front-End-Builds resolven über Verdaccio; öffentlicher-npm-Reichweite wird vermittelt statt direkt. Effekt: ein kompromittierter öffentlich-npm-Tarball kommt nicht ohne explizite Allow-List-Änderung in den Tenant-Build-Pfad.
- **SQL-Artefakte → Redgate SQL Source Control.** SQL Compare und Source Control bringen Schema-Änderungen unter Versionskontroll-Review, genauso wie Anwendungscode bereits war. Effekt: Datenbank-Änderungen werden zu reviewbaren Diffs mit einem benannten Genehmiger, nicht Ad-hoc-DBA-Aktionen.
- **Container-Images → GitLab Container Registry.** Bereits vorhanden; das Mandat machte den Credential-Flow zuverlässig und den Login-Schritt verifizierbar.

Jede Schicht ist mit dem Zertifikat-Lifecycle gepaart, sodass die Registries selbst gegen dieselbe interne CA authentifizieren, die vom Rest der Plattform verwendet wird.

## Analytics-Stack

Zwei weitere Hetzner-VMs wurden hinzugefügt — eine für Metabase, eine für Grafana — jede provisioniert durch denselben Ansible/Semaphore-Pfad, der für die Entwickler- und Kunden-VMs verwendet wird. Die Metabase-VM hostet das BI-Tool mit eigenem PostgreSQL-Metadaten-Store und einem Java Keystore für TLS-Terminierung. Die Grafana-VM verwendet dieselbe interne CA, persistiert Zustand unter `/grafana` und läuft das `grafana/grafana-oss`-Image in Docker hinter derselben DNS-Zonen-Namens-Konvention wie der Rest der Plattform. Beide Knoten sind nur innerhalb des OpenVPN-Overlays erreichbar; keiner ist im öffentlichen Internet exponiert. Der TLS-terminierende Reverse-Proxy davor ist das produktive nginx-Repository oben — WebSocket-Unterstützung für Grafana-Echtzeit, Pro-Service-Auth-Routing, Custom-4xx/5xx-Seiten.

## Ergebnis

Die Plattform-IaC läuft wieder end-to-end, mit den beweglichen Teilen dokumentiert (Architektur, Playbooks, Rollen, Workflows) auf einem Niveau, das das nächste Ingenieur-Rotations-Ereignis überlebt. Die Lieferketten-Schicht bedeutet, dass die Antwort auf *Können Sie beschreiben, wie ein typosquatted öffentliches Paket Produktion erreichen würde* lautet: "Es kann nicht, weil die Artefakt-Kanäle durch interne Registries vermittelt werden." Der Analytics-Stack läuft neben dem Rest der Plattform, ohne die öffentliche Angriffsfläche zu erweitern. Der produktive Reverse-Proxy ist getaggt-und-released, sodass Änderungen durch eine Disziplin fließen, die auf NIS2 § 21(2) "sichere Entwicklung"-Erwartungen abbildet.

In der Sprache von CRA-Cliff-1 (11. September 2026) und NIS2 Artikel 21(2) produzierte dieser Korpus — zwei Jahre früher — genau die Art von Lieferketten-Integritäts-Evidenz, die diese Verordnungen nun von Betreibern verlangen, einem Regulierer oder einer Benannten Stelle auf Anfrage präsentieren zu können.

## Was die Arbeit nicht produzierte

Wir betrieben keine formale SBOM-Pipeline (das SBOM-Mandat datiert nach der Arbeit). Wir führten keinen Drittparteien-Penetrationstest gegen die Registries durch. Wir produzierten keine Tenant-Daten-Schutz-Bewertung. Wir produzierten keine ISO/IEC-27001 Statement of Applicability. Die Arbeit war operative Verbesserung, nicht Compliance-Attestierung — aber die operativen Verbesserungen sind das Substrat, auf dem Compliance-Attestierung ruht.

## Form der Arbeit

Single-Engineer-intensiv über mehrere Monate, im Zusammenspiel mit dem kleinen Inhouse-Team des Betreibers. Etwa **178 Commits über vier Repositories** als sichtbarer Trace: die Orchestrierungs-IaC, der produktive nginx-Reverse-Proxy, das PostgreSQL-Container-Base-Image und der Analytics-Stack-Feature-Branch. Plus die Lieferketten-Registry-Komponenten und die Analytics-Stack-Provisionierung. Durchgehend vertraulich; diese Seite ist die einzige anonymisierte Referenz.
