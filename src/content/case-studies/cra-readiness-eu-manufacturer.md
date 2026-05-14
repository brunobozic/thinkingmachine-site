---
title: "Cyber Resilience Act readiness for an EU manufacturer of connected products"
sector: "EU manufacturer of connected products"
engagementType: "Applied preparedness work · anonymised internal reference"
year: "2026"
region: "European Union"
summary: "Applied preparedness work on CRA Cliff 1 (September 2026) for an EU manufacturer-operator of connected products. Roughly 240 pages of audit-defensible evidence across 13 documents — checklists, briefings, the Article 14 runbook, the RACI, the execution plan — anchored on five-pass verbatim verification of the Official Journal. Published as a methodology reference; client unidentified."
publishedAt: "2026-05-09"
featured: true
---

> **Note on framing.** This page describes a body of internal preparedness work, anonymised and published as a methodology reference. It is not a paid external engagement. Same anonymisation rules apply: no client identification, no quoted text, sector descriptor only.

## Context

The EU Cyber Resilience Act (Regulation 2024/2847) imposes obligations on every economic operator placing products with digital elements on the EU market. The cliff dates above set the operational deadlines; the official implementation timeline and standardisation requests are tracked on the [European Commission's CRA Implementation page](https://digital-strategy.ec.europa.eu/en/factpages/cyber-resilience-act-implementation). What makes this engagement non-trivial is the regulatory geometry of the organisation underneath those dates.

The organisation in this body of work carried a hybrid regulatory posture: **manufacturer** in CRA terms for its own software stack (edge runtime, container images, cloud back-office, mobile app), **operator/distributor** for the vendor hardware it integrates. Layered on top: the German national NIS2 transposition (BSIG-neu, in force 6 December 2025) created a parallel reporting obligation as a (besonders) wichtige Einrichtung, with its own clocks under § 32. A downstream-customer cascade introduced supply-chain liability from Article 21(2) NIS2.

Starting posture: weak but not yet in breach. No SBOM. No firmware inventory. No documented support-period rationale. No Article 14 runbook. VPN/SSH operations without per-user attribution. No vendor evidence packs. Hard-deletion confused with security-audit retention. A legacy-certificate exposure for one product family. An inherited site running as a black box from a prior customer migration.

The engineering team had no dedicated cybersecurity headcount. The deadlines do not move.

## Approach

The work adopted a deliberately rigorous posture from the first day: every load-bearing claim would be cited to the Official Journal text or an EU Commission interpretive document, every finding tagged with verification status, every document propagated through a cross-reference matrix functioning as an internal audit trail. The methodological commitments were:

- **Five-pass verbatim verification** against EU Regulation 2024/2847 (Articles 13, 14, 16, 22, 28, 31, 64, 69; Annex I Parts I and II; Annex II; Annex III; Annex VII), Directive (EU) 2022/2555 NIS2, and the German BSIG-neu (§§ 30, 32, 33, 38, 65). A separate citations annex carries verbatim regulatory text for every Cliff 1 deliverable, designed to survive a hostile review meeting line-by-line.
- **A "Position of Record" annex** capturing authoritative claims with their evidence chain, separable from the operational documents that depend on them.
- **A 32-finding consolidated catalogue** classified L (legally required) / I (implicit means) / B (best practice), tracked across 24 downstream documents with per-document propagation status (DONE / PENDING / FROZEN / OPTIONAL).
- **Open-question discipline**: every claim awaiting external corroboration (vendor PSIRT response, regulator clarification, notified-body designation) is tagged OPEN, with the document holding it explicitly noting the wait.

## What the work produced

Roughly 240 pages of audit-defensible evidence across thirteen primary documents:

- **Master Compliance Checklist** — consolidated obligations register across eleven themed sections (scope, inventory, legacy certificates, audit/logging, vulnerability handling, secure update + support period + Annex II, Article 14 reporting, edge security, procurement/vendor evidence, conformity assessment, GDPR/NIS2 alignment). Each row: gap statement, why-it-matters tied to a specific Annex/Article, severity (Critical / High), tickbox sub-items.
- **Audit-Readiness Deep-Dive** — primary-source verification companion testing every load-bearing claim, plus a 90-day execution plan.
- **Execution Timeline** — week-by-week through Cliff 1, monthly through Cliff 2, organised in seven phases across ten integration tracks.
- **Gap Analysis / Procedures / Procurement** — fifteen named threat scenarios, a thirteen-section policy/procedure inventory, twenty tooling categories, eight categories of external services.
- **Research Update** — vendor-by-vendor security posture refresh, CRA implementing-act status, German NIS2 transposition update, EUCC scheme positioning, legacy-certificate identification.
- **First 30 Days Alone** — sole-engineer prioritisation override, eight must-exist documents, a 30-day plan, management memo template, signature page template requesting staffing options A/B/C.
- **Executive Briefing** (16-slide deck) — board-facing, anchored on three numbers: days to cliff, fine ceiling, FTE reality. Reporting-clock infographic, 13-week roadmap, decision options.
- **Tech Coordination Deck** (~19 slides) — CTO-facing companion. Splits estate into edge-wired versus cloud-API integration modes, assigns six internal teams, three external parties, plus the Geschäftsführung.
- **Article 14 / § 32 BSIG Runbook** — operational runbook with verbatim regulatory text, four pre-drafted notification templates (24h early warning, 72h notification, 14d vulnerability final, 30d incident final), customer-comms template, ENISA Single Reporting Platform onboarding procedure.
- **RACI Matrix** — one-page accountability matrix covering ~25 cybersecurity and CRA/NIS2 functions; populated with real names, used as evidence of single-person concentration in the R column.
- **Consolidated Findings Annex** — the 32-finding catalogue × 24-document propagation tracker.
- **Operator's Playbook** — three-tier hand-holding guide ordered easiest-leverage-first; for each item: what, where it lives, what it must contain, who signs, where to file, effort estimate, citation satisfied.
- **README / Index** — Confluence topology, page-numbering convention, status banners (DRAFT / APPROVED / EFFECTIVE / SUPERSEDED), document map.

## Risk surface mapped

Fifteen named threat scenarios in the gap analysis:

- container escape on edge
- physical attack on unattended edge appliance
- NFC relay against mobile credential integration
- SSH key compromise propagating across the fleet
- unknown vulnerability on inherited site
- supply-chain compromise of a Docker base image
- central back-end compromise propagating to on-prem
- replay / time-drift
- cloning of contactless credentials
- vendor cloud compromise pivoting back
- insider via privileged engineering access
- mobile-app reverse engineering
- customer-side compromise propagating to integrator
- denial-of-service against central whitelist sync
- NIS2 supply-chain cascade liability

Twenty-five to twenty-nine entries in the risk register, scored on a 5×5 model (visible scores 25, 20, 16, 15). Tooling backlog spans twenty categories — SBOM, SAST, DAST, image scanning, secret scanning, image signing, runtime security, PAM / session recording, EDR on edge, SIEM, vulnerability management, patch management, secrets / credentials, PKI / cert management, HSM, code signing, backup / DR, GRC, threat-intel.

## Outcome

The work delivered a defensible position pack rather than a problem statement. Specifically:

- A board-readable briefing distilling the entire posture to three numbers and three staffing options.
- A line-by-line compliance register the regulator and notified body can audit against.
- An operational runbook for Article 14 reporting that runs without further design work — including pre-drafted notification text for each clock.
- An accountability matrix demonstrating the staffing-concentration reality (and therefore that escalation to leadership for staffing decisions is itself a documented control).
- An execution plan with explicit external-validation gates (notified-body designation, vendor evidence packs, regulator written replies) where the work cannot be advanced unilaterally.

The net effect: by Cliff 1 (11 September 2026) the operator can present this evidence pack to a notified body or to the regulator without preparation gaps, and the staffing-resource decision sits on the leadership table as an explicit board-level call rather than an engineering-team default. The "weak-but-not-yet-breaching" starting posture has a documented path to "audit-defensible".

## What the work did not produce

We did not implement controls. We did not write code. We did not engage with notified bodies or regulators on anyone's behalf. We did not provide ISO 27001 certification or a EUCC certificate. We did not build the SBOM pipeline or the PSIRT mailbox. The output was an evidence-grade readiness pack — a position from which staffed-up implementation can begin without re-litigating the foundations.

## Shape of the work

Sole-author intensive: roughly 240 pages produced across thirteen primary documents and four annexes. Front-loaded into a compressed drafting window with onward execution scoped over approximately nineteen months to Cliff 2. Companion-document architecture throughout — each deliverable explicitly describes how it overrides or complements the others. Confidential throughout; no public materials produced beyond this anonymised methodology reference.
