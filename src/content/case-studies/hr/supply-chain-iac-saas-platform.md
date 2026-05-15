---
title: "Kontrole softverskog opskrbnog lanca i spas platformske IaC za multi-tenant SaaS pružatelja"
sector: "Multi-tenant SaaS pružatelj"
engagementType: "Primijenjena platformsko-inženjerska radnja · anonimizirana interna referenca"
year: "2024"
region: "Europska unija"
summary: "Rekonstruiran end-to-end IaC stack na bazi Ansible/Semaphore star pet godina kroz četiri repozitorija — orkestracijski playbookovi, produkcijski nginx reverse proxy, PostgreSQL container, feature branch analitičkog stacka. Osmišljen i isporučen sloj softverskog opskrbnog lanca s ulaznim vratima (Composer/Satis, npm/Verdaccio, SQL/Redgate, kontejneri/GitLab Registry) — svaki paket prolazi statičku analizu, skeniranje ranjivosti i odobrenje prije nego što developer može uopće riješiti ovisnost. Otprilike 30% mandata; implementirano 2024., dvije godine prije CRA Cliffa 2 (11. prosinca 2027.) kada SBOM i integritet opskrbnog lanca postaju regulatorna obveza diljem EU-a."
quickRead: |
  **Implementirano 2024. — dvije godine prije nego što CRA Cliff 2 (prosinac 2027.) integritet opskrbnog lanca pretvori u regulatornu obvezu diljem EU-a.** Obrazac se izravno preslikava na SOUP kontrole EN/IEC 62304, NIS2 članak 21. i CRA Annex I — režim opskrbnog lanca koji regulatori sada zahtijevaju da proizvođači dokažu.

  Multi-tenant SaaS operator na Hetzner Cloudu trebao je tri stvari odjednom: pet godina star Ansible/Semaphore IaC stog cjelovito obnovljen, internu razinu softverskog opskrbnog lanca (PHP iz javnog Packagista, JavaScript iz javnog npm-a, SQL artefakti s ad-hoc razvojnih strojeva — bez interne korjenske točke povjerenja, bez pred-integracijskog evaluacijskog vrata) i analitički stog (Metabase + Grafana na vlastitim VM-ovima, povezane u istu PKI kao ostatak platforme).

  Kroz četiri međupovezana repozitorija — orchestration / IaC, produkcijski nginx reverse proxy, PostgreSQL kontejner, feature-grana analitičkog stoga — približno 178 commitova vratilo je platformu u rad od kraja do kraja.

  Prepoznatljiv dio — otprilike 30 % angažmana — bila su **četverostruka pred-integracijska vrata** za svaki kanal artefakta: razvojni programer traži paket → statička analiza (skeniranje sastava, popis licenci, signal na razini koda) → skeniranje ranjivosti prema CVE / GHSA / OSV → odobrenje i zrcaljenje u interni registar (Satis za Composer, Verdaccio za npm, Redgate SQL Source Control za promjene sheme, GitLab Container Registry za slike).

  **Nijedna putanja resolvera ne zaobilazi interni registar.** To je arhitektonska tvrdnja koju kupci i regulatori pamte.
publishedAt: "2026-05-13"
featured: true
---

> **Bilješka o uokviravanju.** Ova stranica opisuje izvedbeni rad isporučen multi-tenant SaaS operatoru, anonimiziran i objavljen kao metodološka referenca. Nema identifikacije klijenta, nema imena tenanata, samo deskriptor sektora. Rad prethodi trenutnoj savjetodavnoj formi fiksnog opsega Thinking Machinea i uključen je na stranicu studija slučaja jer informira tri današnje trake: cyber otpornost (opskrbni lanac), AI integraciju (temeljni IaC obrazac) i operativnu realnost dokaznih paketa NIS2 / CRA.

## Kontekst

Operator je vodio multi-tenant SaaS platformu na Hetzner Cloudu, organiziranu oko master/tenant arhitekture: središnji Semaphore UI orkestrira Ansible playbookove protiv on-demand developerskih i klijentskih VM-ova. Platforma je bila izgrađena pet do šest godina ranije od inženjera koji su otad otišli. IaC je strukturno bila čvrsta, ali više nije radila end-to-end. Dokumentacija je zaostajala za kodom, automatizacija Semaphore API-ja se odvojila od pokrenute verzije, a nekoliko komponenti control planea (BIND9 datoteke zona, OpenVPN klijent-provizioniranje, docker-login prema GitLab Container Registryju) tiho je degradiralo.

