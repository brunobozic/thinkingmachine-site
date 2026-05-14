---
title: "Klinisch belastbare Video-Konsultations-Plattform für einen EU-Anbieter im Bereich psychischer Gesundheit"
sector: "EU-Anbieter im Bereich psychischer Gesundheit"
engagementType: "Architektur-Design & Technologie-Auswahl · anonymisierte interne Referenz"
year: "2026"
region: "Europäische Union"
summary: "Entwurf und Spezifikation einer selbst-gehosteten, EU-only Video-Konsultations-Plattform speziell für klinische Konsultationen im Bereich psychischer Gesundheit. Edge-ML-Architektur — Face-Mesh-Extraktion, Geräuschunterdrückung, ROI-Encoding und adaptive Framerate laufen am Client; der Server ist ein intelligenter Switch. Die bewusste architektonische Entscheidung wurde getroffen, keine Emotionserkennung durchzuführen — obwohl die medizinische Ausnahme des EU AI Act sie zuließe — weil die klinische Evidenz keine zuverlässige Emotionsinferenz aus Gesichtsausdrücken stützt. Ein Sechs-Dimensionen-Kosten-und-Qualitäts-Framework (CPU, RAM, Speicher, Bandbreite, klinische Qualität, Netzwerk-Resilienz) angewandt über Codec, Aufzeichnung, Transkription und Speicher-Tiering erreicht eine end-to-end **98%-Speicher-Reduktion** auf der Cold-Tier — €2.190/Monat hinunter auf €45–55/Monat bei 500 Sitzungen/Tag. Pro-Sitzung AES-256-GCM-Schlüssel aus HashiCorp Vault, Crypto-Shredding für DSGVO Artikel-9 Recht auf Löschung in unter 24 Stunden."
publishedAt: "2026-05-14"
featured: true
---

> **Hinweis zum Rahmen.** Diese Seite beschreibt Architektur-Design- und Technologie-Auswahl-Arbeit, geliefert an einen EU-Anbieter im Bereich psychischer Gesundheit, anonymisiert und als Methodik-Referenz veröffentlicht. Kein Produktname, kein Kundenname, keine Einzelnamen. Nur Sektor-Deskriptor.

## Kontext

Der Betreiber liefert Konsultationen im Bereich psychischer Gesundheit — klinische Psychologie und Psychiatrie — primär über deutschsprachige EU-Märkte, mit EU-weiter Expansion geplant. Die klinische Realität ist unnachgiebig: ein Kliniker, der den Zustand eines Patienten über eine Video-Verbindung liest, arbeitet auf Signal, das allgemein-zweckdienliche Video-Konferenz-Plattformen (Zoom, Teams, Doxy.me) wegoptimieren. Mikro-Ausdrücke im Gesicht und stimmliche Tonalität — die zwei primären Kanäle, durch die ein Kliniker einen Patienten beurteilt — erhalten dieselbe für-Geschäftsmeetings-komprimiert Behandlung wie jeder andere Anruf.

Der Auftrag war, eine selbst-gehostete, EU-only Video-Konsultations-Plattform zu spezifizieren, die:

1. Klinisch überlegene Audio- und Video-Qualität liefert — messbar besseres Signal für die Kanäle, die Kliniker tatsächlich verwenden, bei gleicher oder geringerer Bandbreite als Commodity-Plattformen.
2. Alle Daten innerhalb des EU-Perimeters des Betreibers behält — Hetzner Frankfurt, kein Dritt-Routing, keine Analytics, kein Data-Mining.
3. Biometrische Daten (Face-Mesh-Landmarks unter DSGVO Artikel 9) rechtmäßig behandelt — ausdrückliche Einwilligung, Zweckbindung, Aufbewahrungs-Disziplin und ein echter Recht-auf-Löschung-Pfad — und der restlichen anwendbaren Matrix standhalten: EHDS (HL7-FHIR-R4-Interoperabilität, Patienten-Zugriffsrechte), NIS2 (Gesundheitswesen als wichtige Einrichtung, 24h-/72h-Vorfalls-Meldung, Lieferketten-Sicherheit), ePrivacy (Vertraulichkeit der Kommunikation, doppelte Einwilligung für Aufzeichnung), ISO 27001 / 27799 (Healthcare-ISMS) und die nationalen Überlagerungen für die primären Expansions-Märkte — Deutschland (Gematik TI, BSI C5, KBV-Telemedizin-Richtlinien, DiGAV bei DiGA-Listing) und Kroatien (HZZO-Integration, AZOP-Registrierung, eZdravlje-Kompatibilität).
4. Von der Hochrisiko-Klassifikation des EU AI Act für Emotionserkennungs-Systeme fernbleibt — sowohl weil die regulatorische Belastung enorm ist als auch weil die klinische Evidenz keine zuverlässige Emotionsinferenz aus Gesichtsausdrücken stützt.
5. Von einem kleinen Team auf Commodity-Hetzner-Hardware betrieben werden kann, mit einer Kostenhülle, die einen langen Expansions-Vorlauf bis zum ersten Skalierungs-Ereignis trägt.

