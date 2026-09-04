// Shared Material 3 design tokens for the admin console — extracted from the
// repeated hex literals in components/admin/m3/** and the design mockup
// (docs/design/admin-dashboard-v3.dc.html). Additive: existing components
// keep using their own inline hex values until they're touched for other
// reasons — this file exists so new code (primitives, new screens) has one
// place to pull the palette from instead of re-typing hex strings.

export const SURFACE = {
  base: "#141114",
  raised: "#1B181B",
  overlay: "#1F1B1F",
  hover: "#2A252A",
  sunken: "#241F23",
  accentCard: "#2A1A22",
} as const;

export const BORDER = {
  hairline: "#241F23",
  default: "#332B30",
  strong: "#524549",
} as const;

export const TEXT = {
  primary: "#EDE0E4",
  secondary: "#CFC0C5",
  muted: "#9A8C91",
} as const;

export const ACCENT = {
  pink: "#FFB1C4",
  pinkStrong: "#8E1049",
  pinkHover: "#A81456",
  pinkPale: "#FFD9E2",
  pinkDeep: "#650430",
  plum: "#4E1930",
} as const;

export const MONO = "'Roboto Mono', monospace";

// Re-exported so existing `from "./m3-data"` imports keep working while new
// code can pull the same badge palette from here alongside the other tokens.
export { BADGE_COLORS, badgeColors, type BadgeType } from "./m3-data";
