---
title: "Kontrole softverskog opskrbnog lanca i spas platformske IaC za multi-tenant SaaS pružatelja"
sector: "Multi-tenant SaaS pružatelj"
engagementType: "Primijenjena platformsko-inženjerska radnja · anonimizirana interna referenca"
year: "2024"
region: "Europska unija"
summary: "Oživljen end-to-end IaC stack na bazi Ansible/Semaphore star pet godina iz rekonstrukcije kroz četiri repozitorija — orkestracijski playbookovi, produkcijski nginx reverse proxy, PostgreSQL container base image, feature branch analitičkog stacka. Dodan sloj softverskog opskrbnog lanca s internim korijenima povjerenja (Composer/Satis, npm/Verdaccio, SQL/Redgate, kontejneri/GitLab Registry) i analitički stack (Metabase + Grafana). Otprilike 30% mandata bilo je upravljanje softverskim opskrbnim lancem — izravno relevantno za obveze SBOM-a i integriteta iz CRA Članka 13 i kaskadu opskrbnog lanca iz NIS2 Članka 21(2)."
publishedAt: "2026-05-13"
featured: true
---

> **Bilješka o uokviravanju.** Ova stranica opisuje izvedbeni rad isporučen multi-tenant SaaS operatoru, anonimiziran i objavljen kao metodološka referenca. Nema identifikacije klijenta, nema imena tenanata, samo deskriptor sektora. Rad prethodi trenutnoj savjetodavnoj formi fiksnog opsega Thinking Machinea i uključen je na stranicu studija slučaja jer informira tri današnje trake: cyber otpornost (opskrbni lanac), AI integraciju (temeljni IaC obrazac) i operativnu realnost dokaznih paketa NIS2 / CRA.

## Kontekst

Operator je vodio multi-tenant SaaS platformu na Hetzner Cloudu, organiziranu oko master/tenant arhitekture: središnji Semaphore UI orkestrira Ansible playbookove protiv on-demand developerskih i klijentskih VM-ova. Platforma je bila izgrađena pet do šest godina ranije od inženjera koji su otad otišli. IaC je strukturno bila čvrsta, ali više nije radila end-to-end. Dokumentacija je zaostajala za kodom, automatizacija Semaphore API-ja se odvojila od pokrenute verzije, a nekoliko komponenti control planea (BIND9 datoteke zona, OpenVPN klijent-provizioniranje, docker-login prema GitLab Container Registryju) tiho je degradiralo.

Sloj iznad, operator je trebao tri dopune:

1. **Sloj softverskog opskrbnog lanca.** Platforma je konzumirala PHP pakete s javnog Packagista, JavaScript pakete s javnog npm-a i SQL artefakte s ad-hoc developerskih strojeva. Nije bilo internog korijena povjerenja. Container slike već su dolazile iz GitLab Container Registryja, ali tok vjerodajnica bio je krhak.
2. **Analitički stack.** Metabase za BI nad tenant podacima; Grafana za operativne metrike. Svaki na svojem Hetzner VM-u, povezan na istu DNS zonu i PKI kao ostatak platforme.
3. **Poboljšanja otpornosti pri provizioniranju.** Idempotentno stvaranje korisnika, bez prskanja SSH ključeva kroz klijentske VM-ove i radni put docker-login-a za container registry.

Tim nije imao dediciranog platformskog inženjera. Rad je morao sletjeti prije nego što proširenje klijenata stavi teret na postojeće tokove.

## Pristup

Početni potez bio je natjerati postojeći stack da ponovno radi end-to-end iz rekonstrukcije. Bez greenfield prepisivanja. Čitanje postojećeg Ansible koda u orkestracijskom repozitoriju, strukture inventara (`group_vars`, `host_vars`, `playbooks`, `tasks`, `roles`, `templates`), definicija Semaphore predložaka i toka docker-login-a prema GitLab Container Registryju, a zatim vježbanje svakog puta stvarnim provizioniranjima prema Hetzneru.

Mandat je obuhvatio **četiri međusobno povezana repozitorija**, s otprilike sto sedamdeset osam commitova kao vidljivim tragom:

- **Orkestracijski / IaC repozitorij** (~85 commitova) — Ansible playbookovi, konfiguracija Semaphore projekta, lanac provizioniranja po-tenant VM-ova. Vidljivo u tragu kao male, inkrementalne, debugging-razinske poruke — tipičan potpis rada protiv klimavog vanjskog API-ja i lanca provizioniranja više VM-ova. Klasteri: integracija Semaphore API-ja (neslaganja oblika JSON niz-vs-objekt, idempotentno stvaranje korisnika, debug 400-pri-stvaranju-korisnika), higijena SSH ključeva (developerski ključevi tiho su se propagirali na svaki provisionirani VM — popravak uklanja taj put i dokumentira zašto je promjena strukturna), docker-login prema GitLab Container Registryju (dva odvojena login toka su se brkala — popravak ih razdvaja i izlaže vjerodajnice kroz Makefile cilj s provjerljivim login korakom), lifecycle certifikata (wildcard certifikat za internu TLD, po-VM developerski certifikati, lanac povjerenja internog CA).
- **Produkcijski nginx reverse-proxy repozitorij** (~67 commitova) — TLS-terminirajući rub ispred internih analitičkih alata (Grafana, Metabase, Redash). Rad se koncentrirao na WebSocket podršku za Grafanine real-time dashboarde, po-servis auth usmjeravanje (neki servisi ne trebaju auth na internoj mreži), prilagođene stranice grešaka, popravke redirect loopova i rubne slučajeve PWA usmjeravanja. Označeno za produkciju kroz više objavljenih verzija, što znači da su se promjene postavljale na stvaran perimetar prema klijentu, a ne u sandbox.
- **PostgreSQL container repozitorij** (~20 commitova) — rad na base imageu baze podataka. Rekurirajuća tema bila je natjerati Postgresove logove da pouzdano prelaze granice kontejnera — vlasništvo log datoteka kroz korisnike i grupe, provizioniranje `postgresql.conf` pri build-vremenu kontejnera, log datoteke koje moraju biti čitljive od sestrinskih kontejnera, te mali ali stvaran DBA-strani alatni lanac (npr. dodavanje `nano` u base image kako bi se debug unutar kontejnera učinio izvodljivim).
- **Feature branch analitičkog stacka** (~6 commitova) — radna kopija korištena za razvoj provizioniranja Metabase/Grafana VPS-a prije nego što se mergeala u glavni orkestracijski repozitorij. Commitovi dokumentiraju tipičnu bol povezivanja Metabase preko interne firewall-a s Postgresom hostanim na GitLabu (ICMP restrikcije, network namespacing) — vrsta integracijskog debuga koja se ne pojavljuje u javnom commit logu konačnog mergeanog playbooka.