Sloj iznad, operator je trebao tri dopune:

1. **Sloj softverskog opskrbnog lanca.** Platforma je konzumirala PHP pakete s javnog Packagista, JavaScript pakete s javnog npm-a i SQL artefakte s ad-hoc developerskih strojeva. Nije bilo internog korijena povjerenja ni evaluacijskih vrata prije integracije. Container slike već su dolazile iz GitLab Container Registryja, ali tok vjerodajnica bio je krhak.
2. **Analitički stack.** Metabase za BI nad tenant podacima; Grafana za operativne metrike. Svaki na svojem Hetzner VM-u, povezan na istu DNS zonu i PKI kao ostatak platforme.
3. **Poboljšanja otpornosti pri provizioniranju.** Idempotentno stvaranje korisnika, bez prskanja SSH ključeva kroz klijentske VM-ove i radni put docker-login-a za container registry.

Tim nije imao dediciranog platformskog inženjera. Rad je morao sletjeti prije nego što proširenje klijenata stavi teret na postojeće tokove.

## Pristup

Početni potez bio je natjerati postojeći stack da ponovno radi end-to-end iz hladnog čitanja naslijeđenog koda. Bez greenfield prepisivanja — strukturno čvrsti dijelovi bili su spasivi, trošak potpune ponovne izrade neekonomičan. Radno znanje rekonstruirano je iz postojećeg Ansible orkestracijskog repozitorija, strukture inventara (`group_vars`, `host_vars`, `playbooks`, `tasks`, `roles`, `templates`), definicija Semaphore predložaka i toka docker-login-a prema GitLab Container Registryju, a zatim svaki put uvježban stvarnim provizioniranjima prema Hetzneru.

Mandat je obuhvatio **četiri međusobno povezana repozitorija**, s otprilike sto sedamdeset osam commitova kao vidljivim tragom:

- **Orkestracijski / IaC repozitorij** (~85 commitova) — Ansible playbookovi, konfiguracija Semaphore projekta, lanac provizioniranja po-tenant VM-ova. Vidljivo u tragu kao male, inkrementalne, debugging-razinske poruke — potpis iterativnog rada protiv klimavog vanjskog API-ja i lanca provizioniranja više VM-ova. Klasteri: integracija Semaphore API-ja (neslaganja oblika JSON niz-vs-objekt, idempotentno stvaranje korisnika, debug 400-pri-stvaranju-korisnika), higijena SSH ključeva (developerski ključevi tiho su se propagirali na svaki provisionirani VM — popravak uklanja taj put i dokumentira zašto je promjena strukturna a ne kozmetička), docker-login prema GitLab Container Registryju (dva odvojena login toka brkala su se — popravak ih razdvaja i izlaže vjerodajnice kroz Makefile cilj s provjerljivim login korakom prije bilo kakvog povlačenja slike), lifecycle certifikata (wildcard certifikat za internu TLD, po-VM developerski certifikati, lanac povjerenja internog CA).
- **Produkcijski nginx reverse-proxy repozitorij** (~67 commitova) — TLS-terminirajući rub ispred internih analitičkih alata (Grafana, Metabase, Redash). Rad se koncentrirao na WebSocket podršku za Grafanine real-time dashboarde, po-servis auth usmjeravanje (neki servisi ne trebaju auth na internoj mreži), prilagođene stranice grešaka, popravke redirect loopova i rubne slučajeve PWA usmjeravanja. **Označeno za produkciju kroz više objavljenih verzija**, što znači da su se promjene postavljale na stvaran perimetar prema klijentu, a ne u sandbox.
- **PostgreSQL container repozitorij** (~20 commitova) — rad na base imageu baze podataka. Rekurirajuća tema bila je natjerati Postgresove logove da pouzdano prelaze granice kontejnera — vlasništvo log datoteka kroz korisnike i grupe, provizioniranje `postgresql.conf` pri build-vremenu kontejnera, log datoteke koje moraju biti čitljive od sestrinskih kontejnera, te mali ali stvaran DBA-strani alatni lanac.
- **Feature branch analitičkog stacka** (~6 commitova) — radna kopija korištena za razvoj provizioniranja Metabase/Grafana VPS-a prije nego što se mergeala u glavni orkestracijski repozitorij. Commitovi dokumentiraju integracijsko debugiranje — povezivanje Metabase preko interne firewall-a s Postgresom hostanim na GitLabu — koje se ne pojavljuje u javnom commit logu konačnog mergeanog playbooka.

