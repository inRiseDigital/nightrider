/**
 * Module-private-style doc/collection ref helpers, mirroring `lib/admin/firestore.ts`.
 * Exported (rather than module-private) so a later task's real query functions
 * can import them directly instead of re-deriving paths.
 */
import { collection, doc, type CollectionReference, type DocumentReference } from "firebase/firestore";
import { getDb } from "@/lib/firebase";

export function venueDocRef(id: string): DocumentReference {
  return doc(getDb(), "venues", id);
}
export function venuesCol(): CollectionReference {
  return collection(getDb(), "venues");
}
export function eventDocRef(id: string): DocumentReference {
  return doc(getDb(), "events", id);
}
export function eventsCol(): CollectionReference {
  return collection(getDb(), "events");
}
export function venueActivityCol(venueId: string): CollectionReference {
  return collection(getDb(), "venues", venueId, "activity");
}
export function venueTeamCol(venueId: string): CollectionReference {
  return collection(getDb(), "venues", venueId, "team");
}
export function venueMenuSectionsCol(venueId: string): CollectionReference {
  return collection(getDb(), "venues", venueId, "menuSections");
}
export function venueMetricsDocRef(venueId: string, periodId: string): DocumentReference {
  return doc(getDb(), "venues", venueId, "metrics", periodId);
}
export function venueAiVisibilityDocRef(venueId: string): DocumentReference {
  return doc(getDb(), "venues", venueId, "aiVisibility", "current");
}
export function venuePromotionsCol(venueId: string): CollectionReference {
  return collection(getDb(), "venues", venueId, "promotions");
}
export function venuePushCampaignsCol(venueId: string): CollectionReference {
  return collection(getDb(), "venues", venueId, "pushCampaigns");
}
export function venuePromoStateDocRef(venueId: string): DocumentReference {
  return doc(getDb(), "venues", venueId, "promoState", "current");
}
export function venueBoostsCol(venueId: string): CollectionReference {
  return collection(getDb(), "venues", venueId, "boosts");
}
export function venueRankPerksDocRef(venueId: string): DocumentReference {
  return doc(getDb(), "venues", venueId, "rankPerks", "current");
}
export function venueReportsCol(): CollectionReference {
  return collection(getDb(), "venueReports");
}
export function userInboxCol(uid: string): CollectionReference {
  return collection(getDb(), "users", uid, "inbox");
}
export function userDocRef(uid: string): DocumentReference {
  return doc(getDb(), "users", uid);
}
