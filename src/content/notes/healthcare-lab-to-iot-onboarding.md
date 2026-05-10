---
title: "What healthcare lab integration taught me about IoT device onboarding"
summary: "The diagnostic-instrument integration playbook from hospital IT translates almost line-for-line to multi-vendor IoT device onboarding. Same heterogeneous vendor landscape, same identity problem, same per-device commissioning friction — and the lab world has a thirty-year head start."
publishedAt: "2026-05-09"
tags: ["IoT", "Healthcare IT", "Integration", "Cross-domain"]
---

Hospital lab integration solves a problem that looks suspiciously like multi-vendor IoT device onboarding. Both involve a fleet of expensive, heterogeneous, vendor-specific devices that arrive without a common protocol, must be commissioned per-instance into a multi-tenant environment, and need to keep working when the network is flaky and the vendor support contract ran out two years ago.

The lab world has been doing this since ASTM E1394 (1991) and has converged on a small set of patterns that the IoT industry is reinventing badly. A handful worth stealing:

**Vendor abstraction at the per-device-type layer, not the per-protocol layer.** Hospital lab systems do not try to write one driver for "all immunoassay analysers". They write a thin per-vendor adapter, and abstract above that — at the level of *what an immunoassay test result looks like*, not *what bytes Roche puts on the wire*. IoT projects that try to abstract at the protocol layer (one runtime that speaks Modbus and KNX and BACnet and CoAP) usually collapse under the weight of vendor-specific quirks. The lab world figured out that the right abstraction is the *clinical concept*, not the *transport*.

**Commissioning as a per-device ceremony, not a script.** When a new chemistry analyser arrives at a hospital, the integration is a known three-day procedure: install, configure the bidirectional ASTM/HL7 link, verify with a known-positive control sample, sign-off. Nobody pretends it can be one-click. IoT vendors keep selling "auto-discovery" that works for the demo and breaks on site number eleven. Embracing the ceremony — making it short, repeatable, documented per device class — beats pretending the ceremony does not exist.

**The middleware is the asset.** In hospital IT, the integration engine (Cloverleaf, Mirth, Rhapsody, in-house) is a strategic asset that the hospital owns. It outlives every device generation, every vendor change, every system replacement. IoT shops that put the smarts in the device cloud lose this asset every time a vendor changes pricing. The pattern that survives: keep your own integration runtime, treat the vendor cloud as a *protocol provider*, not a *system of record*.

**Identity must be hospital-side.** A glucose meter has a serial number; the patient it just measured has an MRN. The mapping has to be owned by the hospital, not the device vendor. Same in IoT: the building owns the device's location and role, not the vendor cloud. Designs that put identity in the vendor cloud become hostage to that vendor's M&A history.

**Bidirectional from day one.** Lab integration started as one-way (instrument → LIS) and quickly hit walls: the operator needed to push QC schedules and patient demographics back. The same trajectory plays out in IoT: read-only telemetry quickly turns into "we need to actuate from the cloud". Bake bidirectional into the abstraction from the start; retrofitting it costs more than starting with it.

If you're standing up an IoT integration program and have not read what hospital IT did in the 1990s and 2000s, you are about to spend three years rediscovering the patterns. Start with the IHE technical frameworks. The names are different. The shape is identical.
