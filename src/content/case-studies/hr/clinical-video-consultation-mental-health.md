---
title: "Klinički-grade platforma za video konzultacije za EU pružatelja usluga mentalnog zdravlja"
sector: "EU pružatelj usluga mentalnog zdravlja"
engagementType: "Dizajn arhitekture i odabir tehnologije · anonimizirana interna referenca"
year: "2026"
region: "Europska unija"
summary: "Osmišljena i specificirana self-hosted, EU-only platforma za video konzultacije namjenski izgrađena za kliničke konzultacije u području mentalnog zdravlja. Edge-ML arhitektura — ekstrakcija face mesha, smanjenje šuma, ROI kodiranje i adaptivna brzina sličica izvršavaju se na klijentu; server je inteligentni preklopnik. Donesena svjesna arhitektonska odluka da se ne provodi prepoznavanje emocija — iako medicinska iznimka EU AI Acta to dopušta — jer klinička evidencija ne podržava pouzdanu inferenciju emocija iz izraza lica. Kompozitno snimanje (puni video za segmente visoke aktivnosti, face mesh + audio za dijelove niske aktivnosti) smanjuje pohranu ~50% uz strogo bolji klinički sadržaj. Po-sesijski AES-256-GCM ključevi iz HashiCorp Vaulta, crypto-shredding za GDPR članak 9 pravo na brisanje u manje od 24 sata."
publishedAt: "2026-05-14"
featured: true
---

> **Bilješka o uokviravanju.** Ova stranica opisuje rad na dizajnu arhitekture i odabiru tehnologije isporučen EU pružatelju usluga mentalnog zdravlja, anonimiziran i objavljen kao metodološka referenca. Bez imena proizvoda, bez imena klijenta, bez pojedinačnih imena. Samo deskriptor sektora.

## Kontekst

Operator pruža konzultacije iz područja mentalnog zdravlja — kliničke psihologije i psihijatrije — prvenstveno preko EU tržišta njemačkog govornog područja, s planiranom ekspanzijom diljem EU-a. Klinička je realnost nepopustljiva: kliničar koji čita stanje pacijenta preko video veze radi na signalu koji opće-namjenske platforme za video konferencije (Zoom, Teams, Doxy.me) optimiziraju van postojanja. Mikro-izrazi lica i glasovna tonalnost — dva primarna kanala kroz koja kliničar procjenjuje pacijenta — dobivaju isti tretman kompresije-za-poslovne-sastanke kao i bilo koji drugi poziv.

Zadatak je bio specificirati self-hosted, EU-only platformu za video konzultacije koja bi:

1. Isporučila klinički superiorniju audio i video kvalitetu — mjerljivo bolji signal za kanale koje kliničari zapravo koriste, pri istoj ili manjoj propusnosti od commodity platformi.
2. Sve podatke zadržala unutar EU perimetra operatora — Hetzner Frankfurt, bez usmjeravanja kroz treće strane, bez analitike, bez rudarenja podataka.
3. Biometrijske podatke (face mesh oznake pod GDPR člankom 9) tretirala zakonito — eksplicitni pristanak, ograničenje svrhe, disciplina čuvanja i stvaran put do prava na brisanje.
4. Ostala podalje od visokorizične klasifikacije EU AI Acta za sustave prepoznavanja emocija — i jer je regulatorni teret enorman i jer klinička evidencija ne podržava pouzdanu inferenciju emocija iz izraza lica.
5. Bila operabilna od strane malog tima na commodity Hetzner hardveru, s troškovnom omotnicom dimenzioniranom za dugu ekspanzijsku stazu prije prvog događaja skaliranja.

## Pristup — "Klijent radi, server prosljeđuje"

Organizacijsko načelo arhitekture jest da sva inteligencija — ekstrakcija face mesha, smanjenje šuma, ROI kodiranje, simulcast kodiranje, adaptivna brzina sličica, omekšavanje pozadine — radi na klijentskom uređaju. Server je inteligentni preklopnik koji prima pakete i prosljeđuje ih.

Praktične posljedice:

- CPU servera ostaje ispod 15% čak i pri punom kapacitetu. Usko grlo je propusnost, ne računanje.
- Tehnologija servera može se birati prema pouzdanosti i operativnoj jednostavnosti, ne prema sirovoj izvedbi. Klijentska tehnologija može se birati prema kvaliteti audio i video obrade na uređaju koji korisnik već posjeduje.
- Dodavanje ML-a na rubu (face mesh, smanjenje šuma, ROI kodiranje) ne košta operatora nikakvo po-sesijsko serversko računanje. Marginalni trošak veće kvalitete je nula.

Odabrani stack:

- **Server**: open-source SFU + signaling + TURN kombinacija u jednom Go binaryju. Business API u Gou. PostgreSQL za relacijsko stanje; Redis za prisutnost i ograničavanje brzine; MinIO za enkriptirane segmente snimaka; HashiCorp Vault za po-sesijske ključeve; Keycloak za autentikaciju (OIDC + SAML + MFA, s LDAP / AD federacijom za bolničke integracije).
- **Klijenti**: nativno iOS (Swift + ARKit-ovih 52 blendshapeova, hardverski ubrzano praćenje lica na uređajima s TrueDepth kamerom), nativno Android (Kotlin + ML Kitove 468 točaka kroz raspon uređaja) i Web klijent (SvelteKit + MediaPipe Face Mesh, 468 točaka pri 30 fps u WASM-u).
- **Audio**: Opus pri 48 kHz, 96 kbps — tri puta Zoomov default. Čuva tonalnost, dah, pauze i drhtaj glasa.
- **Video**: H.264 High Profile pri 720p, simulcast u tri sloja (720p / 360p / 180p) za graceful degradaciju bez transkodiranja na strani servera.
- **Edge poboljšanje zvuka**: open-source DNN-temeljen cjevovod za smanjenje šuma i dezreverberaciju, full-band pri 48 kHz, MIT licenciran.

## Arhitektonske odluke koje su važne

### ROI kodiranje — 2,5× oštrije lice pri istoj ukupnoj propusnosti

Standardni video alocira bitove ravnomjerno kroz frame. 60–70% propusnosti ide pozadini (zidovi, police, biljke). Lice — jedina klinički relevantna regija — dobiva 30–40%.

ROI kodiranje platforme obrće tu alokaciju. Detekcija lica (već se izvodi on-device za face mesh) identificira bounding-box lica; pozadinska regija dobiva blagi Gaussov blur (radijus 2–3 piksela, ne puni blur); H.264 enkoder automatski alocira više bitova oštrim regijama i manje zamućenim. Ukupna propusnost ostaje 2,0 Mbps — ali lice dobiva otprilike 2,5× više bitova nego pod ravnomjernom alokacijom.

Rezultat: mikro-izrazi su dramatično jasniji. Implementacija je u potpunosti na strani klijenta — nula troška servera. iOS koristi Metal GPU shadere protiv TrueDepth dubinskih podataka; Android koristi ML Kit Selfie Segmentation s Vulkan / RenderScript putom blura; Web koristi MediaPipe segmentaciju s WebGL shaderom.

### Adaptivna brzina sličica vođena Voice Activity Detectionom

Zoom i Teams šalju konstantnih 30 fps neovisno o sadržaju. Platforma čita Opusov ugrađeni signal Voice Activity Detectiona: kad sudionik sluša (tiho više od dvije sekunde), brzina sličica pada na 10–15 fps; kad počne govoriti, vraća se na 30 fps u roku od 100 ms. Za tipičnu 50-minutnu konzultaciju, prosječna brzina sličica iznosi oko 22 fps. Nepomični sudionik pri 10 fps izgleda identično 30 fps jer H.264 već komprimira identične sličice na gotovo nulti delta — uštede dolaze od neenkodiranja-i-neprenošenja redundancije od početka.

### Kompozitno snimanje — bolji klinički sadržaj u polovici pohrane

Mainstream platforme snimaju puni video pri ujednačenoj kvaliteti. Svaka sličica zida iza tihog pacijenta dobiva isti budžet bitova kao trenutak emocionalne reakcije. Platforma snima i puni video i face mesh, a zatim po segmentu odlučuje koji artefakt zadržati:

- **Segmenti visoke aktivnosti** (emocionalne reakcije, geste, glasovni intenzitet): sačuvaj puni H.264 video u punoj kvaliteti.
- **Segmenti niske aktivnosti** (slušanje, stabilno držanje): zadrži samo face mesh oznake plus puni audio.

Klasifikacija aktivnosti temelji se na magnitudi pokreta, ne na emociji: delta od 468 face mesh točaka između uzastopnih sličica, normaliziran veličinom bounding-boxa lica, s EMA glađenjem i histerezom. Audio se uvijek čuva u punoj kvaliteti neovisno o klasifikaciji segmenta, pa se tiho plakanje hvata u potpunosti čak i kad je pokret nizak. Kliničari mogu i ručno označiti trenutke, što prisiljava punu video-pohranu neovisno o klasifikaciji pokreta.

Rezultat pohrane: otprilike 50% manje od mainstream platformi, s **boljim** kliničkim sadržajem (trenuci visoke aktivnosti dobivaju veći udio budžeta pohrane). Reprodukcija podržava tri stila avatara za segmente s meshom — wireframe, neutralni geometrijski, low-poly stilizirani — svaki čuva klinički signal (mikro-izrazi, smjer pogleda, tempo pokreta, simetrija izraza), bez prikazivanja izgleda pacijenta.

### Biometrijski podaci, GDPR članak 9 i namjerno nekorištenje prepoznavanja emocija

Face mesh oznake su biometrijski podaci pod GDPR člankom 9. Iz 468 pozicija oznaka osoba se može jedinstveno identificirati (faceprint). To pokreće specifičan skup obveza: eksplicitan pristanak posebno za pohranu face mesha (ne generički "pristanak na snimanje"), definiranu svrhu, minimizaciju podataka, definirano razdoblje čuvanja i stvaran put do prava na brisanje. Platforma sve to implementira — uključujući **crypto-shredding** (brisanje po-sesijskog AES-256-GCM ključa iz HashiCorp Vaulta čini snimku kriptografski neoporavljivom, ispunjavajući pravo na brisanje u manje od 24 sata).

Teža je odluka bila što učiniti s face meshom jednom kada je uhvaćen. **EU AI Act (članak 5(1)(f), na snazi od 2. veljače 2025.)** zabranjuje prepoznavanje emocija u kontekstima rada i obrazovanja — ali izričito ga dopušta za medicinske svrhe kroz usku iznimku. Iskušenje, posebno za platformu marketinški usmjerenu kliničarima, jest iskoristiti medicinsku iznimku i graditi klasifikaciju emocija povrh mesha.

Platforma to ne radi. Dva razloga.

Prvo: klinička evidencija ne podržava pouzdanu inferenciju emocija iz izraza lica. Ekmanov framework "univerzalnih emocija" / Facial Action Coding System — osnova svakog komercijalnog proizvoda za prepoznavanje emocija — predmet je nepovoljne meta-analize iz 2019. preko tisuću studija Lise Feldman Barrett i kolega. Ista osoba, istu emociju izražava drugačije u različitim kontekstima; različite kulture različito kodiraju izraz; u kliničkim okruženjima posebno, pacijenti koji maskiraju smijeh ili sjede ravnog lica kroz intenzivan distres su rutina. Kliničar čita kontekst, ne samo izraz; sustav inferencije ne može.

Drugo: čak i tamo gdje je prepoznavanje emocija dopušteno pod medicinskom iznimkom, klasifikacija pokreće visokorizičnu kategoriju EU AI Acta (**Aneks III**) i pripadajuće zahtjeve za ocjenu sukladnosti, sustav upravljanja kvalitetom, dokumentaciju (deset godina čuvanja), ljudski nadzor, robusnost, točnost i registraciju u EU AI bazu podataka. Regulatorni teret je enorman; gornja granica kazne je €35 milijuna ili 7% globalnog godišnjeg prometa.

