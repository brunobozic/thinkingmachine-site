---
title: "Software supply-chain controls and platform-IaC rescue for a multi-tenant SaaS vendor"
sector: "Multi-tenant SaaS vendor"
engagementType: "Applied platform-engineering work · anonymised internal reference"
year: "2024"
region: "European Union"
summary: "Reconstructed a five-year-old Ansible/Semaphore IaC stack end-to-end across four repositories — orchestration playbooks, production nginx reverse proxy, PostgreSQL container, analytics-stack feature branch. Designed and shipped a gated software supply-chain layer (Composer/Satis, npm/Verdaccio, SQL/Redgate, container/GitLab Registry) with per-package static analysis, vulnerability scanning, and approval before any developer could resolve a third-party dependency. Approximately 30% of the engagement; implemented in 2024, two years before CRA Cliff 2 (11 December 2027) makes SBOM and supply-chain integrity a regulatory obligation across the EU."
publishedAt: "2026-05-13"
featured: true
---

> **Note on framing.** This page describes execution work delivered to a multi-tenant SaaS operator, anonymised and published as a methodology reference. No client identification, no tenant names, sector descriptor only. The work pre-dates Thinking Machine's current fixed-scope advisory shape and is included on the case-study page because it informs three of today's lanes: cyber resilience (supply chain), AI integration (the underlying IaC pattern), and the operational reality of NIS2 / CRA evidence packs.

## Context

The operator ran a multi-tenant SaaS platform on Hetzner Cloud, organised around a master / tenant architecture: a central Semaphore UI orchestrating Ansible playbooks against on-demand developer and customer VMs. The platform had been built five to six years earlier by engineers who had since moved on. The IaC was structurally sound but no longer ran end-to-end. Documentation lagged the code, the Semaphore-API automation had drifted out of sync with the running version, and several control-plane components (BIND9 zone files, OpenVPN client provisioning, docker-login against the GitLab Container Registry) had silently degraded.

Layered on top, the operator needed three additions:

1. **A software supply-chain layer.** The platform consumed PHP packages from public Packagist, JavaScript packages from public npm, and SQL artifacts from ad-hoc developer machines. There was no internal trust root and no pre-integration evaluation gate. Container images came from the GitLab Container Registry already, but the credential flow was brittle.
2. **An analytics stack.** Metabase for tenant-data BI; Grafana for operational metrics. Each on its own Hetzner VM, wired into the same DNS zone and PKI as the rest of the platform.
3. **Resilience improvements to provisioning.** Idempotent user creation, no SSH-key sprawl across customer VMs, and a working docker-login path for the container registry.

The team had no dedicated platform engineer. The work needed to land before customer expansion put load on the existing flows.

## Approach

The starting move was to make the existing stack work end-to-end again from cold reading of inherited code. No greenfield rebuild — the structurally sound parts were salvageable, the cost of rewriting from scratch was uneconomic. Reconstructed working knowledge from the existing Ansible orchestration repository, the inventory layout (`group_vars`, `host_vars`, `playbooks`, `tasks`, `roles`, `templates`), the Semaphore template definitions, and the docker-login flow against the GitLab Container Registry, and then exercised each path with real provisioning runs against Hetzner.

The engagement spanned **four interconnected repositories**, with roughly one hundred and seventy-eight commits across them as the visible trace:

- **Orchestration / IaC repository** (~85 commits) — Ansible playbooks, Semaphore project configuration, the per-tenant VM-provisioning chain. Visible in the trace as small, incremental, debugging-grade messages — the signature of iterative work against a flaky external API and a multi-VM provisioning chain. Clusters: Semaphore API integration (JSON-array-vs-object mismatches, idempotent user creation, 400-on-create-user debugging), SSH-key hygiene (developer keys had been silently propagating onto every provisioned VM — fix removes that path and documents why the change is structural, not cosmetic), docker-login against the GitLab Container Registry (two separate login flows were getting conflated — fix separates them and exposes credentials through a Makefile target with a verifiable login step before any image pull), certificate lifecycle (wildcard certificate for the internal TLD, per-VM development certificates, internal CA trust chain).
- **Production nginx reverse-proxy repository** (~67 commits) — the TLS-terminating edge in front of the internal analytics tools (Grafana, Metabase, Redash). The work concentrated on WebSocket support for Grafana real-time dashboards, per-service auth routing (some services do not need auth on the internal network), custom error pages, redirect-loop fixes, and PWA-routing edge cases. **Production-tagged across multiple released versions**, so the changes were deployed on a real customer-facing perimeter rather than a sandbox.
- **PostgreSQL container repository** (~20 commits) — base-image work on the database container. The recurring theme was getting Postgres logs to cross container boundaries reliably — log-file ownership across users and groups, `postgresql.conf` provisioning at container-build time, log files needing to be readable by sibling containers, and the small but real DBA-side toolchain.
- **Analytics-stack feature branch** (~6 commits) — a working copy used to develop the metabase/grafana VPS provisioning before it merged into the main orchestration repo. The commits document the integration debugging — getting Metabase to connect to a GitLab-hosted Postgres through the internal firewall — that does not show up in the public commit log of the final merged playbook.

## Software supply-chain layer

Approximately 30% of the engagement was concentrated here. The objective was operationally simple and regulatorily consequential: **no third-party package would reach a tenant build without a documented pre-integration evaluation** against the cybersecurity controls now codified across EU medical-device software, NIS2 supply-chain, and CRA-manufacturer obligations.

