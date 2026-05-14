---
title: "Clinical-grade video consultation platform for an EU mental-health services provider"
sector: "EU mental-health services provider"
engagementType: "Architecture design & technology selection · anonymised internal reference"
year: "2026"
region: "European Union"
summary: "Designed and specified a self-hosted, EU-only video-consultation platform purpose-built for clinical mental-health consultations. Edge-ML architecture — face-mesh extraction, noise cancellation, ROI encoding, and adaptive framerate all run on the client; the server is a smart switch. Made the deliberate architectural choice not to do emotion recognition, despite the EU AI Act's medical exemption permitting it, because the clinical evidence does not support reliable emotion inference from facial expression. A six-dimension cost-and-quality framework (CPU, RAM, storage, bandwidth, clinical quality, network resilience) applied across codec, recording, transcription, and storage tiering achieves an end-to-end **98% storage reduction** at the cold tier — €2,190/month down to €45–55/month at 500 sessions/day. Per-session AES-256-GCM keys from HashiCorp Vault, crypto-shredding for GDPR Article 9 right-to-erasure in under 24 hours."
publishedAt: "2026-05-14"
featured: true
---

> **Note on framing.** This page describes architecture-design and technology-selection work delivered to an EU mental-health services provider, anonymised and published as a methodology reference. No product name, no client name, no individual names. Sector descriptor only.

## Context

The operator delivers mental-health consultations — clinical psychology and psychiatry — primarily across German-speaking EU markets, with EU-wide expansion planned. The clinical reality is unforgiving: a clinician reading a patient's state across a video link is operating on signal that general-purpose video-conferencing platforms (Zoom, Teams, Doxy.me) optimise away. Facial micro-expressions and vocal tonality — the two primary channels through which a clinician assesses a patient — get the same compressed-for-business-meetings treatment as any other call.

The brief was to specify a self-hosted, EU-only video-consultation platform that would:

1. Deliver clinically-superior audio and video — measurably better signal for the channels clinicians actually use, at the same or lower bandwidth than commodity platforms.
2. Keep all data within the operator's EU perimeter — Hetzner Frankfurt, no third-party routing, no analytics, no data mining.
3. Handle biometric data (face-mesh landmarks under GDPR Article 9) lawfully — explicit consent, purpose limitation, retention discipline, and a genuine right-to-erasure pathway — and stand up to the rest of the applicable matrix: EHDS (HL7 FHIR R4 interoperability, patient access rights), NIS2 (healthcare as essential entity, 24h / 72h incident reporting, supply-chain security), ePrivacy (confidentiality of communications, dual consent for recording), ISO 27001 / 27799 (healthcare ISMS), and the national overlays for the primary expansion markets — Germany (Gematik TI, BSI C5, KBV telemedicine guidelines, DiGAV if a DiGA listing is pursued) and Croatia (HZZO integration, AZOP registration, eZdravlje compatibility).
4. Stay clear of the EU AI Act's high-risk classification for emotion-recognition systems — both because the regulatory burden is enormous and because the clinical evidence does not support reliable emotion inference from facial expression.
5. Be operable by a small team on commodity Hetzner hardware, with a cost envelope sized to support a long expansion runway before the first scaling event.

## Approach — "Client works, server forwards"

The architecture's organising principle is that all intelligence — face-mesh extraction, noise cancellation, ROI encoding, simulcast encoding, adaptive framerate, background softening — runs on the client device. The server is a smart switch that receives packets and forwards them.

The practical consequences:

- Server CPU stays under 15% even at full capacity. The bottleneck is bandwidth, not compute.
- Server technology can be chosen for reliability and operational simplicity, not raw performance. Client technology can be chosen for quality of audio and video processing on the device the user already owns.
- Adding ML at the edge (face mesh, noise cancellation, ROI encoding) costs the operator zero per-session server compute. The marginal cost of higher quality is zero.

The selected stack:

- **Server**: an open-source SFU + signaling + TURN combination in a single Go binary. Business API in Go. PostgreSQL for relational state; Redis for presence and rate limiting; MinIO for encrypted recording segments; HashiCorp Vault for per-session encryption keys; Keycloak for authentication (OIDC + SAML + MFA, with LDAP/AD federation for hospital integrations).
- **Clients**: native iOS (Swift + ARKit's 52 blendshapes, hardware-accelerated face tracking on TrueDepth-equipped devices), native Android (Kotlin + ML Kit's 468 landmarks across the device range), and a Web client (SvelteKit + MediaPipe Face Mesh, 468 landmarks at 30 fps in WASM).
- **Audio**: Opus at 48 kHz, 96 kbps — three times Zoom's default. Preserves tonality, breath, pauses, and vocal tremor.
- **Video**: H.264 High Profile at 720p, simulcast in three layers (720p / 360p / 180p) for graceful degradation without server-side transcoding.
- **Edge audio enhancement**: an open-source DNN-based noise-cancellation and dereverberation pipeline, full-band at 48 kHz, MIT-licensed.

## The architectural decisions that matter

### ROI encoding — 2.5× sharper face at the same total bitrate

Standard video allocates bits uniformly across the frame. 60–70% of the bitrate goes to background (walls, bookshelves, plants). The face — the only clinically relevant region — gets 30–40%.

The platform's ROI encoding inverts that allocation. Face detection (already running on-device for face mesh) identifies the face bounding box; the background region receives a soft Gaussian blur (radius 2–3 pixels, not full blur); the H.264 encoder automatically allocates more bits to sharp regions and fewer to blurred ones. Total bitrate stays at 2.0 Mbps — but the face gets approximately 2.5× more bits than under uniform allocation.

Result: micro-expressions are dramatically clearer. Implementation is entirely client-side — zero server cost. iOS uses Metal GPU shaders against TrueDepth depth data; Android uses ML Kit Selfie Segmentation with a Vulkan / RenderScript blur path; Web uses MediaPipe segmentation with a WebGL shader.

### Adaptive framerate driven by Voice Activity Detection

Zoom and Teams send a constant 30 fps regardless of content. The platform reads Opus's built-in Voice Activity Detection signal: when a participant is listening (silent for more than two seconds), framerate drops to 10–15 fps; when they begin speaking, it restores to 30 fps within 100 ms. For a typical 50-minute consultation, average framerate runs around 22 fps. A motionless participant at 10 fps looks identical to 30 fps because H.264 already compresses identical frames to near-zero delta — the savings come from not encoding-and-transmitting the redundancy in the first place.

### Composite recording — better clinical content in half the storage

Mainstream platforms record full video at uniform quality. Every frame of a wall behind a quiet patient gets the same bit budget as a moment of emotional reaction. The platform records both full video and face mesh, then per-segment decides which artifact to keep:

- **High-activity segments** (emotional reactions, gestures, vocal intensity): preserve full H.264 video at full quality.
- **Low-activity segments** (listening, stable posture): keep only face-mesh landmarks plus full audio.

Activity classification is on movement magnitude, not on emotion: the delta of 468 face-mesh landmarks between consecutive frames, normalised by face bounding-box size, with EMA smoothing and hysteresis. Audio is always preserved at full quality regardless of segment classification, so crying-quietly is captured in full even when motion is low. Clinicians can also manually bookmark moments, which forces full-video preservation regardless of motion classification.

Storage result: approximately 50% less than mainstream platforms, with **better** clinical content (high-activity moments get a larger share of the storage budget). Replay supports three avatar styles for the mesh-only segments — wireframe, neutral geometric, low-poly stylised — each preserves clinical signal (micro-expressions, gaze direction, movement tempo, expression symmetry) without showing the patient's appearance.

### Biometric data, GDPR Article 9, and the deliberate non-use of emotion recognition

Face-mesh landmarks are biometric data under GDPR Article 9. From 468 landmark positions you can uniquely identify a person (faceprint). That triggers a specific set of obligations: explicit consent specifically for face-mesh storage (not generic "consent to recording"), defined purpose, data minimisation, defined retention period, and a genuine right-to-erasure pathway. The platform implements all of these — including **crypto-shredding** (deletion of the per-session AES-256-GCM key from HashiCorp Vault renders the recording cryptographically unrecoverable, satisfying the erasure right in under 24 hours).