## Vorgehen — "Der Client arbeitet, der Server leitet weiter"

Das organisierende Prinzip der Architektur ist, dass alle Intelligenz — Face-Mesh-Extraktion, Geräuschunterdrückung, ROI-Encoding, Simulcast-Encoding, adaptive Framerate, Hintergrund-Weichzeichnung — auf dem Client-Gerät läuft. Der Server ist ein intelligenter Switch, der Pakete empfängt und weiterleitet.

Die praktischen Konsequenzen:

- Server-CPU bleibt selbst bei voller Kapazität unter 15%. Der Engpass ist Bandbreite, nicht Compute.
- Server-Technologie kann nach Zuverlässigkeit und operativer Einfachheit gewählt werden, nicht nach roher Performance. Client-Technologie kann nach Qualität der Audio- und Video-Verarbeitung auf dem Gerät gewählt werden, das der Nutzer bereits besitzt.
- Edge-ML (Face Mesh, Geräuschunterdrückung, ROI-Encoding) kostet den Betreiber null Pro-Sitzung-Server-Compute. Die Grenz-Kosten höherer Qualität sind null.

Der gewählte Stack:

- **Server**: eine Open-Source-SFU + Signaling + TURN-Kombination in einem einzigen Go-Binary. Business-API in Go. PostgreSQL für relationalen Zustand; Redis für Präsenz und Rate-Limiting; MinIO für verschlüsselte Recording-Segmente; HashiCorp Vault für Pro-Sitzung-Schlüssel; Keycloak für Authentifizierung (OIDC + SAML + MFA, mit LDAP / AD-Federation für Krankenhaus-Integrationen).
- **Clients**: nativ iOS (Swift + ARKits 52 Blendshapes, hardware-beschleunigte Gesichtsverfolgung auf TrueDepth-Geräten), nativ Android (Kotlin + ML Kits 468 Landmarks über die Geräte-Bandbreite) und ein Web-Client (SvelteKit + MediaPipe Face Mesh, 468 Landmarks bei 30 fps in WASM).
- **Audio**: Opus bei 48 kHz, 96 kbps — dreimal Zooms Default. Erhält Tonalität, Atem, Pausen und stimmliches Zittern.
- **Video**: H.264 High Profile bei 720p, Simulcast in drei Schichten (720p / 360p / 180p) für graceful Degradation ohne Server-seitiges Transcoding.
- **Edge-Audio-Verbesserung**: eine Open-Source-DNN-basierte Geräuschunterdrückungs- und Enthallungs-Pipeline, Full-Band bei 48 kHz, MIT-lizenziert.

## Die architektonischen Entscheidungen, die zählen

### ROI-Encoding — 2,5× schärferes Gesicht bei gleicher Gesamt-Bitrate

Standard-Video allokiert Bits gleichmäßig über das Frame. 60–70% der Bitrate gehen an Hintergrund (Wände, Bücherregale, Pflanzen). Das Gesicht — die einzige klinisch relevante Region — bekommt 30–40%.

Das ROI-Encoding der Plattform invertiert diese Allokation. Gesichtserkennung (bereits On-Device für Face Mesh laufend) identifiziert die Gesichts-Bounding-Box; die Hintergrund-Region erhält einen sanften Gauß-Blur (Radius 2–3 Pixel, kein voller Blur); der H.264-Encoder allokiert automatisch mehr Bits zu scharfen Regionen und weniger zu unscharfen. Gesamt-Bitrate bleibt bei 2,0 Mbps — aber das Gesicht bekommt etwa 2,5× mehr Bits als unter gleichmäßiger Allokation.