The architecture is a workflow, not just a static list of registries. Every artifact channel the platform consumed — PHP packages via Composer, JavaScript packages via npm, SQL schema changes, container images — passed through the same four-step gate before a developer could resolve it:

1. **Request.** A developer requests a new third-party package, naming it, the requested version, and the intended use within the tenant build.
2. **Static analysis.** The candidate package is pulled into an isolated runner. Composition scanning enumerates transitive dependencies and license inventory. The license inventory is matched against the operator's permitted-licence list. Code-level signal is reviewed for the obvious unsafe patterns (`eval`, dynamic execution, shell-out, build-time post-install hooks reaching the network).
3. **Vulnerability analysis.** The candidate package and every transitive dependency are looked up in CVE / GHSA / OSV databases at the requested version. Packages with known unpatched-and-exploitable vulnerabilities are rejected outright; packages with patched vulnerabilities at a higher version are approved at the patched version, not the requested version, with the developer's `composer.json` or `package.json` updated to match.
4. **Approval and mirror.** If the package passes both gates, it is mirrored into the internal registry — **Satis for Composer**, **Verdaccio for npm** — at the approved version, with the evaluation record retained alongside the binary. Only at that point can a developer's `composer require` or `npm install` resolve the package. There is no resolver path that bypasses the internal registry.

The same shape applied to **SQL schema artifacts** through Redgate SQL Compare and Source Control — every schema change becomes a reviewable diff with a named approver before it can reach a tenant database — and to **container images** through the GitLab Container Registry as the single authorised image source for tenant VMs, with the docker-login flow giving the Ansible playbook a verifiable login step before any image pull.

The pattern maps directly onto the regulatory landscape that subsequently codified what was already shipped:

- **EN / IEC 62304 § 5.1.5 and § 8.1** — SOUP (Software of Unknown Provenance) identification and anomaly review. Every third-party item carries its inventory record, intended use, and known-vulnerability review at the version actually consumed.
- **MDCG 2019-16** — the EU MDR cybersecurity guidance requirement to perform "thorough evaluation of third-party components" *before integration* is satisfied operationally by the static-analysis-then-vuln-scan gate, not by an after-the-fact attestation.
- **IEC 81001-5-1** — health-software security activities in the product lifecycle. The internal-registry-as-single-source-of-truth makes the SBOM and supplier-evaluation requirements a byproduct of operation rather than a separately maintained artefact.
- **NIS2 Article 21(2)(d)** — supply-chain security for essential and important entities (the health sector is in NIS2 Annex I). The gate IS the supply-chain control: a typosquatted Packagist package cannot reach a tenant build because no resolver path bypasses the internal registry.
- **CRA Article 13 and Annex I Part II(1) and (2)** — manufacturer obligations to identify components, produce an SBOM, and handle vulnerabilities effectively. Cliff 2 (11 December 2027) makes these full obligations across the EU. The registry produces the SBOM as a byproduct; the evaluation log is the vulnerability-handling evidence.

Implemented in 2024 — two years before the early CRA reporting obligations (Cliff 1, September 2026) and three years before the full SBOM and component-identification mandate (Cliff 2, December 2027).

## Analytics stack

Two further Hetzner VMs were added — one for Metabase, one for Grafana — each provisioned through the same Ansible / Semaphore path used for the developer and customer VMs. The Metabase VM hosts the BI tool with its own PostgreSQL metadata store and a Java Keystore for TLS termination. The Grafana VM uses the same internal CA, persists state under `/grafana`, and runs the `grafana/grafana-oss` image in Docker behind the same DNS-zone naming convention as the rest of the platform. Both nodes are reachable only inside the OpenVPN overlay; neither is exposed to the public internet. The TLS-terminating reverse proxy that fronts them is the production nginx repository above — WebSocket support for Grafana real-time, per-service auth routing, custom 4xx/5xx pages.

## Outcome

The platform IaC works end-to-end again, with the moving parts documented (architecture, playbooks, roles, workflows) at a level that survives the next engineer-rotation event. The supply-chain layer means the answer to *can you describe how a typosquatted public package would reach production* is "it cannot, because the resolver path is mediated by an internal registry and every candidate package has been through static analysis, vulnerability scanning, and a documented approval before it can be served." The analytics stack runs alongside the rest of the platform without expanding the public attack surface. The production reverse proxy is tagged-and-released across multiple versions, which maps onto NIS2 § 21(2) "secure development" expectations.

In the language of CRA Cliff 1 (11 September 2026) and CRA Cliff 2 (11 December 2027), this body of work produced — two to three years earlier — exactly the kind of supply-chain-integrity evidence pack the regulation now requires manufacturers to be able to present to a regulator or a notified body on request.

## What the work did not produce

A formal SBOM pipeline emitting SPDX / CycloneDX (the SBOM-format mandate post-dates the work; the internal registry was the source of truth for component inventory but the export format was operator-internal). A third-party penetration test against the registries. A tenant-data-protection assessment. An ISO/IEC 27001 Statement of Applicability. The work was operational improvement, not compliance attestation — but the operational improvements are the substrate that compliance attestation rests on.

## Shape of the work

Sole-principal engagement over several months, leading the work in coordination with the operator's small in-house team. **Approximately 178 commits across four repositories** as the visible trace: the orchestration IaC, the production nginx reverse-proxy, the PostgreSQL container base image, and the analytics-stack feature branch. Plus the four-channel supply-chain gate and the analytics-stack provisioning. Confidential throughout; this page is the only anonymised reference.
