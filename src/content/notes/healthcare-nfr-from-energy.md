---
title: "Why your healthcare-IT NFR matrix should look like an energy-sector one"
summary: "Healthcare-IT vendors handed a hospital procurement NFR catalogue tend to react with the same mild horror SaaS vendors react to energy-sector matrices with. The fix is the same: copy the discipline the more scarred sector has already paid for. Five patterns that move."
publishedAt: "2026-05-09"
tags: ["NFR", "Healthcare IT", "Energy", "Procurement", "Cross-domain"]
---

A pattern shows up every time we work with a healthcare-IT vendor that has just received its first hospital-procurement non-functional-requirement matrix: the matrix is shorter than an energy-sector one (twenty to thirty rows, not fifty), but the structure is fuzzier, the evidence column is often missing, and the answers come back as PowerPoint paragraphs rather than scored cells.

The hospital procurement team is not less rigorous than the energy operator. It is *less practised*. Energy operators have thirty years of integration scar tissue and have converged on a workable matrix shape. Healthcare-IT procurement is younger, more fragmented across national health systems, and still inventing its own conventions. A healthcare-IT vendor that arrives with the energy-sector discipline pre-built has a structural advantage that compounds over every deal.

A few patterns directly transferable from the energy NFR practice we wrote about [in the previous note](/notes/energy-procurement-nfr-saas):

**The compliant / partial / non-compliant / desirable matrix.** The four-state schema is a shared vocabulary that procurement teams everywhere can use. Healthcare procurement teams that haven't seen it before adopt it within one read. The honesty implied by *partial* (rather than the binary "yes/no" most healthcare-IT vendors default to) builds trust faster than any sales narrative.

**Evidence-link everything.** A SOC 2 report PDF link, a pen-test summary, a signed DPA, a CRA Article 13 risk-assessment excerpt, a HL7 FHIR R4 conformance statement — these things are *evidence assets*. Healthcare-specific overlays add: an EHDS-readiness statement, a GDPR Article 9 lawful-basis register, an ISO 27799 ISMS scope letter, an MDR / EN 62304 SaMD classification (if applicable), and the relevant national-transposition references (Gematik TI integration plan for Germany, AZOP registration for Croatia, etc.). Treat each one as a versioned PDF that lives in a known URL pattern. The procurement team will copy-paste your evidence references into their internal report — make it easy.

**Cost-impact alongside gap-status.** This is where healthcare-IT vendors lose deals they could win. When you mark a requirement *partial*, the next question is always "what does it cost to make it compliant?" Pre-answer it. A *partial — we encrypt at rest but key rotation is manual* row with a €15k / 6-week remediation note is a deal in progress; the same row without the note is a "we'll get back to you" that dies in committee.

**Source-verification log.** A separate document linking each justification ("we comply with X") to a specific meeting, email, design document, or published policy. Procurement teams need this provenance to defend the decision internally. It also forces the vendor to answer truthfully — every soft claim becomes a citation that has to exist somewhere.

**Maintain it as a living document.** Healthcare-IT NFR responses tend to be re-invented per deal because hospitals each ask in slightly different formats. They are more similar than they look. Build the response once, version it, and re-issue. The marginal cost of the next response drops by 80%. The competitive advantage in regulated-customer deals compounds.

The healthcare-specific layer that energy doesn't have:

- **GDPR Article 9 (special-category data)** is a structurally different obligation from the GDPR baseline most vendors think they understand. Health data needs an explicit legal basis under Article 9(2), usually patient consent or healthcare-provision necessity, and the lawful-basis assertion has to survive an audit.
- **EHDS** (the European Health Data Space, Regulation 2025/...) layers an interoperability obligation on top — HL7 FHIR R4 capability becomes the lingua franca, and primary-use vs secondary-use data flows have to be cleanly separated.
- **NIS2 essential-entity classification** applies to most healthcare providers and to some software vendors that supply them, which means Article 14-style reporting clocks (24h / 72h / 14d) are in scope.
- **MDR / EN 62304 / ISO 14971** apply if any part of the product makes a clinical decision, which is a line many digital-health products don't realise they crossed.
- **ISO 27001 + 27799** is the right ISMS scoping pair. A healthcare-IT vendor with ISO 27001 alone but no 27799 reads as half-cooked to a hospital security architect.

Build a single living document that answers all of this, with evidence-links per row, in the four-state matrix format, and you arrive at hospital procurement with the same sales-cycle advantage that the disciplined SaaS vendors have in energy-sector deals: the procurement team finishes their internal report in days instead of weeks. Same competitive moat, different sector.

If you sell software into hospitals, payers, or any healthcare-adjacent regulated buyer and you do not have a versioned NFR response document in the four-state matrix format with evidence-links — you are about to either lose a deal or invent the same document under deadline pressure. The energy-sector procurement teams have already paid for the format. Copy it.
