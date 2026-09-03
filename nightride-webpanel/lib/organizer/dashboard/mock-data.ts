import { DAYS } from "./constants";
import type {
  ActivityEntry,
  BoostSlot,
  InboxMessage,
  OpeningHours,
  OrganizerEvent,
  PromoCode,
  PushState,
  RankPerk,
  TeamMember,
  VenueProfile,
  VenueReview,
} from "./types";

/**
 * Seed data for the organizer dashboard prototype. Nothing here is persisted —
 * the Firestore collections (`venues`, `events`, `approvals`) are the eventual
 * source of truth, but the panel is UI-first for now, matching how
 * `lib/admin/mock-data.ts` seeds the admin side.
 */

function hours(closedDays: string[], open: string, close: string): OpeningHours[] {
  return DAYS.map((day) => ({ day, closed: closedDays.includes(day), open, close }));
}

export const MOCK_ORGANIZER = {
  name: "Neon Fox Collective",
  initials: "NF",
  email: "contact@neonfoxcollective.com",
  phone: "+971 50 123 4567",
};

export const MOCK_VENUE_ORDER = ["sirens", "warehouse9"];

export const MOCK_VENUES: Record<string, VenueProfile> = {
  sirens: {
    verified: true,
    name: "Sirens Dubai",
    city: "Dubai, UAE",
    address: "Marina Walk, Dubai Marina, Dubai, UAE",
    about:
      "Rooftop techno and house on the Marina skyline. Open-air terrace, resident DJs Thu–Sat, and a strict door policy after 23:00.",
    socialLinks: [
      { network: "instagram", value: "@sirensdubai" },
      { network: "tiktok", value: "@sirensdubai" },
    ],
    genres: ["Techno", "House"],
    dressCode: "Smart Casual",
    agePolicy: "21+",
    coverMin: 50,
    coverMax: 150,
    currency: "AED",
    capacity: 450,
    amenities: ["Rooftop", "Cloakroom"],
    hours: hours(["Mon", "Tue"], "22:00", "04:00"),
    exceptions: [{ label: "Eid Al Adha — Private Hire", date: "2026-08-19", closed: true }],
    menu: [
      {
        id: "ms1",
        name: "Bottle service & tables",
        items: [
          {
            id: "mi1",
            name: "Skyline table — Grey Goose",
            price: 3200,
            desc: "Reserved terrace table with skyline view, two mixers per bottle.",
            size: "1.5L magnum",
            serves: "6",
            tags: ["Signature"],
            nights: [4, 5],
            soldOut: false,
          },
          {
            id: "mi2",
            name: "Dom Pérignon 2013",
            price: 2900,
            desc: "Served with sparklers on request.",
            size: "75cl",
            serves: "4",
            tags: [],
            nights: [],
            soldOut: false,
          },
          {
            id: "mi3",
            name: "Booth minimum — main deck",
            price: 1500,
            desc: "Minimum spend, redeemable against anything on the menu.",
            size: "",
            serves: "8",
            tags: [],
            nights: [3, 4, 5],
            soldOut: true,
          },
        ],
      },
      {
        id: "ms2",
        name: "Cocktails",
        items: [
          {
            id: "mi4",
            name: "Marasi Spritz",
            price: 75,
            desc: "Aperol, cava, blood orange, rosemary smoke.",
            size: "",
            serves: "",
            tags: ["Signature"],
            nights: [],
            soldOut: false,
          },
          {
            id: "mi5",
            name: "Sober Sunset",
            price: 45,
            desc: "Seedlip, passionfruit, lime, soda.",
            size: "",
            serves: "",
            tags: ["Alcohol-free", "New"],
            nights: [],
            soldOut: false,
          },
        ],
      },
      {
        id: "ms3",
        name: "Food",
        items: [
          {
            id: "mi6",
            name: "Wagyu sliders (3)",
            price: 95,
            desc: "Truffle mayo, aged cheddar, brioche.",
            size: "",
            serves: "2",
            tags: ["Halal"],
            nights: [],
            soldOut: false,
          },
          {
            id: "mi7",
            name: "Charred padrón peppers",
            price: 40,
            desc: "Sea salt, lemon.",
            size: "",
            serves: "",
            tags: ["Vegan"],
            nights: [],
            soldOut: false,
          },
        ],
      },
      {
        id: "ms4",
        name: "Happy hour",
        items: [
          {
            id: "mi8",
            name: "Two-for-one house pours",
            price: 55,
            desc: "House spirits and wines by the glass.",
            size: "",
            serves: "",
            tags: [],
            nights: [3, 4],
            soldOut: false,
          },
        ],
      },
    ],
    tableLink: "https://booking.sirensdubai.com/reserve",
  },
  warehouse9: {
    verified: true,
    name: "Warehouse 9",
    city: "Tokyo, Japan",
    address: "9 Chome, Shibuya, Tokyo, Japan",
    about:
      "Industrial main room built for deep house and techno. Outdoor terrace for smoke breaks, VIP tables on request.",
    socialLinks: [{ network: "instagram", value: "@warehouse9tokyo" }],
    genres: ["Deep House", "Techno", "Commercial"],
    dressCode: "Casual",
    agePolicy: "18+",
    coverMin: 2000,
    coverMax: 4000,
    currency: "¥",
    capacity: 600,
    amenities: ["Smoking Area", "VIP Tables", "Outdoor Terrace"],
    hours: hours(["Mon"], "21:00", "05:00"),
    exceptions: [{ label: "Closed for Renovation", date: "2026-09-01", closed: true }],
    menu: [
      {
        id: "mw1",
        name: "Bar",
        items: [
          {
            id: "mwi1",
            name: "Beer bucket",
            price: 4500,
            desc: "Five bottles on ice.",
            size: "5 × 33cl",
            serves: "3",
            tags: [],
            nights: [5, 6],
            soldOut: false,
          },
          {
            id: "mwi2",
            name: "Espresso martini",
            price: 1800,
            desc: "Double shot, house cold brew.",
            size: "",
            serves: "",
            tags: ["Signature"],
            nights: [],
            soldOut: false,
          },
        ],
      },
      {
        id: "mw2",
        name: "Late food",
        items: [
          {
            id: "mwi3",
            name: "Loaded fries",
            price: 1200,
            desc: "Served until 04:00 from the yard hatch.",
            size: "",
            serves: "2",
            tags: ["Vegan"],
            nights: [],
            soldOut: false,
          },
        ],
      },
    ],
    tableLink: "",
  },
};

