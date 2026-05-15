---
title: "Spremnost za Cyber Resilience Act za EU proizvođača povezanih proizvoda"
sector: "EU proizvođač povezanih proizvoda"
engagementType: "Primijenjena pripremna radnja · anonimizirana interna referenca"
year: "2026"
region: "Europska unija"
summary: "Primijenjena pripremna radnja za CRA Cliff 1 (rujan 2026.) za EU proizvođača-operatora povezanih proizvoda. Otprilike 240 stranica audit-obranjive evidencije kroz 13 dokumenata — checkliste, briefinzi, runbook za Članak 14, RACI, plan izvršenja — usidreno u petostrukoj doslovnoj provjeri Službenog lista. Objavljeno kao metodološka referenca; klijent neidentificiran."
quickRead: |
  **Početna pozicija: slaba, ali još ne u kršenju.** Bez SBOM-a. Bez inventara firmwarea. Bez runbooka za članak 14. U inženjerskom timu nema dediciranog kadra za kibernetičku sigurnost.

  **Rokovi se ne pomiču.**

  EU proizvođač-operator povezanih proizvoda suočio se s CRA Cliff 1 (11. rujna 2026.) s klasičnim složenim problemom: hibridna regulatorna pozicija (proizvođač u CRA smislu za vlastiti softverski stog, operator/distributer za hardver dobavljača koji integrira), njemačka transpozicija NIS2 dodatno preko toga (BSIG-neu, na snazi od 6. prosinca 2025., s vlastitim rokovima prema § 32), te kaskada odgovornosti u opskrbnom lancu iz NIS2 članka 21. stavka 2.

  Metodološko sidro: **petostruka doslovna verifikacija** prema tekstu Službenog lista za Uredbu EU 2024/2847, Direktivu (EU) 2022/2555 NIS2 i njemački BSIG-neu. Svaka nosiva tvrdnja citirana; svaki nalaz označen statusom verifikacije; svaki dokument povezan u matricu unakrsnih referenci koja funkcionira kao interni revizijski trag.

  Tri dokumenta nose težinu angažmana: **Runbook za članak 14. / § 32 BSIG** s četiri unaprijed pripremljena predloška obavijesti (24h / 72h / 14d / 30d), prioritizacija **First 30 Days Alone** za jednog inženjera, te **Executive Briefing** za odobrenje uprave. Oko njih približno 240 stranica revizijski obranjivih dokaza — kontrolne liste, gap analiza, plan izvršenja tjedan po tjedan, RACI, Operatorski playbook.

  Do Cliffa 1, operator može ovaj paket dokaza predstaviti ovlaštenom tijelu ili regulatoru bez praznina u pripremi. *Slaba, ali još ne u kršenju* dobiva dokumentirani put do *revizijski obranjivo*.
publishedAt: "2026-05-09"
featured: true
---

> **Bilješka o uokviravanju.** Ova stranica opisuje korpus interne pripremne radnje, anonimiziran i objavljen kao metodološka referenca. Nije plaćeni vanjski mandat. Vrijede ista pravila anonimizacije: nema identifikacije klijenta, nema citiranog teksta, samo deskriptor sektora.

## Kontekst

