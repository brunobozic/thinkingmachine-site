---
title: "Software supply-chain controls and platform-IaC rescue for a multi-tenant SaaS vendor"
sector: "Multi-tenant SaaS vendor"
engagementType: "Applied platform-engineering work · anonymised internal reference"
year: "2024"
region: "European Union"
summary: "Revived a five-year-old Ansible/Semaphore IaC stack end-to-end from reconstruction across four repositories — orchestration playbooks, production nginx reverse proxy, PostgreSQL container base image, analytics-stack feature branch. Added an internal-trust-root software supply-chain layer (Composer/Satis, npm/Verdaccio, SQL/Redgate, container/GitLab Registry) and an analytics stack (Metabase + Grafana). Approximately 30% of the engagement was software supply-chain management — directly relevant to CRA Article 13 SBOM/integrity obligations and NIS2 Article 21(2) supply-chain cascade."
publishedAt: "2026-05-13"
featured: true
---

> **Note on framing.** This page describes execution work delivered to a multi-tenant SaaS operator, anonymised and published as a methodology reference. No client identification, no tenant names, sector descriptor only. The work pre-dates Thinking Machine's current fixed-scope advisory shape and is included on the case-study page because it informs three of today's lanes: cyber resilience (supply chain), AI integration (the underlying IaC pattern), and the operational reality of NIS2 / CRA evidence packs.

## Context

The operator ran a multi-tenant SaaS platform on Hetzner Cloud, organised around a master / tenant architecture: a central Semaphore UI orchestrating Ansible playbooks against on-demand developer and customer VMs. The platform had been built five to six years earlier by engineers who had since moved on. The IaC was structurally sound but no longer ran end-to-end. Documentation lagged the code, the Semaphore-API automation had drifted out of sync with the running version, and several control-plane components (BIND9 zone files, OpenVPN client provisioning, docker-login against the GitLab Container Registry) had silently degraded.

Layered on top, the operator needed three additions:

1. **A software supply-chain layer.** The platform consumed PHP packages from public Packagist, JavaScript packages from public npm, and SQL artifacts from ad-hoc developer machines. There was no internal trust root. Container images came from the GitLab Container Registry already, but the credential flow was brittle.
2. **An analytics stack.** Metabase for tenant-data BI; Grafana for operational metrics. Each on its own Hetzner VM, wired into the same DNS zone and PKI as the rest of the platform.
3. **Resilience improvements to provisioning.** Idempotent user creation, no SSH-key sprawl across customer VMs, and a working docker-login path for the container registry.

The team had no dedicated platform engineer. The work needed to land before customer expansion put load on the existing flows.

## Approach

The starting move was to make the existing stack work end-to-end again from reconstruction. No greenfield rebuild. Reading the existing Ansible code across the orchestration repository, the inventory layout (`group_vars`, `host_vars`, `playbooks`, `tasks`, `roles`, `templates`), the Semaphore template definitions, and the docker-login flow against the GitLab Container Registry, and then exercising each path with real provisioning runs against Hetzner.

The engagement spanned **four interconnected repositories**, with roughly one hundred and seventy-eight commits across them as the visible trace:

- **Orchestration / IaC repository** (~85 commits) — Ansible playbooks, Semaphore project configuration, the per-tenant VM-provisioning chain. Visible in the trace as small, incremental, debugging-grade messages — the typical signature of working against a flaky external API and a multi-VM provisioning chain. Clusters: Semaphore API integration (JSON-array-vs-object mismatches, idempotent user creation, 400-on-create-user debugging), SSH-key hygiene (developer keys had been silently propagating onto every provisioned VM — fix removes that path and documents why the change is structural), docker-login against the GitLab Container Registry (two separate login flows were getting conflated — fix separates them and exposes credentials through a Makefile target with a verifiable login step), certificate lifecycle (wildcard certificate for the internal TLD, per-VM development certificates, internal CA trust chain).
- **Production nginx reverse-proxy repository** (~67 commits) — the TLS-terminating edge in front of the internal analytics tools (Grafana, Metabase, Redash). The work concentrated on WebSocket support for Grafana real-time dashboards, per-service auth routing (some services do not need auth on the internal network), custom error pages, redirect-loop fixes, and PWA-routing edge cases. Production-tagged across multiple released versions, so the changes were deployed on a real customer-facing perimeter rather than a sandbox.
- **PostgreSQL container repository** (~20 commits) — base-image work on the database container. The recurring theme was getting Postgres logs to cross container boundaries reliably — log-file ownership across users and groups, `postgresql.conf` provisioning at container-build time, log files needing to be readable by sibling containers, and the small but real DBA-side toolchain (e.g. adding `nano` to the base image to make in-container debugging tractable).
- **Analytics-stack feature branch** (~6 commits) — a working copy used to develop the metabase/grafana VPS provisioning before it merged into the main orchestration repo. The commits document the typical pain of getting Metabase to connect to a GitLab-hosted Postgres through the internal firewall (ICMP restrictions, network namespacing) — the kind of integration debugging that does not show up in the public commit log of the final merged playbook.

