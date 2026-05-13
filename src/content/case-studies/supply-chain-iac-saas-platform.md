---
title: "Software supply-chain controls and platform-IaC rescue for a multi-tenant SaaS vendor"
sector: "Multi-tenant SaaS vendor"
engagementType: "Applied platform-engineering work · anonymised internal reference"
year: "2024"
region: "European Union"
summary: "Revived a five-year-old Ansible/Semaphore IaC stack end-to-end from reconstruction; added an internal-trust-root software supply-chain layer (Composer/Satis, npm/Verdaccio, SQL/Redgate, container/GitLab Registry) and an analytics stack (Metabase + Grafana). Approximately 30% of the engagement was software supply-chain management — directly relevant to CRA Article 13 SBOM/integrity obligations and NIS2 Article 21(2) supply-chain cascade."
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

The starting move was to make the existing stack work end-to-end again from reconstruction. No greenfield rebuild. Reading the existing Ansible code, the inventory layout (`group_vars`, `host_vars`, `playbooks`, `tasks`, `roles`, `templates`), the Semaphore template definitions, and the docker-login flow against the GitLab Container Registry, and then exercising each path with real provisioning runs against Hetzner.

That phase produced approximately 85 commits across the IaC repository — visible in the public-facing parts of the trace as small, incremental, debugging-grade messages (the typical signature of working against a flaky external API and a multi-VM provisioning chain). The clusters were:

- **Semaphore API integration.** Idempotent user creation, template variable scoping, JSON object-vs-array shape mismatches (the Semaphore HTTP API expects arrays where the playbook templating produced objects), 400-on-create-user debugging. The output is a Semaphore project that admins can use to self-serve new developer VMs and customer environments without touching Ansible directly.
- **SSH-key hygiene.** Developer SSH keys were being silently propagated onto every provisioned VM. The fix removes that path and documents why the change is structural rather than cosmetic — a small piece of evidence that the supply-chain posture extends to the credential boundary between development and production.
- **docker-login against the registry.** Two separate GitLab login flows (one for the registry, one for the API) were getting conflated. The fix separates them, exposes the credentials through a Makefile target, and gives the playbook a verifiable login step before any image pull.
- **Certificate lifecycle.** PKI / CA assets (wildcard certificate for the internal TLD, per-VM development certificates, internal CA trust chain) integrated cleanly with the dev-VM and analytics-VM provisioning paths so every node speaks mTLS off a single internal trust root.

## Software supply-chain layer

Approximately 30% of the engagement was concentrated here. The pattern is simple to describe and operationally consequential: every artifact channel the platform consumed was wrapped behind an internal trust root.

- **Composer / PHP packages → Satis.** Private repository service for Composer. Internal packages and approved third-party mirrors are served from Satis; the platform's `composer.json` proxies through it rather than reaching public Packagist directly. Effect: a typosquatted Packagist package cannot land in a tenant build by accident.
- **npm / JavaScript packages → Verdaccio.** Same shape on the JavaScript side. Front-end builds resolve through Verdaccio; public-npm reach is mediated rather than direct. Effect: a compromised public-npm tarball does not enter the tenant build path without explicit allow-list change.
- **SQL artifacts → Redgate SQL Source Control.** SQL Compare and Source Control bring schema changes under version-control review the same way application code already was. Effect: database changes become reviewable diffs with a named approver, not ad-hoc DBA actions.
- **Container images → GitLab Container Registry.** Already in place; the engagement made the credential flow reliable and the login step verifiable.

Each layer is paired with the certificate lifecycle so that the registries themselves authenticate against the same internal CA used by the rest of the platform.

## Analytics stack

Two further Hetzner VMs were added — one for Metabase, one for Grafana — each provisioned through the same Ansible / Semaphore path used for the developer and customer VMs. The Metabase VM hosts the BI tool with its own PostgreSQL metadata store and a Java Keystore for TLS termination. The Grafana VM uses the same internal CA, persists state under `/grafana`, and runs the `grafana/grafana-oss` image in Docker behind the same DNS-zone naming convention as the rest of the platform. Both nodes are reachable only inside the OpenVPN overlay; neither is exposed to the public internet.

## Outcome

The platform IaC works end-to-end again, with the moving parts documented (architecture, playbooks, roles, workflows) at a level that survives the next engineer-rotation event. The supply-chain layer means the answer to *can you describe how a typosquatted public package would reach production* is "it cannot, because the artifact channels are mediated by internal registries". The analytics stack runs alongside the rest of the platform without expanding the public attack surface.

In the language of CRA Cliff 1 (11 September 2026) and NIS2 Article 21(2), this body of work produced — two years earlier — exactly the kind of supply-chain-integrity evidence that those regulations now require operators to be able to present to a regulator or a notified body on request.

## What the work did not produce

We did not run a formal SBOM pipeline (the SBOM mandate post-dates the work). We did not perform a third-party penetration test against the registries. We did not produce a tenant-data-protection assessment. We did not produce an ISO/IEC 27001 Statement of Applicability. The work was operational improvement, not compliance attestation — but the operational improvements are the substrate that compliance attestation rests on.

## Shape of the work

Sole-engineer intensive over several months, working alongside the operator's small in-house team. Approximately 85 commits on the IaC repository as the visible trace, plus the analytics-stack provisioning and the four supply-chain registry components. Confidential throughout; this page is the only anonymised reference.