Ergebnis: Mikro-Ausdrücke sind dramatisch klarer. Implementierung ist vollständig Client-seitig — null Server-Kosten. iOS verwendet Metal-GPU-Shader gegen TrueDepth-Tiefendaten; Android verwendet ML Kit Selfie Segmentation mit einem Vulkan- / RenderScript-Blur-Pfad; Web verwendet MediaPipe-Segmentation mit einem WebGL-Shader.

### Adaptive Framerate, gesteuert durch Voice Activity Detection

Zoom und Teams senden konstant 30 fps unabhängig vom Inhalt. Die Plattform liest Opus' eingebautes Voice-Activity-Detection-Signal: wenn ein Teilnehmer zuhört (über zwei Sekunden still), sinkt die Framerate auf 10–15 fps; wenn er zu sprechen beginnt, stellt sie sich innerhalb von 100 ms auf 30 fps wieder her. Für eine typische 50-Minuten-Konsultation läuft die durchschnittliche Framerate bei rund 22 fps. Ein bewegungsloser Teilnehmer bei 10 fps sieht identisch zu 30 fps aus, weil H.264 bereits identische Frames zu nahezu Null-Delta komprimiert — die Einsparungen kommen daher, dass die Redundanz gar nicht erst kodiert und übertragen wird.

### Composite Recording — bessere klinische Inhalte bei halbem Speicher

Mainstream-Plattformen zeichnen volles Video bei gleichförmiger Qualität auf. Jedes Frame einer Wand hinter einem ruhigen Patienten bekommt dasselbe Bit-Budget wie ein Moment emotionaler Reaktion. Die Plattform zeichnet sowohl volles Video als auch Face Mesh auf, dann entscheidet sie pro Segment, welches Artefakt behalten wird:

- **High-Activity-Segmente** (emotionale Reaktionen, Gesten, stimmliche Intensität): volles H.264-Video bei voller Qualität bewahren.
- **Low-Activity-Segmente** (Zuhören, stabile Haltung): nur Face-Mesh-Landmarks plus volles Audio behalten.

Aktivitäts-Klassifikation auf Bewegungs-Magnitude, nicht auf Emotion: das Delta von 468 Face-Mesh-Landmarks zwischen aufeinanderfolgenden Frames, normalisiert durch die Gesichts-Bounding-Box-Größe, mit EMA-Glättung und Hysterese. Audio wird immer in voller Qualität bewahrt unabhängig von der Segment-Klassifikation, so wird stilles Weinen voll erfasst, auch wenn die Bewegung gering ist. Kliniker können auch manuell Momente markieren, was Voll-Video-Bewahrung unabhängig von der Bewegungs-Klassifikation erzwingt.

Speicher-Ergebnis: etwa 50% weniger als Mainstream-Plattformen, mit **besseren** klinischen Inhalten (High-Activity-Momente erhalten einen größeren Anteil des Speicher-Budgets). Replay unterstützt drei Avatar-Stile für die Mesh-nur-Segmente — Wireframe, neutral geometrisch, Low-Poly stilisiert — jeder bewahrt klinisches Signal (Mikro-Ausdrücke, Blickrichtung, Bewegungs-Tempo, Ausdrucks-Symmetrie), ohne das Aussehen des Patienten zu zeigen.

### Biometrische Daten, DSGVO Artikel 9 und die bewusste Nicht-Verwendung von Emotionserkennung

Face-Mesh-Landmarks sind biometrische Daten unter DSGVO Artikel 9. Aus 468 Landmark-Positionen kann man eine Person eindeutig identifizieren (Faceprint). Das löst eine bestimmte Reihe von Pflichten aus: ausdrückliche Einwilligung speziell für Face-Mesh-Speicherung (keine generische "Zustimmung zur Aufzeichnung"), definierter Zweck, Datenminimierung, definierte Aufbewahrungsdauer und ein echter Recht-auf-Löschung-Pfad. Die Plattform implementiert all diese — einschließlich **Crypto-Shredding** (Löschung des Pro-Sitzung-AES-256-GCM-Schlüssels aus HashiCorp Vault macht die Aufzeichnung kryptographisch nicht wiederherstellbar, erfüllt das Lösch-Recht in unter 24 Stunden).