export const MOCK_EVENTS: OrganizerEvent[] = [
  {
    id: "e1",
    name: "Full Moon Rooftop",
    venue: "sirens",
    date: "2026-08-08",
    startTime: "22:00",
    endTime: "04:00",
    lineup: ["DJ Kalima", "Nyx"],
    tiers: [
      { name: "Early Bird", price: 80, qty: 100 },
      { name: "General", price: 120, qty: 300 },
    ],
    status: "published",
    recurring: false,
    recurrenceLabel: "",
    scheduledPublish: "",
    notifyOnChange: true,
    moderationFlag: "clean",
    moderationEta: "",
    cancelReason: "",
    sold: 268,
    revenue: 21440,
  },
  {
    id: "e2",
    name: "Techno Fridays",
    venue: "warehouse9",
    date: "2026-08-14",
    startTime: "23:00",
    endTime: "05:00",
    lineup: ["Resident Crew"],
    tiers: [{ name: "Door", price: 3000, qty: 400 }],
    status: "published",
    recurring: true,
    recurrenceLabel: "Every Friday",
    scheduledPublish: "",
    notifyOnChange: true,
    moderationFlag: "clean",
    moderationEta: "",
    cancelReason: "",
    sold: 112,
    revenue: 336000,
  },
  {
    id: "e3",
    name: "Sunset to Sunrise",
    venue: "sirens",
    date: "2026-08-16",
    startTime: "20:00",
    endTime: "06:00",
    lineup: ["Anya Frost"],
    tiers: [{ name: "General", price: 100, qty: 250 }],
    status: "in_review",
    recurring: false,
    recurrenceLabel: "",
    scheduledPublish: "",
    notifyOnChange: true,
    moderationFlag: "pending",
    moderationEta: "~2h remaining",
    cancelReason: "",
    sold: 0,
    revenue: 0,
  },
  {
    id: "e4",
    name: "Members Only: Vol. 3",
    venue: "warehouse9",
    date: "2026-08-22",
    startTime: "22:00",
    endTime: "05:00",
    lineup: [],
    tiers: [],
    status: "draft",
    recurring: false,
    recurrenceLabel: "",
    scheduledPublish: "2026-08-19T18:00",
    notifyOnChange: true,
    moderationFlag: "",
    moderationEta: "",
    cancelReason: "",
    sold: 0,
    revenue: 0,
  },
];

/**
 * `venues/{id}.live`, one raw doc per venue — mock-backed stand-in for what
 * would otherwise be a Firestore read. `parseTonight(MOCK_LIVE[id], capacity)`
 * derives the `TonightState` for whichever venue is being edited; there is no
 * global "tonight" slice, matching one `live` map per venue in production.
 */
export const MOCK_LIVE: Record<string, Record<string, unknown>> = {
  sirens: {
    status: "open",
    doorStatus: "open",
    inVenue: 412,
    queueMinutes: 15,
    emergencyActive: false,
    tablesAvailable: true,
    flash: { active: false, text: "Free entry before midnight", until: "23:59" },
  },
  warehouse9: {
    status: "open",
    doorStatus: "open",
    inVenue: 90,
    queueMinutes: 0,
    emergencyActive: false,
    tablesAvailable: true,
    flash: { active: false, text: "", until: "" },
  },
};

export const MOCK_PUSH: PushState = { message: "", rateUsed: 2, rateMax: 4 };

export const MOCK_PROMOS: PromoCode[] = [
  { code: "VIP-AUG-08", desc: "Guest list — Full Moon Rooftop", maxUses: 50, used: 31 },
  { code: "LADIES2FOR1", desc: "2-for-1 before 11pm", maxUses: 200, used: 88 },
];