## Sloj softverskog opskrbnog lanca

Otprilike 30% mandata bilo je koncentrirano ovdje. Cilj je bio operativno jednostavan i regulatorno značajan: **nijedan paket treće strane ne dolazi do tenant builda bez dokumentirane evaluacije prije integracije** prema cyber-sigurnosnim kontrolama koje su sada kodificirane kroz EU regulativu za medicinski softver, NIS2 opskrbni lanac i obveze proizvođača iz CRA.

Arhitektura je workflow, ne samo statička lista registrija. Svaki kanal artefakata koji je platforma konzumirala — PHP paketi preko Composera, JavaScript paketi preko npm-a, SQL promjene sheme, container slike — prolazio je kroz ista četverostruka ulazna vrata prije nego što ih je developer mogao riješiti:

1. **Zahtjev.** Developer traži novi paket treće strane, navodeći ime, traženu verziju i namjenu unutar tenant builda.
2. **Statička analiza.** Kandidatski paket povlači se u izolirani runner. Composition skeniranje pobrojava tranzitne ovisnosti i inventar licenci. Inventar licenci uspoređuje se s operatorovom listom dopuštenih licenci. Signali na razini koda pregledavaju se na očite nesigurne uzorke (`eval`, dinamičko izvršavanje, shell-out, build-time post-install hookove koji dosežu mrežu).
3. **Analiza ranjivosti.** Kandidatski paket i svaka tranzitna ovisnost pretražuju se u CVE / GHSA / OSV bazama na traženoj verziji. Paketi s poznatim nezakrpanim i iskoristivim ranjivostima odbijaju se odmah; paketi s zakrpanim ranjivostima u višoj verziji odobravaju se u zakrpanoj verziji, ne u traženoj, uz prilagođen `composer.json` ili `package.json`.
4. **Odobrenje i ogledavanje.** Ako paket prođe oba vrata, ogleda se u internom registriju — **Satis za Composer**, **Verdaccio za npm** — u odobrenoj verziji, s evaluacijskim zapisom pohranjenim uz binar. Tek tada `composer require` ili `npm install` developera može riješiti paket. Ne postoji resolver put koji zaobilazi interni registar.

Isti oblik primjenjivao se na **SQL artefakte sheme** kroz Redgate SQL Compare i Source Control — svaka promjena sheme postaje pregledivi diff s imenovanim odobravateljem prije nego što može doći do tenant baze — i na **container slike** kroz GitLab Container Registry kao jedini ovlašteni izvor slika za tenant VM-ove, s docker-login tokom kao provjerljivim login korakom prije bilo kakvog povlačenja slike u Ansible playbooku.

Obrazac se izravno preslikava na regulatorni krajolik koji je naknadno kodificirao ono što je već bilo isporučeno:

- **EN / IEC 62304 § 5.1.5 i § 8.1** — identifikacija SOUP (softver nepoznatog podrijetla) i pregled anomalija. Svaki element treće strane nosi svoj inventarski zapis, predviđenu uporabu i pregled poznatih ranjivosti u verziji koja se zapravo konzumira.
- **MDCG 2019-16** — zahtjev iz EU MDR smjernica za cybersigurnost da se provede "temeljita evaluacija komponenti trećih strana" *prije integracije* zadovoljen je operativno kroz statičku-analizu-onda-vuln-skeniranje vrata, ne kroz naknadno atestiranje.
- **IEC 81001-5-1** — sigurnosne aktivnosti za softver u zdravstvu kroz životni ciklus proizvoda. Interni-registar-kao-jedinstveni-izvor-istine čini zahtjeve za SBOM i evaluaciju dobavljača nuspojavom rada, a ne posebno održavanim artefaktom.
- **NIS2 članak 21(2)(d)** — sigurnost opskrbnog lanca za ključne i važne subjekte (zdravstveni sektor je u Aneksu I NIS2). Vrata JESU kontrola opskrbnog lanca: typosquattirani Packagist paket ne može doći do tenant builda jer nijedan resolver put ne zaobilazi interni registar.
- **CRA članak 13 i Aneks I dio II(1) i (2)** — obveze proizvođača da identificiraju komponente, proizvedu SBOM i učinkovito rješavaju ranjivosti. Cliff 2 (11. prosinca 2027.) čini ih punim obvezama diljem EU-a. Registar proizvodi SBOM kao nuspojavu; evaluacijski log je dokaz rukovanja ranjivostima.