Die schwierigere Entscheidung war, was mit dem Face Mesh nach der Erfassung zu tun ist. Der **EU AI Act (Artikel 5(1)(f), in Kraft seit 2. Februar 2025)** verbietet Emotionserkennung in Arbeits- und Bildungskontexten — aber erlaubt sie ausdrücklich für medizinische Zwecke über eine enge Ausnahme. Die Versuchung, besonders für eine an Kliniker gerichtete Plattform, ist, die medizinische Ausnahme zu nutzen und Emotionsklassifikation auf das Mesh zu bauen.

Die Plattform tut das nicht. Zwei Gründe.

Erstens: die klinische Evidenz stützt keine zuverlässige Emotionsinferenz aus Gesichtsausdrücken. Das Ekman-„universelle-Emotionen" / Facial-Action-Coding-System-Framework — die Basis jedes kommerziellen Emotionserkennungs-Produkts — ist Gegenstand einer ungünstigen Meta-Analyse von 2019 über mehr als tausend Studien von Lisa Feldman Barrett und Kolleg:innen. Dieselbe Person, dieselbe Emotion drückt sich in verschiedenen Kontexten verschieden aus; verschiedene Kulturen kodieren Ausdruck unterschiedlich; in klinischen Settings speziell sind Patienten, die Lachen maskieren oder durch intensiven Distress flach-gesichtig dasitzen, Routine. Ein Kliniker liest Kontext, nicht nur Ausdruck; ein Inferenz-System kann das nicht.

Zweitens: selbst wo Emotionserkennung unter der medizinischen Ausnahme erlaubt ist, löst die Klassifikation die Hochrisiko-Kategorie des EU AI Act (**Anhang III**) aus und die Konformitätsbewertung, Qualitätsmanagement, Dokumentation (zehn Jahre Aufbewahrung), menschliche Aufsicht, Robustheit, Genauigkeit und EU-AI-Datenbank-Registrierungs-Anforderungen, die damit einhergehen. Die regulatorische Belastung ist enorm; die Strafhöchstgrenze liegt bei €35 Millionen oder 7% des globalen Jahresumsatzes.

Die Plattform misst also **Bewegung** — die Magnitude des Landmark-Deltas zwischen Frames — nicht Emotion. Bewegung ist ein klinisch nützliches Signal (es steuert die Aufnahme-Qualitäts-Entscheidung und das Bookmark-Surfacing), trägt aber keine Inferenz über den psychischen Zustand. Es gibt keine Emotions-Labels, keine Konfidenz-Werte, keine zeitlichen Emotions-Graphen. Das System sagt einem Kliniker nie, was ein Patient fühlt.

### Sicherheits-Hülle

- **Transport**: DTLS-SRTP für alle WebRTC-Medien (die obligatorische WebRTC-Basislinie); WSS für Signaling; HTTPS mit TLS 1.3 für API. Phase 2 führt SFrame-Ende-zu-Ende-Verschlüsselung ein — sogar der Server sieht nur verschlüsselte Media-Frames.
- **Aufzeichnung-at-Rest**: AES-256-GCM mit Pro-Sitzung-Schlüsseln aus HashiCorp Vault. Der Schlüssel verlässt Vault nie; Vaults Transit-Engine führt die Encrypt- / Decrypt-Operationen aus. Löschung des Schlüssels (Crypto-Shredding) macht die Aufzeichnung nicht wiederherstellbar.
- **Authentifizierung**: Keycloak selbst-gehostet, OIDC + SAML, MFA (TOTP und WebAuthn / FIDO2-Hardware-Keys für Kliniker), LDAP / AD-Federation für Krankenhaus-Systeme.
- **Audit-Trail**: append-only, hash-verkettet, manipulationsfest. Jede Aktion geloggt (Login, Raum erstellen / beitreten / verlassen, Einwilligung gegeben / geändert, Aufnahme Start / Stopp, Daten-Zugriff, Daten-Löschung). Kein PHI im Audit-Trail — nur IDs, Aktionen, Zeitstempel. Aufbewahrung zehn Jahre.

### Kostenengineering — Skalierung um 6–12 Monate verschoben

