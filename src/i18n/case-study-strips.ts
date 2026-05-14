// Per-case-study, per-locale copy for the CaseStudyNumbersStrip component.
// All values are sourced from the case-study body — no inventing.

import type { Locale } from './paths';

export interface StripCell {
  value: string;
  label: string;
  sublabel: string;
}

export interface StripData {
  caption: string;
  note: string;
  cells: [StripCell, StripCell, StripCell, StripCell];
}

type SlugStrips = Partial<Record<Locale, StripData>>;

const strips: Record<string, SlugStrips> = {
  'cloud-cost-finops': {
    en: {
      caption: 'By the numbers',
      note: 'All values are drawn from the engagement scope or workload definition documented in the case study text; none are projected outcomes or invented metrics.',
      cells: [
        { value: '40h',    label: 'fixed-scope advisory engagement',     sublabel: '≈ four weeks calendar time, single principal' },
        { value: '36',     label: 'servers in the planned scope',        sublabel: '12 installations · 2 DB performance tiers · prod + non-prod' },
        { value: '9 + 4',  label: 'cloud scenarios modelled',            sublabel: '3 platforms × 3 commitment levels + 4 ruled-out paths' },
        { value: '200k',   label: 'rows/day peak ingestion',             sublabel: '24/7 instrument telemetry through Node.js receiver' },
      ],
    },
    de: {
      caption: 'In Zahlen',
      note: 'Alle Werte stammen aus dem in der Fallstudie dokumentierten Mandatsumfang oder der Workload-Definition; keiner ist ein projiziertes Ergebnis oder eine erfundene Metrik.',
      cells: [
        { value: '40 h',   label: 'festpreisiges Beratungsmandat',       sublabel: '≈ vier Wochen Kalenderzeit, ein Principal' },
        { value: '36',     label: 'Server im geplanten Umfang',          sublabel: '12 Installationen · 2 DB-Performance-Stufen · Prod + Non-Prod' },
        { value: '9 + 4',  label: 'Cloud-Szenarien modelliert',          sublabel: '3 Plattformen × 3 Bindungsstufen + 4 ausgeschlossene Pfade' },
        { value: '200k',   label: 'Zeilen/Tag Spitzen-Ingestion',        sublabel: '24/7 Instrumenten-Telemetrie via Node.js-Receiver' },
      ],
    },
    hr: {
      caption: 'U brojkama',
      note: 'Sve vrijednosti dolaze iz opsega mandata ili definicije workloada dokumentirane u studiji; nijedna nije projicirani rezultat ili izmišljena metrika.',
      cells: [
        { value: '40 h',   label: 'savjetodavni mandat fiksnog opsega',  sublabel: '≈ četiri tjedna kalendarskog vremena, jedan principal' },
        { value: '36',     label: 'servera u planiranom opsegu',         sublabel: '12 instalacija · 2 razine performansi baze · prod + non-prod' },
        { value: '9 + 4',  label: 'cloud scenarija modelirano',          sublabel: '3 platforme × 3 razine obveze + 4 isključena puta' },
        { value: '200k',   label: 'redaka/dan vršne ingestije',          sublabel: '24/7 telemetrija instrumenata kroz Node.js prijemnik' },
      ],
    },
  },
  'cra-readiness-eu-manufacturer': {
    en: {
      caption: 'By the numbers',
      note: 'All values reflect the produced evidence pack and risk-surface mapping documented in the case study; no client performance outcomes are claimed.',
      cells: [
        { value: '240',    label: 'pages of audit-defensible evidence',  sublabel: '13 primary documents + 4 annexes' },
        { value: '32',     label: 'consolidated findings tracked',       sublabel: 'classified L / I / B across 24 downstream documents' },
        { value: '15',     label: 'named threat scenarios mapped',       sublabel: 'edge · cloud · supply chain · NIS2 cascade' },
        { value: '25–29',  label: 'risk-register entries (5×5 scored)',  sublabel: 'visible scores 25 · 20 · 16 · 15' },
      ],
    },
    de: {
      caption: 'In Zahlen',
      note: 'Alle Werte spiegeln das erzeugte Evidenz-Paket und die in der Fallstudie dokumentierte Risiko-Oberflächen-Kartierung wider; keine Kunden-Performance-Ergebnisse werden behauptet.',
      cells: [
        { value: '240',    label: 'Seiten Audit-belastbarer Evidenz',    sublabel: '13 primäre Dokumente + 4 Annexe' },
        { value: '32',     label: 'konsolidierte Befunde nachverfolgt',  sublabel: 'klassifiziert L / I / B über 24 nachgelagerte Dokumente' },
        { value: '15',     label: 'benannte Bedrohungs-Szenarien',       sublabel: 'Edge · Cloud · Lieferkette · NIS2-Kaskade' },
        { value: '25–29',  label: 'Risiko-Register-Einträge (5×5)',       sublabel: 'sichtbare Werte 25 · 20 · 16 · 15' },
      ],
    },
    hr: {
      caption: 'U brojkama',
      note: 'Sve vrijednosti odražavaju proizvedeni dokazni paket i mapiranje rizične površine dokumentirano u studiji; ne tvrdi se ništa o klijentskim performansama.',
      cells: [
        { value: '240',    label: 'stranica audit-obranjive evidencije', sublabel: '13 primarnih dokumenata + 4 dodatka' },
        { value: '32',     label: 'konsolidiranih nalaza praćenih',      sublabel: 'klasificirano L / I / B kroz 24 povezana dokumenta' },
        { value: '15',     label: 'imenovanih scenarija prijetnji',      sublabel: 'rub · cloud · opskrbni lanac · NIS2 kaskada' },
        { value: '25–29',  label: 'unosa u registar rizika (5×5)',        sublabel: 'vidljivi rezultati 25 · 20 · 16 · 15' },
      ],
    },
  },
  'nfr-compliance-energy': {
    en: {
      caption: 'By the numbers',
      note: 'All values reflect the deliverable structure documented in the case study; no client-side outcomes are claimed.',
      cells: [
        { value: '~50',    label: 'line items in the compliance register',  sublabel: '4 domains: security · data · architecture · BC/DR' },
        { value: '7',      label: 'difficult-items deep-dives',              sublabel: 'cross-domain or customer-decision-dependent' },
        { value: '~30',    label: 'entries in the source-verification log', sublabel: 'evidence linked to meetings · emails · designs' },
        { value: '5',      label: 'open customer-side clarifications',       sublabel: 'flagged, did not block Phase 1 commercial decision' },
      ],
    },
    de: {
      caption: 'In Zahlen',
      note: 'Alle Werte spiegeln die in der Fallstudie dokumentierte Lieferstruktur wider; keine Kunden-seitigen Ergebnisse werden behauptet.',
      cells: [
        { value: '~50',    label: 'Zeilen im Compliance-Register',          sublabel: '4 Domänen: Sicherheit · Daten · Architektur · BC/DR' },
        { value: '7',      label: 'Vertiefungen für schwierige Punkte',      sublabel: 'domänen-übergreifend oder kunden-entscheidungs-abhängig' },
        { value: '~30',    label: 'Einträge im Quellen-Verifikations-Log',   sublabel: 'Evidenz verknüpft mit Meetings · E-Mails · Designs' },
        { value: '5',      label: 'offene kunden-seitige Klärungen',         sublabel: 'markiert, blockierten Phase-1-Geschäftsentscheidung nicht' },
      ],
    },
    hr: {
      caption: 'U brojkama',
      note: 'Sve vrijednosti odražavaju strukturu isporuke dokumentiranu u studiji; ne tvrde se rezultati na strani klijenta.',
      cells: [
        { value: '~50',    label: 'stavki u registru sukladnosti',          sublabel: '4 domene: sigurnost · podaci · arhitektura · BC/DR' },
        { value: '7',      label: 'detaljnih analiza teških stavki',         sublabel: 'međudomenske ili ovisne o odluci klijenta' },
        { value: '~30',    label: 'unosa u log provjere izvora',             sublabel: 'dokazi povezani sa sastancima · emailovima · dizajnima' },
        { value: '5',      label: 'otvorenih pitanja na strani klijenta',    sublabel: 'označena, nisu blokirala fazu 1 komercijalne odluke' },
      ],
    },
  },
};

export function getNumbersStrip(slug: string, locale: Locale): StripData | undefined {
  const slugStrips = strips[slug];
  if (!slugStrips) return undefined;
  return slugStrips[locale] ?? slugStrips.en;
}
