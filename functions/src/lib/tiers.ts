import {cols} from "./admin";

// Default country → tier map, mirroring `lib/core/services/tier_map.dart`.
const DEFAULT_TIERS: Record<string, number> = {
  US: 1, CA: 1, GB: 1, AU: 1, NZ: 1, DE: 1, NL: 1, SE: 1, NO: 1, DK: 1,
  CH: 1, IE: 1, AT: 1, BE: 1, FI: 1,
  FR: 2, IT: 2, ES: 2, JP: 2, KR: 2, SG: 2, AE: 2, SA: 2, QA: 2, KW: 2,
  IL: 2, PT: 2, GR: 2, PL: 2, CZ: 2, HK: 2,
  BR: 3, MX: 3, AR: 3, CL: 3, TR: 3, RU: 3, MY: 3, TH: 3, ZA: 3, RO: 3,
  HU: 3, CN: 3, CO: 3, PE: 3, RS: 3, UA: 3,
  IN: 4, ID: 4, PK: 4, BD: 4, NG: 4, EG: 4, PH: 4, VN: 4, KE: 4, MA: 4,
  DZ: 4, IQ: 4, LK: 4, NP: 4, GH: 4, TZ: 4,
};

let cachedOverrides: Record<string, number> | null = null;
let cachedAt = 0;

/**
 * Resolves a country ISO code to a tier level (1..4), applying admin overrides
 * from `geo_tiers/overrides` (cached for 5 minutes). This runs server-side so a
 * client cannot inflate its tier by spoofing — the country of record on the
 * account is what payouts use.
 */
export async function tierForCountry(countryCode: string): Promise<number> {
  const code = (countryCode || "").toUpperCase();
  if (Date.now() - cachedAt > 5 * 60_000) {
    try {
      const snap = await cols.geoTiers.doc("overrides").get();
      cachedOverrides = (snap.data()?.map as Record<string, number>) ?? {};
      cachedAt = Date.now();
    } catch {
      cachedOverrides = {};
    }
  }
  return cachedOverrides?.[code] ?? DEFAULT_TIERS[code] ?? 3;
}
