---
title: "NFR odgovor o sukladnosti za tier-1 europskog energetskog operatora"
sector: "Tier-1 europski energetski operator"
engagementType: "Pred-ugovorna dubinska analiza — strukturirani NFR odgovor"
year: "2026"
region: "Sjeverna Europa"
summary: "Multidomenska NFR matrica iz enterprise nabavnog tima — otprilike pedeset stavki kroz sigurnost i podatkovnu arhitekturu — zahtijevala je strukturirani odgovor koji bi preživio nabavni pregled. Proizveli smo registar sukladnosti, detaljni list za teške stavke i log provjere izvora."
publishedAt: "2026-05-09"
featured: true
---

## Kontekst

Enterprise nabavni tim tier-1 europskog energetskog operatora izdao je multidomenski katalog ne-funkcionalnih zahtjeva (NFR) kao dio pred-ugovorne dubinske analize za odnos sa softverskim pružateljem. Katalog je obuhvaćao otprilike pedeset stavki kroz četiri široke domene:

1. **Cyber sigurnost** — kroz sve standardne domene: *identitet i pristup* (autentikacija, RBAC, MFA, pregledi pristupa); *zaštita podataka* (klasifikacija, enkripcija u prijenosu i u mirovanju, upravljanje ključevima, DLP, sigurnost backupa, GDPR / privatnost); *upravljanje ranjivostima i incidentima* (upravljanje ranjivostima, penetracijsko testiranje, odgovor na incidente, patching, SIEM); *mrežna i aplikacijska sigurnost* (sigurnost mreže, logiranje i nadzor, sigurni SDLC, rizik treće strane); *kontinuitet poslovanja i izvještavanje* (kontinuitet, izvještavanje o sukladnosti); i *ljudi* (sigurnosna obuka).
2. **Podatkovna arhitektura** — upravljanje, kvaliteta, event-driven arhitektura, čuvanje, lineage, master data management, microservice / labava povezanost, API i OpenAPI standardi, dualne metode pristupa.
3. **Tehnička arhitektura / aplikacija** — skalabilnost (horizontalna i vertikalna), island-mode rad, observabilnost.
4. **Kontinuitet poslovanja / DR** — recovery point i time objectives, geo-redundancija, testiranje failovera, integritet backupa.

Pružatelj je imao arhitekturu na strani pružatelja, Azure-native sigurnosni stack i radno proizvod. Trebao je strukturirani odgovor koji bi preživio nabavni pregled — redak po redak, s dokazima — unutar fiksnog vremenskog okvira.

## Pristup

Radili smo u strukturi koju je nabavni tim nametnuo i dodali strukturu koju nije.

Sam registar sukladnosti tekao je s jednim retkom po zahtjevu, sa stupcima za: tekst zahtjeva, status sukladnosti (jedan od *compliant*, *partial*, *non-compliant*, *desirable*), obrazloženje, izvor / referenca dokaza, potrebna akcija, procjena troška i vremenski okvir. Gdje je postojeća sposobnost proizvoda pokrivala zahtjev, stupac izvora vezao se na artefakt koji ga dokazuje. Gdje je sposobnost bila djelomična ili odsutna, stupci akcije i troška činili su jaz eksplicitnim i kvantificiranim.

Oko registra dodali smo tri strukturna artefakta koje izvorni katalog nije tražio:

- **Detaljnu analizu "teških stavki".** Otprilike sedam stavki zahtijevalo je više od retka u registru — tipično zato što su sjekle više domena, ili zato što je odgovor ovisio o odlukama na strani klijenta koje još nisu donesene. Svaka je dobila vlastitu narativnu stranicu.
- **Log provjere izvora.** Otprilike trideset unosa koji vežu specifična obrazloženja na specifične sastanke, emailove ili dizajn dokumente. Ovo je pretvorilo tvrdnje *u skladu smo s X* u auditabilno podrijetlo.
- **Sažetak utjecaja troška.** Konsolidirani pogled na implikacije troška kroz sve djelomične i non-compliant stavke, s grubim vremenskim okvirom. Nabavni timovi tipično otkrivaju ovu cifru kroz bolnu nadnabavu; iznoseći je unaprijed skratili smo razgovor.

Radili smo kroz standardni Azure-native sigurnosni stack — Entra ID, Key Vault, Defender, Purview, Sentinel, Event Hub, Log Analytics — ali metodologija je platform-agnostic. Artefakt bi izgledao isto na AWS ili GCP ekvivalentima.

## Što smo isporučili

- Registar sukladnosti od otprilike pedeset redaka koji pokriva sigurnosne, podatkovne i arhitekturalne domene
- Detaljnu narativu o sedam stavki koje su zahtijevale više od retka
- Log provjere izvora s tridesetak unosa
- Sažetak utjecaja troška s grubim vremenskim okvirom
- Eksplicitnu identifikaciju pet otvorenih pojašnjenja na strani klijenta koja nisu blokirala početni odgovor

## Ishod

Pružatelj je ušao u nabavni pregled sa strukturiranim odgovorom koji je dokumentirao sukladnost, dokaze i troškove jaza u istom artefaktu, te **prešao u komercijalno zatvaranje bez dodatne NFR runde** — detaljna analiza *teških stavki* odgovorila je unaprijed na pitanja koja bi neprijateljsko nabavno čitanje postavilo, a sažetak utjecaja troška iznio okidače za ponovno pregovaranje prije nego što su postali ponovno pregovaranje.

Pet otvorenih pojašnjenja na strani klijenta vraćeno je arhitekturalnom timu klijenta kao dio odgovora, sužavajući sljedeću rundu pitanja i skraćujući njihov interni ciklus pregleda.

## Što nismo isporučili

Penetracijski test. Sigurnosni audit. ISO 27001 dokumentaciju. Implementaciju bilo koje djelomično sukladne stavke. Isporuka je bila strukturirano savjetovanje, ne sigurnosni rad.

## Oblik mandata

Mandat fiksnog opsega, oblik pred-ugovorne dubinske analize, single principal. Materijali proizvedeni kao strukturiran workbook u željenom formatu nabavnog tima. Cijelo vrijeme povjerljivo; nema proizvedenih javnih materijala.