export const MOCK_PERKS: RankPerk[] = [
  { tier: "Gold", perk: "Skip-the-line + welcome shot" },
  { tier: "Silver", perk: "Priority guest list" },
  { tier: "Bronze", perk: "Early-bird ticket alerts" },
];

export const MOCK_BOOST: BoostSlot = { active: false, night: "2026-08-15", price: 40 };

export const MOCK_TEAM: TeamMember[] = [
  { id: "tm1", name: "Rana Aziz", email: "rana@sirensdubai.com", role: "Owner" },
  { id: "tm2", name: "Marco Reyes", email: "marco@sirensdubai.com", role: "Manager" },
  { id: "tm3", name: "Leila Haddad", email: "leila@sirensdubai.com", role: "Door staff" },
];

export const MOCK_ACTIVITY: ActivityEntry[] = [
  { who: "Jamie Rios", what: "Changed Sunset to Sunrise price tier", when: "Aug 5, 14:02" },
  { who: "Priya Shah", what: "Set live status to Filling Up (Sirens Dubai)", when: "Aug 4, 23:10" },
  { who: "Jamie Rios", what: "Published Techno Fridays (Aug 14)", when: "Aug 2, 09:44" },
];

export const MOCK_REVIEWS: VenueReview[] = [
  {
    id: "r1",
    author: "@mira_k",
    rating: 5,
    text: "Best rooftop set of the summer. Door was quick even at 1am and the terrace never felt packed.",
    reply: "",
    posted: "Thank you Mira — Kalima is back on the decks the first Friday of every month.",
    postedWhen: "Aug 6",
    flagged: false,
  },
  {
    id: "r2",
    author: "@johndoe22",
    rating: 1,
    text: "Obvious spam review with a promo link.",
    reply: "",
    posted: "",
    postedWhen: "",
    flagged: true,
  },
  {
    id: "r3",
    author: "@tokyo_afterhours",
    rating: 4,
    text: "Sound system needs work but great crowd.",
    reply: "",
    posted: "",
    postedWhen: "",
    flagged: false,
  },
];

export const MOCK_INBOX: InboxMessage[] = [
  {
    id: "m1",
    subject: "Photo policy reminder",
    from: "Trust & Safety",
    date: "Aug 3",
    type: "policy",
    body: "Hero images must show the actual venue interior or entrance — stock photos will be removed.",
    open: false,
  },
  {
    id: "m2",
    subject: "Event flagged for review: Sunset to Sunrise",
    from: "Content Review",
    date: "Aug 5",
    type: "violation",
    body: "Automated scan flagged the lineup name for duplicate-event review. ETA ~2h.",
    open: false,
  },
  {
    id: "m3",
    subject: "Appeal decision: Warehouse 9 listing",
    from: "Trust & Safety",
    date: "Jul 29",
    type: "appeal",
    body: "Your appeal was upheld — the listing has been reinstated.",
    open: false,
  },
];

/** Overview KPIs and the analytics panels are presentational placeholders. */
/**
 * The four headline metrics on Home → Live operations. `icon` is a key the
 * section maps to a lucide component; `tone` picks the icon/delta colours from
 * the M3 token set.
 */
export const MOCK_KPIS: {
  icon: "rsvp" | "revenue" | "views" | "ai";
  value: string;
  label: string;
  delta: string;
  tone: "primary" | "tertiary";
  deltaTone: "up" | "down";
}[] = [
  {
    icon: "rsvp",
    value: "268",
    label: "RSVPs tonight",
    delta: "+18%",
    tone: "primary",
    deltaTone: "up",
  },
  {
    icon: "revenue",
    value: "21.4k",
    label: "Ticket revenue (AED)",
    delta: "+7%",
    tone: "tertiary",
    deltaTone: "up",
  },
  {
    icon: "views",
    value: "9,120",
    label: "Profile views, 7d",
    delta: "−4%",
    tone: "primary",
    deltaTone: "down",
  },
  {
    icon: "ai",
    value: "74",
    label: "AI recommendation score",
    delta: "+6",
    tone: "tertiary",
    deltaTone: "up",
  },
];

export const MOCK_FUNNEL = { views: 8400, saves: 1120, directions: 640 };

export const MOCK_AGE_BANDS = [
  { label: "18–24", pct: "38%" },
  { label: "25–34", pct: "44%" },
  { label: "35–44", pct: "14%" },
  { label: "45+", pct: "4%" },
];

export const MOCK_LOCAL_SPLIT = [
  { label: "Local", pct: "61%" },
  { label: "Tourist", pct: "39%" },
];

export const MOCK_GENRE_FOLLOWS = [
  { label: "Techno", pct: "52%" },
  { label: "House", pct: "31%" },
  { label: "Afrobeats", pct: "17%" },
];

export const MOCK_AI_INTENTS = [
  { label: "techno tonight", count: 410 },
  { label: "rooftop, cheap", count: 260 },
  { label: "open late near me", count: 180 },
];

export const MOCK_AI_RECOMMEND_COUNT = "1,240";