EU Cyber Resilience Act (Uredba 2024/2847) nameće obveze svakom ekonomskom operatoru koji stavlja proizvode s digitalnim elementima na tržište EU. Gore navedeni datumi cliffa postavljaju operativne rokove; službeni raspored implementacije i zahtjevi za standardizaciju praćeni su na [stranici Europske komisije o implementaciji CRA-a](https://digital-strategy.ec.europa.eu/en/factpages/cyber-resilience-act-implementation). Ono što ovaj mandat čini netrivijalnim jest regulatorna geometrija organizacije ispod tih datuma.

Organizacija u ovom korpusu nosila je hibridnu regulatornu poziciju: **proizvođač** u CRA smislu za svoj vlastiti softverski stack (rub runtime, container slike, cloud back-office, mobilna aplikacija), **operator/distributer** za hardver dobavljača koji integrira. Sloj iznad: njemačka nacionalna transpozicija NIS2 (BSIG-neu, na snazi 6. prosinca 2025.) stvorila je paralelnu obvezu prijavljivanja kao (posebno) značajan subjekt, s vlastitim satovima prema § 32. Kaskada prema klijentu uvela je odgovornost opskrbnog lanca iz Članka 21(2) NIS2.

Početna pozicija: slabo, ali još ne u prekršaju. Bez SBOM-a. Bez inventara firmvera. Bez dokumentiranog obrazloženja razdoblja podrške. Bez runbooka za Članak 14. VPN/SSH operacije bez per-korisničke atribucije. Bez dokaznih paketa dobavljača. Tvrdo brisanje zbunjeno sa sigurnosno-audit pohranjivanjem. Izloženost legacy certifikata za jednu obitelj proizvoda. Naslijeđena lokacija koja radi kao crna kutija iz prethodne migracije klijenta.

Inženjerski tim nije imao dediciranu cybersecurity poziciju. Rokovi se ne pomiču.

## Pristup

Rad je od prvog dana zauzeo namjerno rigoroznu poziciju: svaka noseća tvrdnja bila bi citirana na tekst Službenog lista ili na interpretativni dokument EU Komisije, svaki nalaz označen statusom provjere, svaki dokument propagiran kroz matricu unakrsnih referenci koja funkcionira kao interni audit trag. Metodološke obveze bile su:

- **Petostruka doslovna provjera** prema EU Uredbi 2024/2847 (Članci 13, 14, 16, 22, 28, 31, 64, 69; Aneks I Dijelovi I i II; Aneks II; Aneks III; Aneks VII), Direktivi (EU) 2022/2555 NIS2 i njemačkom BSIG-neu (§§ 30, 32, 33, 38, 65). Zaseban dodatak citata nosi doslovni regulatorni tekst za svaku Cliff-1 isporuku, dizajniran da preživi neprijateljski review sastanak redak po redak.
- **Dodatak "Position of Record"** koji bilježi autoritativne tvrdnje s njihovim dokaznim lancem, odvojiv od operativnih dokumenata koji o njima ovise.
- **Konsolidirani katalog 32 nalaza** klasificiran L (zakonski potrebno) / I (implicirano sredstvo) / B (najbolja praksa), praćen kroz 24 nizvodna dokumenta s po-dokumentnim statusom propagacije (DONE / PENDING / FROZEN / OPTIONAL).
- **Disciplina otvorenih pitanja**: svaka tvrdnja koja čeka vanjsko potvrđivanje (odgovor PSIRT-a dobavljača, pojašnjenje regulatora, imenovanje prijavljenog tijela) označena je kao OPEN, s dokumentom koji je drži eksplicitno bilježeći čekanje.

## Što je rad proizveo

Otprilike 240 stranica audit-obranjive evidencije kroz trinaest primarnih dokumenata:

- **Glavna checklista sukladnosti** — konsolidirani registar obveza kroz jedanaest tematskih odjeljaka (opseg, inventar, legacy certifikati, audit/logiranje, postupanje s ranjivostima, sigurni update + razdoblje podrške + Aneks II, izvještavanje po Članku 14, sigurnost ruba, nabava/dokazi dobavljača, ocjena sukladnosti, GDPR/NIS2 usklađenost). Svaki redak: izjava o jazu, zašto-je-važno vezano uz specifični Aneks/Članak, ozbiljnost (Critical / High), pod-stavke s kvačicama.
- **Audit-spremnost duboko zaranjanje** — pratitelj provjere primarnih izvora koji testira svaku noseću tvrdnju, plus 90-dnevni plan izvršenja.
- **Vremenski raspored izvršenja** — tjedan-po-tjedan do Cliffa 1, mjesečno do Cliffa 2, organiziran u sedam faza kroz deset traka integracije.
- **Gap analiza / procedure / nabava** — petnaest imenovanih scenarija prijetnji, inventar politika/procedura iz trinaest odjeljaka, dvadeset kategorija alata, osam kategorija vanjskih usluga.
- **Research update** — osvježenje sigurnosne pozicije dobavljač-po-dobavljač, status CRA provedbenih akata, ažuriranje njemačke transpozicije NIS2, pozicioniranje EUCC sheme, identifikacija legacy certifikata.
- **Prvih 30 dana sami** — prioritizacija s preglašavanjem za pojedinog inženjera, osam must-exist dokumenata, 30-dnevni plan, predložak memoranduma upravi, predložak potpisne stranice koji traži kadrovske opcije A/B/C.
- **Executive briefing** (16-slajdovni deck) — okrenut prema upravi, usidren na tri broja: dani do cliffa, gornja granica kazne, FTE realnost. Infografika sata izvještavanja, 13-tjedna roadmap, opcije odluka.
- **Tech coordination deck** (~19 slajdova) — pratitelj okrenut prema CTO-u. Dijeli estate na rub-ožičeni nasuprot cloud-API integracijskih načina, dodjeljuje šest internih timova, tri vanjske strane, plus Geschäftsführung.
- **Runbook za Članak 14 / § 32 BSIG** — operativni runbook s doslovnim regulatornim tekstom, četiri unaprijed sastavljena predloška obavijesti (24h rano upozorenje, 72h obavijest, 14d konačno o ranjivosti, 30d konačno o incidentu), predložak komunikacije s klijentima, postupak uvođenja u ENISA-inu Single Reporting Platformu.
- **RACI matrica** — jednostrana matrica odgovornosti koja pokriva ~25 cybersecurity i CRA/NIS2 funkcija; popunjena pravim imenima, korištena kao dokaz koncentracije na jednu osobu u R stupcu.
- **Dodatak konsolidiranih nalaza** — tragar 32-nalaza × 24-dokumenta propagacije.
- **Operator's Playbook** — trostupni vodič za vođenje za ruku, najlakša-poluga-prvo poredan; za svaku stavku: što, gdje živi, što mora sadržavati, tko potpisuje, gdje se pohranjuje, procjena truda, zadovoljeni citat.
- **README / Index** — Confluence topologija, konvencija numeriranja stranica, status baneri (DRAFT / APPROVED / EFFECTIVE / SUPERSEDED), mapa dokumenata.

## Mapirana rizična površina

Petnaest imenovanih scenarija prijetnji u gap analizi:

- bijeg kontejnera na rubu
- fizički napad na nenadziran rubni uređaj
- NFC relay protiv integracije mobilnih vjerodajnica
- kompromitacija SSH ključa koja se propagira kroz flotu
- nepoznata ranjivost na naslijeđenoj lokaciji
- kompromitacija opskrbnog lanca Docker base slike
- kompromitacija središnjeg backenda koja se propagira na on-prem
- replay / vremenski drift
- kloniranje beskontaktnih vjerodajnica
- kompromitacija cloud dobavljača koja se vraća
- insider kroz povlašteni inženjerski pristup
- reverse engineering mobilne aplikacije
- kompromitacija na strani klijenta koja se propagira na integratora
- denial-of-service protiv središnje sinkronizacije whitelist-e
- NIS2 odgovornost kaskade opskrbnog lanca

Dvadeset pet do dvadeset devet unosa u registru rizika, bodovano na modelu 5×5 (vidljivi bodovi 25, 20, 16, 15). Backlog alata obuhvaća dvadeset kategorija — SBOM, SAST, DAST, skeniranje slika, skeniranje tajni, potpisivanje slika, runtime sigurnost, PAM / snimanje sesija, EDR na rubu, SIEM, upravljanje ranjivostima, upravljanje zakrpama, tajne / vjerodajnice, PKI / upravljanje certifikatima, HSM, potpisivanje koda, backup / DR, GRC, threat-intel.

## Ishod

Rad je isporučio obranjivi pozicijski paket, ne izjavu o problemu. Konkretno:

- Briefing čitljiv upravi koji destilira cijelu poziciju na tri broja i tri kadrovske opcije.
- Registar sukladnosti redak po redak koji regulator i prijavljeno tijelo mogu auditirati.
- Operativni runbook za izvještavanje po Članku 14 koji radi bez daljnjeg dizajnerskog rada — uključujući unaprijed sastavljeni tekst obavijesti za svaki sat.
- Matricu odgovornosti koja demonstrira realnost koncentracije osoblja (te time da je eskalacija prema upravi za kadrovske odluke sama po sebi dokumentirana kontrola).
- Plan izvršenja s eksplicitnim vratima vanjske validacije (imenovanje prijavljenog tijela, dokazni paketi dobavljača, pisani odgovori regulatora) gdje se rad ne može jednostrano unaprijediti.

Neto efekt: do Cliffa 1 (11. rujna 2026.) operator može predstaviti ovaj paket dokaza prijavljenom tijelu ili regulatoru bez pripremnih praznina, a odluka o kadrovskim resursima sjedi na stolu uprave kao eksplicitni poziv na razini odbora, a ne kao defaultna postavka inženjerskog tima. Početna pozicija "slabo-ali-još-ne-u-prekršaju" ima dokumentirani put prema "audit-obranjivoj".

## Što rad nije proizveo

Nismo implementirali kontrole. Nismo pisali kod. Nismo komunicirali s prijavljenim tijelima ili regulatorima u ime nikoga. Nismo isporučili ISO 27001 certifikaciju ili EUCC certifikat. Nismo izgradili SBOM cijev ili PSIRT poštanski sandučić. Output je bio paket spremnosti razine dokaza — pozicija s koje može započeti kadrovski popunjena implementacija bez ponovnog raspravljanja temelja.

## Oblik rada

Single-autor intenzivno: oko 240 stranica proizvedenih kroz trinaest primarnih dokumenata i četiri dodatka. Prednjavajuće u komprimirani prozor pisanja, s daljnjim izvršenjem opsegovano kroz otprilike devetnaest mjeseci do Cliffa 2. Companion-document arhitektura kroz cijeli korpus — svaka isporuka eksplicitno opisuje kako preglašava ili nadopunjuje ostale. Cijelo vrijeme povjerljivo; nema proizvedenih javnih materijala osim ove anonimizirane metodološke reference.
