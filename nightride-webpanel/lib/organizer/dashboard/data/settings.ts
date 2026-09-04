/**
 * `users/{uid}/settings/preferences` <-> `OrganizerPreferences`.
 *
 * `firestore.rules` allows this self-write wide open (`match /settings/{docId}
 * { allow read, write: if isSelf(uid); }`, no shape enforced server-side), so
 * this file is the only place these fields are validated. Defensive parsing —
 * `typeof` guards per field — so a legacy or partial document degrades to
 * `DEFAULT_PREFERENCES` instead of throwing.
 */
import { doc, type DocumentReference } from "firebase/firestore";
import { getDb } from "@/lib/firebase";

export interface OrganizerPreferences {
  guestList: boolean;
  autoPublish: boolean;
  crowdData: boolean;
  payoutTwoFactor: boolean;
}

export const DEFAULT_PREFERENCES: OrganizerPreferences = {
  guestList: true,
  autoPublish: false,
  crowdData: true,
  payoutTwoFactor: true,
};

/** Static copy for `SettingsSection`'s preference rows — keyed to `OrganizerPreferences`' own fields. */
export const PREFERENCE_FIELDS: { id: keyof OrganizerPreferences; label: string; desc: string }[] = [
  {
    id: "guestList",
    label: "Guest list notifications",
    desc: "Push me when an RSVP list passes 80% of capacity.",
  },
  {
    id: "autoPublish",
    label: "Auto-publish recurring nights",
    desc: "Weekly residencies publish without re-review.",
  },
  {
    id: "crowdData",
    label: "Share anonymised crowd data",
    desc: "Helps the assistant recommend your venue more accurately.",
  },
  {
    id: "payoutTwoFactor",
    label: "Two-factor on payouts",
    desc: "Require SMS confirmation for any payout change.",
  },
];

export function preferencesDocRef(uid: string): DocumentReference {
  return doc(getDb(), "users", uid, "settings", "preferences");
}

export function parsePreferences(raw: Record<string, unknown> | undefined): OrganizerPreferences {
  const d = raw ?? {};
  return {
    guestList: typeof d.guestList === "boolean" ? d.guestList : DEFAULT_PREFERENCES.guestList,
    autoPublish: typeof d.autoPublish === "boolean" ? d.autoPublish : DEFAULT_PREFERENCES.autoPublish,
    crowdData: typeof d.crowdData === "boolean" ? d.crowdData : DEFAULT_PREFERENCES.crowdData,
    payoutTwoFactor:
      typeof d.payoutTwoFactor === "boolean" ? d.payoutTwoFactor : DEFAULT_PREFERENCES.payoutTwoFactor,
  };
}