Eine Kombination aus **P2P-wenn-Aufzeichnung-nicht-erforderlich** (rund 40% der Sitzungen), **Smart Silence** (die Zuhörer-Seite sinkt auf 10 fps bei 0,4 Mbps), **adaptiver Framerate** und **verzögerter Aufzeichnung** (der formale aufgezeichnete Teil umfasst nur die klinisch relevante Mitte einer Sitzung, mit P2P für Smalltalk davor und Terminierung danach) hebt die Concurrent-Session-Kapazität einer einzelnen €52 / Monat Hetzner-Box von einer Baseline von ~145 auf etwa **~280**. Der zweite Server wird bei ~280 Concurrent-Sessions statt bei ~145 benötigt — das Skalierungs-Ereignis verschiebt sich um 6–12 Monate.

### Transkriptions-Pipeline — selbst-gehostet, mehrsprachig, klinisch reviewbar

Sitzungen werden post-Session über eine vollständig selbst-gehostete Pipeline transkribiert — kein Dritt-Cloud-ASR, Audio verlässt die Infrastruktur des Betreibers nie. Die Pipeline läuft FFmpeg-Audio-Extraktion → Silero-VAD-Stille-Stripping → faster-whisper (Whisper large-v3-turbo via CTranslate2, INT8-Quantisierung, ~3–5 Minuten pro 50-Minuten-Sitzung auf einer NVIDIA T4) → wav2vec2 erzwungene Wort-Ausrichtung → pyannote-audio 3.1 Sprecher-Diarisierung → JSONL mit Pro-Wort-Zeitstempeln, Sprecher-Labels und Konfidenz, zstd-komprimiert. Ziel-Genauigkeit: WER ≤ 8% auf sauberer Sprache, ≤ 15% auf spontaner Konversation, WDER ≤ 5% in Zwei-Sprecher-Szenarien (das klinische Setting ist immer Zwei-Sprecher: Kliniker + Patient). Kern-Sprachen: Kroatisch, Englisch, Deutsch, Italienisch — erweiterbar auf 99+ via Whisper. Das Transkript synchronisiert mit der Aufzeichnung für Wort-genaues Scrubbing, Volltext-Suche über alle Sitzungen und zeitstempel-verknüpfte klinische Annotationen.

### Speicher-Ökonomie — 98% Reduktion auf der Cold-Tier

Die 50%-Composite-Recording-Zahl ist eine von vier Schichten in der kumulativen Speicher-Strategie. Das vollständige Bild:

- **Live-Transport-Codec**: VP9 SVC primär (25% Upload-Bandbreiten-Reduktion vs H.264-Simulcast, sofortiges Quality-Layer-Switching ohne Keyframe-Wartezeit), H.264-Simulcast-Fallback für Safari und Pre-2020-Geräte.
- **Offline-Speicher-Codec**: SVT-AV1 lizenzfrei mit vier-stufigem CRF-Tiering (CRF 30 hot / 35 warm / 38 cold-archival), VMAF-abgeglichen gegen H.264-Baseline auf jeder Stufe. 64–67% Speicher-Reduktion vs H.264 bei gleicher visueller Qualität.
- **Composite Recording**: Pro-Segment-Voll-Video-vs-Mesh-Only-Entscheidung, getrieben durch Bewegungs-Magnitude (nicht Emotion), wie oben beschrieben. ~50% weitere Reduktion.
- **Face-Mesh-Kompression**: 303 MB/Stunde Roh → 10–15 MB/Stunde via Delta-of-Delta-Encoding + zstd-Wörterbuch + xxHash3-128-Content-Dedup (93–95% Reduktion auf dem Mesh-Stream).

Kumulativer Effekt: eine 50-Minuten-Sitzung, die unkomprimiert 4+ GB wäre, landet bei **50–60 MB auf der Cold-Tier**, einschließlich Video, Audio, Face-Mesh-Geometrie und vollem Transkript. Monatliche Speicher-Kosten für 500 Sitzungen/Tag: etwa **€45–55**, gegenüber **€2.190** für eine naive nicht-optimierte Implementierung. Die vier-stufige Codec-/Aufbewahrungs-Strategie ist mit Aufbewahrungs-Richtlinien gekoppelt, die an die DSGVO-Zweckbindungs-Analyse gebunden sind: Hot-Tier 30 Tage, Warm 90 Tage, Cold-Archival bis zur gesetzlichen Aufbewahrungsgrenze, dann crypto-shredded.

### Netzwerk-Resilienz — Degradation, die der Patient nicht bemerkt

Patienten verbinden sich aus variablen Bandbreiten-Bedingungen. Der Resilienz-Stack der Plattform:

- **Fünf-stufige Audio-Degradations-Leiter**: Opus 96 kbps + RED (klinisch) → 64 kbps + FEC → 32 kbps → 16 kbps → Lyra V2 bei 6 kbps (neuronaler Codec, verständlich bei nahezu-2G-Geschwindigkeiten). Die Umschaltung ist automatisch, getrieben durch die ausgehandelte Bandbreiten-Schätzung, und der Patient sieht keinen Qualitäts-Dialog.
- **Predictive ICE-Restart** für Netzwerk-Übergänge (Wi-Fi → Mobilfunk, etc.): Lücke fällt vom 4–7-Sekunden-reaktiven Default unter 500 ms.
- **Therapie-getunter Jitter-Buffer** (120 ms Ziel) für weniger Glitches zum Preis marginal höherer End-to-End-Latenz — der Trade-off begünstigt Stabilität für den klinischen Use-Case.
- **FlexFEC + DSCP-Markierung** für die Transport-Schicht, BBRv3 auf der Server-Seite.

### Compliance-getriebene Architektur-Entscheidungen, an Klauseln rückverfolgbar

| Entscheidung | Treibende Klausel |
|---|---|
| End-to-End-Verschlüsselung (SFrame in Phase 2) | ePrivacy + DSGVO Art. 32 — SFU kann auf Medien-Inhalt nicht zugreifen |
| Pro-Sitzung AES-256-GCM mit Crypto-Shredding | DSGVO Art. 17 — Löschung des Schlüssels = Löschung aller abgeleiteten Daten |
| EU-only-Infrastruktur | DSGVO Kapitel V — keine Drittland-Adäquanz-Komplikationen |
| Append-only Hash-verkettetes Audit-Log | NIS2 + DSGVO Art. 30 — manipulationsfeste Verarbeitungs-Aufzeichnungen |
| Einwilligungs-gegatete Verarbeitung | DSGVO Art. 9(2)(a) — ausdrückliche Einwilligung vor jeder besonderen-Kategorie-Verarbeitung |
| Doppelte Einwilligung für Aufzeichnung | ePrivacy + nationale Überlagerungen — beide Parteien willigen aktenkundig ein |
| Bewegungs-Detektion statt Emotions-Klassifikation | EU-AI-Act Art. 5(1)(f) + Anhang-III-Analyse — Hochrisiko-Klassifikation vermeiden |

## Ergebnis

Das Lieferobjekt war eine Architektur-Spezifikation, bereit für gestaffelte Implementierung, mit den Technologie-Entscheidungen auf einem Niveau gerechtfertigt, das ein Regulierer oder eine Benannte Stelle auditieren könnte:

- Eine Edge-ML-Medien-Pipeline, die messbar besseres klinisches Signal liefert als Commodity-Video-Konferenz bei gleicher Bandbreite.
- Ein Composite-Recording-Ansatz, der mehr klinisch nützliche Artefakte in weniger Speicher produziert, ohne etwas über den psychischen Zustand zu inferieren.
- Eine belastbare Position zum EU AI Act: die Plattform führt keine Emotionserkennung durch, und die Wahl ist mit Bezug sowohl auf die regulatorische Analyse (Artikel 5(1)(f), Anhang III) als auch auf die klinische Evidenzbasis (Lisa Feldman Barrett 2019) dokumentiert.
- Eine Kostenhülle, dimensioniert für den Expansions-Plan des Betreibers, mit dem nächsten Skalierungs-Ereignis 6–12 Monate später als bei einer naiven Implementierung.

## Was die Arbeit nicht produzierte

Produktions-Code. Ein Live-Deployment. Eine klinische Studie. Eine formale Konformitätsbewertung unter MDR. Die Arbeit war Architektur-Design, Technologie-Auswahl und die zugrundeliegende regulatorische Analyse — das Substrat, auf dem Implementierung ruht, nicht die Implementierung selbst.

## Form der Arbeit

Sole-Architect-Engagement über ein komprimiertes Drafting-Fenster. Ein ~64-seitiges primäres Design-Dokument mit einem begleitenden Technologie-Landschafts-Memo. Materialien produziert als strukturiertes Workbook im bevorzugten Dateiformat des Betreibers. Durchgehend vertraulich; diese Seite ist die einzige anonymisierte Referenz.