## Software supply-chain layer

Approximately 30% of the engagement was concentrated here. The pattern is simple to describe and operationally consequential: every artifact channel the platform consumed was wrapped behind an internal trust root.

- **Composer / PHP packages → Satis.** Private repository service for Composer. Internal packages and approved third-party mirrors are served from Satis; the platform's `composer.json` proxies through it rather than reaching public Packagist directly. Effect: a typosquatted Packagist package cannot land in a tenant build by accident.
- **npm / JavaScript packages → Verdaccio.** Same shape on the JavaScript side. Front-end builds resolve through Verdaccio; public-npm reach is mediated rather than direct. Effect: a compromised public-npm tarball does not enter the tenant build path without explicit allow-list change.
- **SQL artifacts → Redgate SQL Source Control.** SQL Compare and Source Control bring schema changes under version-control review the same way application code already was. Effect: database changes become reviewable diffs with a named approver, not ad-hoc DBA actions.
- **Container images → GitLab Container Registry.** Already in place; the engagement made the credential flow reliable and the login step verifiable.

Each layer is paired with the certificate lifecycle so that the registries themselves authenticate against the same internal CA used by the rest of the platform.

## Analytics stack

Two further Hetzner VMs were added — one for Metabase, one for Grafana — each provisioned through the same Ansible / Semaphore path used for the developer and customer VMs. The Metabase VM hosts the BI tool with its own PostgreSQL metadata store and a Java Keystore for TLS termination. The Grafana VM uses the same internal CA, persists state under `/grafana`, and runs the `grafana/grafana-oss` image in Docker behind the same DNS-zone naming convention as the rest of the platform. Both nodes are reachable only inside the OpenVPN overlay; neither is exposed to the public internet. The TLS-terminating reverse proxy that fronts them is the production nginx repository above — WebSocket support for Grafana real-time, per-service auth routing, custom 4xx/5xx pages.

## Outcome

The platform IaC works end-to-end again, with the moving parts documented (architecture, playbooks, roles, workflows) at a level that survives the next engineer-rotation event. The supply-chain layer means the answer to *can you describe how a typosquatted public package would reach production* is "it cannot, because the artifact channels are mediated by internal registries". The analytics stack runs alongside the rest of the platform without expanding the public attack surface. The production reverse-proxy is tagged-and-released, so changes flow through a discipline that maps onto NIS2 § 21(2) "secure development" expectations.

In the language of CRA Cliff 1 (11 September 2026) and NIS2 Article 21(2), this body of work produced — two years earlier — exactly the kind of supply-chain-integrity evidence that those regulations now require operators to be able to present to a regulator or a notified body on request.

## What the work did not produce

We did not run a formal SBOM pipeline (the SBOM mandate post-dates the work). We did not perform a third-party penetration test against the registries. We did not produce a tenant-data-protection assessment. We did not produce an ISO/IEC 27001 Statement of Applicability. The work was operational improvement, not compliance attestation — but the operational improvements are the substrate that compliance attestation rests on.

## Shape of the work

Sole-engineer intensive over several months, working alongside the operator's small in-house team. Approximately **178 commits across four repositories** as the visible trace: the orchestration IaC, the production nginx reverse-proxy, the PostgreSQL container base image, and the analytics-stack feature branch. Plus the supply-chain registry components and the analytics-stack provisioning. Confidential throughout; this page is the only anonymised reference.
