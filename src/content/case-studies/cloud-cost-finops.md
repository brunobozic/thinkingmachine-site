---
title: "Cloud cost assessment for a multi-installation SaaS vendor"
sector: "Industrial software vendor"
engagementType: "40-hour fixed-scope advisory"
year: "2026"
region: "Northern Europe"
summary: "A vendor preparing to quote a cloud-managed SaaS deal to a tier-1 enterprise customer needed a defensible per-installation pricing model — without access to the incumbent's hosting baseline. We delivered a triangulated baseline, multi-scenario pricing playbook, and a customer-side cost calculator."
publishedAt: "2026-05-09"
featured: true
---

## Context

A multi-installation industrial software vendor was preparing to quote a managed SaaS deal to a tier-1 enterprise customer. The vendor's existing deployment ran on the customer's infrastructure through a managed-services partner; the new arrangement would move responsibility for hosting and operations to the vendor itself.

The commercial question was deceptively simple: *what should we charge per installation per month?*

The complications were that:

1. The incumbent hosting baseline was opaque. The customer's managed-services partner had declined to release invoices, leaving the *what does this currently cost* question unanswerable from public information alone.
2. The workload sizing was uncertain. The only available performance data came from a downsized test environment; the actual production sizing was confirmed only mid-engagement.
3. The deal carried significant non-cost considerations — regulatory compliance, supply-chain risk, SaaS-enablement strategy — that needed to sit alongside the cost number, not behind it.

The workload was telemetry-heavy. Larger installations ingested approximately **200,000 rows per day** captured 24/7 from connected instruments through a Node.js receiver; smaller installations ran around 20,000 rows/day. The planned scope was twelve installations across two database performance tiers, totalling **36 servers** across production and non-production. Small enough that per-server fixed costs — typically negligible at enterprise scale — became disproportionate, which is part of why the assessment had to be done carefully rather than benchmark-extrapolated.

The vendor needed a board-grade document in roughly four weeks. The internal team was capable but did not have the bandwidth, and the larger consulting alternative would have required a multi-month discovery phase the timeline did not support.

## Approach

We anchored the assessment on cloud-economics, observability, and DevOps literature — Storment & Fuller, Majors, Nygard, Forsgren et al. — plus first-party Azure / AWS / GCP tier-selection and DR-cost guidance for the database engines in scope. The frameworks structured a four-category cost taxonomy: fixed overhead, competence, variable, per-server.

Within that frame we built:

- **A triangulated baseline.** Where invoices were unavailable, we constructed an estimated current spend from verified public cloud list pricing (cross-checked against the cloud provider's pricing API) multiplied by the typical partner-margin band for the customer's deployment scale.
- **A scenario matrix.** Three active cloud paths (Azure SQL Managed Instance, AWS RDS for SQL Server, GCP Cloud SQL — all License-Included after a customer-side decision ruled out license-transfer paths), each at three commitment levels (PAYG, one-year reserved, three-year reserved). Plus four ruled-out scenarios documented for completeness.
- **A pricing playbook.** What the vendor needed to charge per installation per month to cover verified cloud costs plus a target margin, modelled at three margin levels and two staffing postures (dedicated FTE versus absorbed operations).
- **A customer-side calculator.** A spreadsheet sheet the customer could populate with their actual incumbent costs to test whether the vendor's quote was competitive at any given margin.
- **An NFR compliance scoreboard.** Mapped the proposed architecture against the customer's existing non-functional requirements catalog, with explicit deferral of five open clarifications that did not block the Phase 1 commercial decision.

We also identified a zero-cost SQL configuration fix on the test environment (a parallelism-related setting that was driving an apparent need for a tier upgrade) — a finding that potentially reframed the entire sizing conversation and was flagged as priority action item one.

## What we delivered

- A roughly forty-page strategic cost-assessment report
- A separate twenty-six-sheet cost-model spreadsheet, including the live customer calculator
- A migration & recovery summary at strategic level
- An NFR compliance scoreboard
- Explicit out-of-scope declarations covering implementation, runbooks, IaC, deep code analysis, security audits, and proof-of-concept work

## Outcome

The vendor walked into the next customer meeting with a defensible per-installation pricing model anchored on verifiable public pricing, a clean separation between commercial price and infrastructure cost, and a calculator the customer could run themselves. The *is there a margin?* question — which had previously been unanswerable — was reframed as a SaaS-premium conversation supported by a quantified baseline.

The configuration finding identified during the engagement is, on its own, capable of changing the tier-selection conversation entirely.

## What we did not deliver

Implementation. Terraform / IaC. Deep code analysis. Security audit. Migration execution plan. Proof-of-concept. These were declared out-of-scope at engagement framing and remained so. The deliverable was decision support, not delivery.

## Engagement shape

Forty-hour fixed-scope advisory engagement spanning approximately four weeks across three working sessions plus async deliverables. Single principal engagement (no delivery team). Materials shared via the customer's collaboration system; deliverables retained by the customer.
