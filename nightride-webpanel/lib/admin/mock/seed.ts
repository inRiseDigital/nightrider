// Deterministic seed helpers shared by every file in lib/admin/mock/. Same
// hashing philosophy as ../mock-overlay.ts (a tiny string hash, never
// Math.random() or Date.now()) so the mock data source renders identically on
// every reload and in every snapshot/test.
//
// The design mockup (docs/design/admin-dashboard-v3.dc.html) hardcodes
// "today" as `new Date(2026, 8, 4)` so its seed data's relative dates
// ("18 min ago", "2h ago", ...) read correctly against that fixed instant.
// MOCK_NOW mirrors that exact date for the same reason.

import { Timestamp } from "firebase/firestore";

const SEED = 20260904;

/** mulberry32 — small, fast, deterministic PRNG. Never Math.random(). */
export function mulberry32(seed: number): () => number {
  let a = seed | 0;
  return function next() {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Same style as mock-overlay.ts's hashUid — a tiny string hash, not a crypto hash. */
export function hashString(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h * 31 + s.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

/** A PRNG seeded from a stable key (e.g. a record id) plus the module-fixed seed. */
export function rngFor(key: string): () => number {
  return mulberry32((hashString(key) ^ SEED) >>> 0);
}

export function pick<T>(rng: () => number, items: readonly T[]): T {
  return items[Math.floor(rng() * items.length) % items.length];
}

/** The fixed "now" every seed file's timestamps are anchored to — see header comment. */
export const MOCK_NOW = new Date(2026, 8, 4);

export function dateAt(year: number, month: number, day: number, hour = 0, minute = 0): Timestamp {
  return Timestamp.fromDate(new Date(year, month, day, hour, minute));
}

export function minutesBeforeNow(minutes: number): Timestamp {
  return Timestamp.fromDate(new Date(MOCK_NOW.getTime() - minutes * 60_000));
}

export function daysBeforeNow(days: number): Timestamp {
  return Timestamp.fromDate(new Date(MOCK_NOW.getTime() - days * 86_400_000));
}
