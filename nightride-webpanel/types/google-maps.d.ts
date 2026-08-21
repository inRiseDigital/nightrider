// `@types/google.maps` declares the global `google.maps` namespace, but the dot
// in its package name keeps it out of TypeScript's automatic @types inclusion —
// reference it explicitly so lib/organizer/google-maps.ts and the venue
// location picker type-check.
/// <reference types="google.maps" />
