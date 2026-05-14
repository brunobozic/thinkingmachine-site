---
title: "Procjena cloud troškova za SaaS pružatelja s više instalacija"
sector: "Pružatelj industrijskog softvera"
engagementType: "Savjetodavni mandat fiksnog opsega od 40 sati"
year: "2026"
region: "Sjeverna Europa"
summary: "Pružatelj koji je pripremao ponudu za cloud-managed SaaS aranžman tier-1 enterprise klijentu trebao je obranjiv model cijene po instalaciji — bez pristupa baznoj liniji postojećeg davatelja hostinga. Isporučili smo trianguliranu baznu liniju, playbook za cijene u više scenarija i kalkulator za klijenta."
publishedAt: "2026-05-09"
featured: true
---

## Kontekst

Pružatelj industrijskog softvera s više instalacija pripremao je ponudu za managed SaaS aranžman s tier-1 enterprise klijentom. Postojeće postavljanje pružatelja radilo je na infrastrukturi klijenta kroz partnera za upravljane usluge; novi aranžman bi premjestio odgovornost za hosting i operacije na samog pružatelja.

Komercijalno pitanje bilo je naizgled jednostavno: *Koliko da naplaćujemo po instalaciji mjesečno?*

Komplikacije su bile:

1. Postojeća bazna linija hostinga bila je netransparentna. Klijentov partner za upravljane usluge odbio je objaviti račune, ostavljajući pitanje *Koliko ovo trenutno košta?* neodgovorivim iz javno dostupnih informacija.
2. Dimenzioniranje workloada bilo je neizvjesno. Jedini dostupni podaci o performansama dolazili su iz smanjene testne okoline; stvarna proizvodna veličina potvrđena je tek sredinom mandata.
3. Posao je nosio značajna ne-troškovna razmatranja — regulatornu sukladnost, rizik opskrbnog lanca, SaaS-enablement strategiju — koja su morala stajati uz cifru troška, ne iza nje.

Workload je bio telemetrijski intenzivan. Veće instalacije ingestirale su otprilike **200.000 redaka dnevno**, 24/7 hvatanih iz povezanih instrumenata kroz Node.js prijemnik; manje instalacije pokretale su oko 20.000 redaka/dan. Planirani opseg bio je šest instalacija kroz dvije razine performansi baze podataka, s modelskim horizontom proširenim na dvanaest kako bi pružatelj uvodio nove klijente, ukupno **18–36 servera** kroz proizvodnju i ne-proizvodnju. Dovoljno malo da po-serverski fiksni troškovi — tipično zanemarivi pri enterprise skali — postanu neproporcionalni, što je dio razloga zašto se procjena morala napraviti pažljivo, a ne benchmark-ekstrapolacijom.

Pružatelj je trebao dokument za upravu u otprilike četiri tjedna. Interni tim bio je sposoban, ali nije imao kapaciteta, a veća konzultantska alternativa zahtijevala bi višemjesečnu fazu otkrivanja koju vremenski okvir nije podržavao.

## Pristup

Procjenu smo usidrili u literaturi o cloud ekonomiji, observabilnosti i DevOps-u — Storment & Fuller, Majors, Nygard, Forsgren et al. — plus first-party Azure / AWS / GCP smjernicama za odabir razine i DR troškove za database engineove u opsegu. Frameworks su strukturirali četverokategorijsku taksonomiju troškova: fiksni overhead, kompetencija, varijabilni, po serveru.

Unutar tog okvira izgradili smo:

- **Trianguliranu baznu liniju.** Gdje računi nisu bili dostupni, konstruirali smo procijenjenu trenutnu potrošnju iz verificiranih javnih cloud cjenika (unakrsno provjereno s API-jem za cijene pružatelja clouda) pomnoženu s tipičnim rasponom partnerske marže za skalu deploymenta klijenta.
- **Matricu scenarija.** Tri aktivna cloud puta (Azure SQL Managed Instance, AWS RDS za SQL Server, GCP Cloud SQL — svi License-Included nakon klijent-strane odluke koja je isključila put prijenosa licence), svaki na tri razine obveze (PAYG, jednogodišnji rezervirani, trogodišnji rezervirani). Plus četiri isključena scenarija dokumentirana radi potpunosti.
- **Playbook za cijene.** Koliko bi pružatelj trebao naplatiti po instalaciji mjesečno da pokrije verificirane cloud troškove plus ciljanu maržu, modelirano na tri razine marže i dvije postavke osoblja (dedicirani FTE nasuprot apsorbiranih operacija).
- **Kalkulator za klijenta.** List u tablici koji je klijent mogao popuniti svojim stvarnim postojećim troškovima da testira je li ponuda pružatelja konkurentna pri bilo kojoj zadanoj marži.
- **NFR sukladnosti scoreboard.** Mapirao je predloženu arhitekturu na klijentov postojeći katalog ne-funkcionalnih zahtjeva, s eksplicitnim odgađanjem pet otvorenih pojašnjenja koja nisu blokirala komercijalnu odluku Faze 1.

Također smo identificirali bestroškovni SQL konfiguracijski popravak na testnoj okolini (postavka vezana uz paralelizam koja je tjerala prividnu potrebu za upgradeom razine) — nalaz koji je potencijalno preokvirio cijeli razgovor o dimenzioniranju i označen kao prioritetna akcijska stavka broj jedan.

## Što smo isporučili

- Otprilike četrdesetstranični strateški izvještaj procjene troškova
- Zaseban model troškova u tablici od dvadeset šest listova, uključujući živi kalkulator za klijenta
- Sažetak migracije i oporavka na strateškoj razini
- NFR sukladnosti scoreboard
- Eksplicitne izjave izvan opsega koje pokrivaju implementaciju, runbookove, IaC, dubinsku analizu koda, sigurnosne audite i proof-of-concept rad

## Ishod

Pružatelj je ušao u sljedeći sastanak s klijentom s obranjivim modelom cijene po instalaciji usidrenim u provjerljivim javnim cijenama, čistim razdvajanjem između komercijalne cijene i infrastrukturnog troška te kalkulatorom koji je klijent mogao sam pokrenuti. Pitanje *Postoji li marža uopće?* — koje je prije bilo neodgovorivo — preokvireno je kao razgovor o SaaS premiji, potkrijepljen kvantificiranom baznom linijom.

Bestroškovni konfiguracijski nalaz sam po sebi dovoljan je da preokvirivi pitanje odabira razine — zato je označen kao prva akcijska stavka u isporuci, a ne sakriven u dodatku.

## Što nismo isporučili

Implementaciju. Terraform / IaC. Dubinsku analizu koda. Sigurnosni audit. Plan izvršenja migracije. Proof-of-concept. Ti elementi proglašeni su izvan opsega pri postavljanju mandata i takvima ostali. Isporuka je bila podrška odluci, ne izvedba.

## Oblik mandata

Savjetodavni mandat fiksnog opsega od četrdeset sati raspoređen kroz otprilike četiri tjedna kroz tri radne sesije plus asinkrone isporuke. Single-principal mandat (bez tima za isporuku). Materijali dijeljeni kroz sustav za suradnju klijenta; isporuke zadržava klijent.