Platforma stoga mjeri **pokret** — magnitudu delte oznaka između sličica — a ne emociju. Pokret je klinički koristan signal (vodi odluku o kvaliteti snimanja i isticanje oznaka), ali ne nosi nikakvu inferenciju o psihološkom stanju. Nema oznaka emocija, nema vrijednosti pouzdanosti, nema vremenskih grafova emocija. Sustav nikada ne kaže kliničaru što pacijent osjeća.

### Sigurnosna omotnica

- **Transport**: DTLS-SRTP za sve WebRTC medije (obavezni WebRTC base-line); WSS za signaling; HTTPS s TLS 1.3 za API. Faza 2 uvodi SFrame end-to-end enkripciju — čak i server vidi samo enkriptirane medijske frameove.
- **Snimanje at-rest**: AES-256-GCM s po-sesijskim ključevima iz HashiCorp Vaulta. Ključ nikada ne napušta Vault; Vaultov Transit engine izvodi operacije enkripcije / dekripcije. Brisanje ključa (crypto-shredding) čini snimku neoporavljivom.
- **Autentikacija**: Keycloak self-hosted, OIDC + SAML, MFA (TOTP i WebAuthn / FIDO2 hardverski ključevi za kliničare), LDAP / AD federacija za bolničke sustave.
- **Audit trag**: append-only, hash-vezan, otporan na manipulaciju. Svaka akcija logirana (login, kreiranje / pridruživanje / napuštanje sobe, dani / promijenjeni pristanak, start / stop snimanja, pristup podacima, brisanje podataka). Nema PHI u audit tragu — samo ID-evi, akcije, vremenski pečati. Čuvanje deset godina.

### Troškovno inženjerstvo — skaliranje odgođeno 6–12 mjeseci

Kombinacija **P2P-kad-snimanje-nije-potrebno** (oko 40% sesija), **smart silencea** (strana koja sluša pada na 10 fps pri 0,4 Mbps), **adaptivne brzine sličica** i **odgođenog snimanja** (formalni snimljeni dio obuhvaća samo klinički relevantni središnji dio sesije, s P2P-om za small talk prije i terminiranje nakon) podiže kapacitet konkurentnih sesija jedne €52 / mjesečne Hetzner kutije s baseline-a od ~145 na otprilike **~280**. Drugi server potreban je pri ~280 konkurentnih sesija umjesto pri ~145 — događaj skaliranja pomiče se 6–12 mjeseci dalje.

## Ishod

Isporuka je bila arhitektonska specifikacija spremna za staged implementaciju, s tehnološkim odabirima opravdanima na razini koju regulator ili prijavljeno tijelo mogu auditirati:

- Edge-ML medijski cjevovod koji isporučuje mjerljivo bolji klinički signal od commodity video konferencija pri istoj propusnosti.
- Pristup kompozitnog snimanja koji proizvodi više klinički korisnih artefakata u manje pohrane, bez ikakve inferencije o psihološkom stanju.
- Obranjiva pozicija o EU AI Actu: platforma ne provodi prepoznavanje emocija, a izbor je dokumentiran s referencom i na regulatornu analizu (članak 5(1)(f), Aneks III) i na bazu kliničke evidencije (Lisa Feldman Barrett 2019.).
- Troškovna omotnica dimenzionirana za plan ekspanzije operatora, sa sljedećim događajem skaliranja odgođenim 6–12 mjeseci u odnosu na naivnu implementaciju.

## Što rad nije proizveo

Produkcijski kod. Live deployment. Kliničku studiju. Formalnu ocjenu sukladnosti pod MDR-om. Rad je bio dizajn arhitekture, odabir tehnologije i regulatorna analiza ispod toga — supstrat na kojem implementacija počiva, ne sama implementacija.

## Oblik rada

Sole-architect mandat kroz komprimiran prozor pisanja. Primarni dizajn dokument od ~64 stranice s pratećim memorandumom o tehnološkom krajoliku. Materijali proizvedeni kao strukturiran workbook u željenom formatu operatora. Cijelo vrijeme povjerljivo; ova stranica je jedina anonimizirana referenca.