## Sloj softverskog opskrbnog lanca

Otprilike 30% mandata bilo je koncentrirano ovdje. Obrazac je jednostavan za opisati i operativno značajan: svaki kanal artefakata koji je platforma konzumirala omotan je iza internog korijena povjerenja.

- **Composer / PHP paketi → Satis.** Privatni repository servis za Composer. Interni paketi i odobreni odrazi trećih strana poslužuju se iz Satisa; `composer.json` platforme proxia kroz njega umjesto da izravno dohvaća javni Packagist. Učinak: typosquattirani Packagist paket ne može slučajno sletjeti u tenant build.
- **npm / JavaScript paketi → Verdaccio.** Isti oblik na JavaScript strani. Front-end buildovi razrješavaju se kroz Verdaccio; javno-npm dohvaćanje je posredovano umjesto izravnog. Učinak: kompromitirani javni-npm tarball ne ulazi u tenant build put bez eksplicitne izmjene allow-liste.
- **SQL artefakti → Redgate SQL Source Control.** SQL Compare i Source Control dovode promjene sheme pod pregled verzionskog kontrolora na isti način kao što je već bio aplikacijski kod. Učinak: promjene baze podataka postaju pregledivi diffovi s imenovanim odobravateljem, a ne ad-hoc DBA akcije.
- **Container slike → GitLab Container Registry.** Već je bio na mjestu; mandat je tok vjerodajnica učinio pouzdanim i login korak provjerljivim.

Svaki sloj je uparen s lifecycleom certifikata tako da se sami registriji autenticiraju prema istom internom CA koji koristi ostatak platforme.

## Analitički stack

Dodana su dva dodatna Hetzner VM-a — jedan za Metabase, jedan za Grafanu — svaki proviziran kroz isti Ansible/Semaphore put koji se koristi za developerske i klijentske VM-ove. Metabase VM hosta BI alat s vlastitim PostgreSQL skladištem metapodataka i Java Keystoreom za TLS terminaciju. Grafana VM koristi isti interni CA, persistira stanje pod `/grafana` i pokreće `grafana/grafana-oss` sliku u Dockeru iza iste konvencije imenovanja DNS zone kao ostatak platforme. Oba čvora dostupna su samo unutar OpenVPN sloja; nijedan nije izložen javnom internetu. TLS-terminirajući reverse proxy ispred njih je produkcijski nginx repozitorij iznad — WebSocket podrška za Grafanin real-time, po-servis auth usmjeravanje, prilagođene 4xx/5xx stranice.

## Ishod

Platformska IaC ponovno radi end-to-end, s pokretnim dijelovima dokumentiranima (arhitektura, playbooki, uloge, workflowi) na razini koja preživi sljedeći događaj rotacije inženjera. Sloj opskrbnog lanca znači da je odgovor na pitanje *Možete li opisati kako bi typosquattirani javni paket dosegnuo proizvodnju* — "Ne može, jer su kanali artefakata posredovani internim registrijima." Analitički stack radi uz ostatak platforme bez proširenja javne napadne površine. Produkcijski reverse proxy je tagiran-i-objavljen, tako da promjene teku kroz disciplinu koja se preslikava na očekivanja "sigurnog razvoja" iz NIS2 § 21(2).

U jeziku CRA Cliffa 1 (11. rujna 2026.) i NIS2 Članka 21(2), ovaj korpus rada proizveo je — dvije godine ranije — upravo onu vrstu dokaza integriteta opskrbnog lanca koje te regulacije sada zahtijevaju da operatori budu sposobni predstaviti regulatoru ili prijavljenom tijelu na zahtjev.

## Što rad nije proizveo

Nismo pokrenuli formalnu SBOM cijev (mandat za SBOM datira nakon rada). Nismo proveli penetracijsko testiranje treće strane protiv registrija. Nismo proizveli procjenu zaštite tenant podataka. Nismo proizveli ISO/IEC 27001 Statement of Applicability. Rad je bio operativno poboljšanje, ne atestiranje sukladnosti — ali operativna poboljšanja su supstrat na kojem atestiranje sukladnosti počiva.

## Oblik rada

Single-inženjer intenzivno kroz nekoliko mjeseci, radeći uz mali interni tim operatora. Otprilike **178 commitova kroz četiri repozitorija** kao vidljiv trag: orkestracijska IaC, produkcijski nginx reverse proxy, PostgreSQL container base image i feature branch analitičkog stacka. Plus komponente registrija opskrbnog lanca i provizioniranje analitičkog stacka. Cijelo vrijeme povjerljivo; ova stranica je jedina anonimizirana referenca.