The harder decision was what to do with the face mesh once captured. The **EU AI Act (Article 5(1)(f), in force from 2 February 2025)** prohibits emotion recognition in workplace and education contexts — but explicitly permits it for medical purposes via a narrow exemption. The temptation, especially for a platform marketed to clinicians, is to use the medical exemption and build emotion classification on top of the mesh.

The platform does not do this. Two reasons.

First, the clinical evidence does not support reliable emotion inference from facial expression. The Ekman "universal emotions" / Facial Action Coding System framework — the basis of every commercial emotion-recognition product — is the subject of an unfavourable 2019 meta-analysis of more than a thousand studies by Lisa Feldman Barrett and colleagues. Same person, same emotion expresses differently across contexts; different cultures encode expression differently; in clinical settings specifically, patients masking laughter or sitting flat-faced through intense distress are routine. A clinician reads context, not just expression; an inference system cannot.

Second, even where emotion recognition is permitted under the medical exemption, classifying it triggers the EU AI Act's high-risk category (**Annex III**) and the conformity assessment, quality management, documentation (ten-year retention), human-oversight, robustness, accuracy, and EU-AI-database registration requirements that come with it. The regulatory burden is enormous; the penalty ceiling is €35 million or 7% of global annual turnover.

So the platform measures **movement** — magnitude of landmark delta between frames — not emotion. Movement is a clinically useful signal (it drives the recording-quality decision and the bookmark-surfacing) but it carries no inference about psychological state. There are no emotion labels, no confidence scores, no temporal emotion graphs. The system never tells a clinician what a patient is feeling.

### Security envelope

- **Transport**: DTLS-SRTP for all WebRTC media (the mandatory WebRTC baseline); WSS for signaling; HTTPS with TLS 1.3 for API. Phase 2 introduces SFrame end-to-end encryption — even the server sees only encrypted media frames.
- **Recording at rest**: AES-256-GCM with per-session keys from HashiCorp Vault. The key never leaves Vault; Vault's Transit engine performs the encrypt / decrypt operations. Deletion of the key (crypto-shredding) makes the recording unrecoverable.
- **Authentication**: Keycloak self-hosted, OIDC + SAML, MFA (TOTP and WebAuthn / FIDO2 hardware keys for clinicians), LDAP / AD federation for hospital systems.
- **Audit trail**: append-only, hash-chained, tamper-evident. Every action logged (login, room create / join / leave, consent given / changed, recording start / stop, data access, data deletion). No PHI in the audit trail — only IDs, actions, timestamps. Retention ten years.

### Cost engineering — scaling delayed 6–12 months

A combination of **P2P-when-recording-not-required** (around 40% of sessions), **smart silence** (the listener side drops to 10 fps at 0.4 Mbps), **adaptive framerate**, and **delayed recording** (the formal recorded portion only spans the clinically relevant centre of a session, with P2P for small-talk before and scheduling after) lifts the concurrent-session capacity of a single €52 / month Hetzner box from a baseline of ~145 to approximately **~280**. The second server is needed at ~280 concurrent sessions instead of ~145 — the scaling event moves out by 6–12 months.

### Transcription pipeline — self-hosted, multi-language, clinically reviewable

Therapy sessions are transcribed post-session through a fully self-hosted pipeline — no third-party cloud ASR, audio never leaves the operator's infrastructure. The pipeline runs FFmpeg audio extraction → Silero VAD silence stripping → faster-whisper (Whisper large-v3-turbo via CTranslate2, INT8 quantisation, ~3–5 minutes per 50-minute session on an NVIDIA T4) → wav2vec2 forced word alignment → pyannote-audio 3.1 speaker diarization → JSONL with per-word timestamps, speaker labels, and confidence, compressed with zstd. Target accuracy: WER ≤ 8% on clean speech, ≤ 15% on spontaneous conversational speech, WDER ≤ 5% on two-speaker scenarios (the clinical setting is always two-speaker: clinician + patient). Core languages: Croatian, English, German, Italian — extensible to 99+ via Whisper. The transcript synchronises with the recording for word-level scrubbing, full-text search across all sessions, and timestamp-linked clinical annotations.

### Storage economics — 98% reduction at the cold tier

The 50% composite-recording number is one of four layers in the cumulative storage strategy. The full picture:

- **Live transport codec**: VP9 SVC primary (25% upload-bandwidth reduction vs H.264 simulcast, instant quality-layer switching without keyframe wait), H.264 simulcast fallback for Safari and pre-2020 devices.
- **Offline storage codec**: SVT-AV1 royalty-free with four-tier CRF tiering (CRF 30 hot / 35 warm / 38 cold archival), VMAF-matched against H.264 baseline at every tier. 64–67% storage reduction vs H.264 at equivalent visual quality.
- **Composite recording**: per-segment full-video-vs-mesh-only decision driven by movement magnitude (not emotion), as described above. ~50% further reduction.
- **Face-mesh compression**: 303 MB/hour raw → 10–15 MB/hour via delta-of-delta encoding + zstd dictionary + xxHash3-128 content dedup (93–95% reduction on the mesh stream).

Cumulative effect: a 50-minute session that would be 4+ GB uncompressed lands at **50–60 MB at the cold tier**, including video, audio, face mesh geometry, and full transcript. Monthly storage cost for 500 sessions/day: approximately **€45–55**, versus **€2,190** for a naïve unoptimised implementation. The four-tier codec/retention strategy is paired with retention policies tied to the GDPR purpose-limitation analysis: hot tier 30 days, warm 90 days, cold archival to the lawful retention limit, then crypto-shredded.

### Network resilience — degradation that the patient does not notice

Patients connect from variable bandwidth conditions. The platform's resilience stack:

- **Five-tier audio degradation ladder**: Opus 96 kbps + RED (clinical-grade) → 64 kbps + FEC → 32 kbps → 16 kbps → Lyra V2 at 6 kbps (neural codec, intelligible at near-2G speeds). The handover is automatic, driven by the negotiated bandwidth estimate, and the patient does not see a quality dialog.
- **Predictive ICE restart** for network transitions (Wi-Fi → mobile data, etc.): gap drops from the 4–7 second reactive default to under 500 ms.
- **Therapy-tuned jitter buffer** (120 ms target) for fewer glitches at the cost of marginally more end-to-end latency — the trade-off favours stability for the clinical use case.
- **FlexFEC + DSCP marking** for the transport layer, BBRv3 on the server side.

### Compliance-driven architecture decisions, traced to clauses

| Decision | Driving clause |
|---|---|
| End-to-end encryption (SFrame in Phase 2) | ePrivacy + GDPR Art. 32 — SFU cannot access media content |
| Per-session AES-256-GCM with crypto-shredding | GDPR Art. 17 — deletion of the key constitutes deletion of all derived data |
| EU-only infrastructure | GDPR Chapter V — no third-country adequacy complications |
| Append-only hash-chained audit log | NIS2 + GDPR Art. 30 — tamper-evident processing records |
| Consent-gated everything | GDPR Art. 9(2)(a) — explicit consent before any special-category processing |
| Dual consent for recording | ePrivacy + national overlays — both parties consent on the record |
| Movement detection, not emotion classification | EU AI Act Art. 5(1)(f) + Annex III analysis — stay clear of high-risk classification |

## Outcome

The deliverable was an architecture specification ready for staged implementation, with the technology choices justified at the level a regulator or notified body could audit:

- An edge-ML media pipeline that delivers measurably better clinical signal than commodity video conferencing at the same bandwidth.
- A composite-recording approach that produces more clinically useful artifacts in less storage, without inferring anything about psychological state.
- A defensible position on the EU AI Act: the platform does not perform emotion recognition, and the choice is documented with reference to both the regulatory analysis (Article 5(1)(f), Annex III) and the clinical-evidence base (Lisa Feldman Barrett 2019).
- A cost envelope sized for the operator's expansion plan, with the next scaling event pushed out by 6–12 months relative to a naïve implementation.

## What the work did not produce

Production code. A live deployment. A clinical trial. A formal conformity assessment under MDR. The work was architecture design, technology selection, and the regulatory analysis underlying both — the substrate that implementation rests on, not the implementation itself.

## Shape of the work

Sole-architect engagement over a compressed drafting window. A ~64-page primary design document with a companion technology-landscape memo. Materials produced as a structured workbook in the operator's preferred file format. Confidential throughout; this page is the only anonymised reference.