Implementirano 2024. — dvije godine prije ranih CRA obveza izvještavanja (Cliff 1, rujan 2026.) i tri godine prije punog mandata za SBOM i identifikaciju komponenti (Cliff 2, prosinac 2027.).

## Analitički stack

Dodana su dva dodatna Hetzner VM-a — jedan za Metabase, jedan za Grafanu — svaki proviziran kroz isti Ansible/Semaphore put koji se koristi za developerske i klijentske VM-ove. Metabase VM hosta BI alat s vlastitim PostgreSQL skladištem metapodataka i Java Keystoreom za TLS terminaciju. Grafana VM koristi isti interni CA, persistira stanje pod `/grafana` i pokreće `grafana/grafana-oss` sliku u Dockeru iza iste konvencije imenovanja DNS zone kao ostatak platforme. Oba čvora dostupna su samo unutar OpenVPN sloja; nijedan nije izložen javnom internetu. TLS-terminirajući reverse proxy ispred njih je produkcijski nginx repozitorij iznad — WebSocket podrška za Grafanin real-time, po-servis auth usmjeravanje, prilagođene 4xx/5xx stranice.

## Ishod

Platformska IaC ponovno radi end-to-end, s pokretnim dijelovima dokumentiranima (arhitektura, playbooki, uloge, workflowi) na razini koja preživi sljedeći događaj rotacije inženjera. Sloj opskrbnog lanca znači da je odgovor na pitanje *Možete li opisati kako bi typosquattirani javni paket dosegnuo proizvodnju* — "Ne može, jer je resolver put posredovan internim registrom i svaki kandidatski paket prošao je kroz statičku analizu, skeniranje ranjivosti i dokumentirano odobrenje prije nego što se može poslužiti." Analitički stack radi uz ostatak platforme bez proširenja javne napadne površine. Produkcijski reverse proxy tagiran je i objavljen kroz više verzija, što se preslikava na očekivanja "sigurnog razvoja" iz NIS2 § 21(2).

U jeziku CRA Cliffa 1 (11. rujna 2026.) i CRA Cliffa 2 (11. prosinca 2027.), ovaj korpus rada proizveo je — dvije do tri godine ranije — upravo onu vrstu dokaznog paketa o integritetu opskrbnog lanca koji uredba sada zahtijeva da proizvođači budu sposobni predstaviti regulatoru ili prijavljenom tijelu na zahtjev.

## Što rad nije proizveo

Formalnu SBOM cijev koja emitira SPDX / CycloneDX (mandat za format SBOM-a datira nakon rada; interni registar bio je izvor istine za inventar komponenti, ali izvozni format ostao je interni). Penetracijsko testiranje treće strane protiv registrija. Procjenu zaštite tenant podataka. ISO/IEC 27001 Statement of Applicability. Rad je bio operativno poboljšanje, ne atestiranje sukladnosti — ali operativna poboljšanja su supstrat na kojem atestiranje sukladnosti počiva.

## Oblik rada

Sole-principal mandat kroz nekoliko mjeseci, vodeći rad u koordinaciji s malim internim timom operatora. **Otprilike 178 commitova kroz četiri repozitorija** kao vidljiv trag: orkestracijska IaC, produkcijski nginx reverse proxy, PostgreSQL container base image i feature branch analitičkog stacka. Plus četverostruka ulazna vrata opskrbnog lanca i provizioniranje analitičkog stacka. Cijelo vrijeme povjerljivo; ova stranica je jedina anonimizirana referenca.
