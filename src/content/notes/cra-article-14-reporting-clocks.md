---
title: "CRA Article 14 reporting clocks: what 24h, 72h, 14d, and 30d actually require"
summary: "From 11 September 2026, every manufacturer placing a product with digital elements on the EU market is on the clock the moment an actively-exploited vulnerability or severe incident is identified. Four reporting clocks, four different deliverables, one single notification platform. Here is the operational reality, not the press-release version."
publishedAt: "2026-05-14"
tags: ["CRA", "Cyber Resilience Act", "NIS2", "Compliance", "Runbook"]
---

The EU Cyber Resilience Act (Regulation 2024/2847) introduces a four-tier reporting regime that takes force at Cliff 1, **11 September 2026**. Every economic operator placing products with digital elements on the EU market is on the clock the moment an actively-exploited vulnerability or severe incident is identified. The clocks do not pause for weekends, holidays, or in-flight investigation. They are calendar-time, not business-time.

The four clocks are commonly written as "24h / 72h / 14d / 30d" — but they are not four steps of one process. They are four different deliverables, with different audiences and different content. This note walks each one.

## The 24-hour early warning

Triggered as soon as the manufacturer becomes aware of an actively-exploited vulnerability *or* of a severe incident affecting the security of the product. The clock starts at awareness, not at confirmation.

The deliverable is short — a notification to the relevant CSIRT (the national CSIRT designated under NIS2; for a German manufacturer that is BSI under § 32 BSIG-neu) plus, where the product is in scope, ENISA via the Single Reporting Platform.

The minimum content is the existence of the issue, an initial assessment of severity, and any mitigation already taken or known. A manufacturer that does not yet know whether the vulnerability is being exploited still has to notify if it has reasonable indication that it is.

This is the most-missed clock in practice. Engineering teams trigger an internal incident-response process, work through the day, and then realise on Tuesday evening that they passed the 24-hour mark on Monday morning. The runbook fix is to make the 24-hour notification a parallel obligation, not a sequential one — someone outside the engineering team owns it, and notification goes out as soon as the early signal is real, not when the investigation is complete.

## The 72-hour notification

Within 72 hours of awareness, the manufacturer files a more substantive notification with the CSIRT (and ENISA, again via the Single Reporting Platform). This notification updates the 24-hour early warning with what is now known: the nature of the vulnerability or incident, its severity assessment, the affected product versions, the user populations potentially impacted, and any mitigation or workaround now available.

The 72-hour clock runs from the same awareness moment as the 24-hour clock — they are concurrent, not sequential. Filing the 24-hour early warning does not reset the 72-hour clock.

The substantive question at 72 hours is no longer "does this exist" but "what do users need to know now to protect themselves". A manufacturer that has not yet pushed a security update by hour 72 must still notify, and must include in the notification the timeline for the update and the mitigation users can apply in the interim.

## The 14-day vulnerability final report

For actively-exploited vulnerabilities, a final report is due within 14 days of the security update being made available (or, where no update is forthcoming, of the mitigation being made available). The final report describes the vulnerability in technical detail sufficient for downstream operators to assess their own exposure, the root cause, the corrective measures, and the lessons applied to the development process.

This is where the SBOM obligation under CRA Annex I Part II(1) bites hardest. The 14-day vulnerability final report has to be able to point to the specific component that carried the vulnerability, the versions affected, and the version range in which the fix is applied. A manufacturer that does not maintain an accurate SBOM cannot file this report cleanly — and the regulator will notice.

## The 30-day incident final report

For severe incidents (as distinct from vulnerabilities), a final report is due within 30 days of the original 24-hour early warning. The 30-day report covers what happened, why, what the impact was, what the corrective measures are, and what the manufacturer is doing to prevent recurrence.

The 30-day clock allows time for forensic investigation — which is realistic, because severe incidents are usually multi-causal and the root-cause analysis takes more than a fortnight. But the 30 days is a firm deadline, not a guideline. A manufacturer that is not ready at day 30 must still file, and must do so noting what is still under investigation.

## Single Reporting Platform — one inbox, one credential

The ENISA Single Reporting Platform is the single technical interface for these notifications across the EU. A manufacturer files once; the relevant national authorities receive the notification through the platform. The Regulation requires the platform to be operational by 11 September 2026 — ENISA's actual deployment timeline is the relevant risk to monitor.

Practical implication: the credentials for the Single Reporting Platform need to exist *before* the first 24-hour notification is filed. Setting up the credentials during an incident is exactly the wrong time. The runbook step is to register, designate the responsible-person role, and complete the platform onboarding well before any product is shipped under CRA scope. We have seen organisations leave this until the week of Cliff 1 — that is the worst time to discover that the role authorisation requires a senior-management signature.

## NIS2 § 32 BSIG — the parallel clock for essential entities

A manufacturer that is also an essential or important entity under NIS2 (which the German transposition BSIG-neu codes as *(besonders) wichtige Einrichtung*) is on the NIS2 § 32 reporting regime in addition to the CRA Article 14 regime. The clocks are similar — 24h, 72h, and a one-month final report — but the audience is the NIS2 competent authority, not the product-side CSIRT, and the substantive content emphasises the entity's operational impact rather than the product's vulnerability.

In practice, a multi-purpose runbook needs to map both regimes onto a single internal incident-handling process, so that the engineering team does not have to remember which clock they are on. The right design is one incident process with two parallel notification tracks, both filed from the same forensic-evidence base.

## What the runbook needs to be

A working Article 14 / § 32 runbook covers, at minimum:

- The trigger conditions for each clock (what counts as "awareness")
- The responsible-person designations for each notification
- The Single Reporting Platform credentials and the BSI portal credentials, and where they live
- Four pre-drafted notification templates (one per clock) with the regulatory text quoted verbatim, so that the on-call person is not drafting under pressure
- A customer-communications template for the cases where the incident is severe enough to require notifying users directly
- An evidence-retention policy that preserves the forensic state at the moment of the 24-hour early warning

The whole package is one document. It should be readable in under fifteen minutes by an on-call engineer who has not seen it before. If it is longer than that, it will not be read in the moment that matters.

---

*This note draws on the CRA Article 14 / § 32 BSIG runbook produced as part of [the EU Cyber Resilience Act readiness work documented in our case studies](/work/cra-readiness-eu-manufacturer). The four notification templates from that runbook are anonymised but otherwise unchanged in this material.*
