// Everything in this file is FABRICATED — there is no OCR pipeline, face-match
// model, duplicate-detection system, or signup-signal collection anywhere in
// this product (see docs/FIRESTORE_SCHEMA.md, and the "real vs mock-only"
// audit that shaped this rebuild). Kept only because product asked to keep the
// review flow visually complete while testing the real parts underneath —
// every consumer of this module MUST render the "Simulated" label next to it.
//
// Deterministic per uid (a tiny string hash, not Math.random()) so the same
// applicant shows the same simulated numbers across reloads instead of
// flickering on every render.

function hashUid(uid: string): number {
  let h = 0;
  for (let i = 0; i < uid.length; i++) {
    h = (h * 31 + uid.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

export interface MockFaceMatch {
  mismatch: boolean;
  score: string;
  verdict: string;
  threshold: string;
}

export function mockFaceMatch(uid: string): MockFaceMatch {
  const mismatch = hashUid(uid) % 3 === 0;
  return mismatch
    ? { mismatch, score: "41%", verdict: "Flagged — below threshold", threshold: "85%" }
    : { mismatch, score: "94%", verdict: "Auto-approved — above threshold", threshold: "85%" };
}

export interface MockNicOcr {
  docType: string;
  fieldsExtracted: string;
  imageQuality: string;
  tamperCheck: string;
  ocrConfidence: string;
}

export function mockNicOcr(uid: string, mismatch: boolean): MockNicOcr {
  return {
    docType: "Sri Lanka NIC — new (12-digit)",
    fieldsExtracted: "8 of 8",
    imageQuality: "Good — no glare or crop",
    tamperCheck: "No edits detected",
    ocrConfidence: mismatch ? "91%" : "98%",
  };
}

export interface MockSignupSignals {
  ip: string;
  device: string;
  emailDomainNote: string;
}

const DEVICES = ["iPhone 15 · iOS 19.2", "Pixel 9 · Android 17", "Galaxy S26 · Android 17"];

export function mockSignupSignals(uid: string, email: string): MockSignupSignals {
  const n = hashUid(uid);
  const domain = email.split("@")[1] || "example.com";
  return {
    ip: `${94 + (n % 40)}.${(n >> 3) % 255}.${(n >> 7) % 255}.${(n >> 11) % 255}`,
    device: DEVICES[n % DEVICES.length],
    emailDomainNote: `${domain} · free provider`,
  };
}

export interface MockDuplicateCheck {
  icon: string;
  tone: "danger" | "warning" | "success";
  title: string;
  body: string;
}

export function mockDuplicateChecks(uid: string, mismatch: boolean): MockDuplicateCheck[] {
  if (!mismatch) {
    return [
      { icon: "check", tone: "success", title: "No duplicate NIC", body: "This NIC number has not been submitted before." },
      { icon: "check", tone: "success", title: "No prior applications", body: "First application from this email and phone." },
    ];
  }
  return [
    { icon: "warning", tone: "danger", title: "Similar NIC on file", body: "A NIC with a close match was used by a rejected application." },
    { icon: "content_copy", tone: "warning", title: "Venue name near-match", body: "This venue name is one character from an existing listing." },
  ];
}

export const MOCK_INSTRUCTION_PRESETS = [
  {
    label: "Standard walkthrough",
    text: "Please record a short video walkthrough of your venue (entrance, main floor, and bar/DJ booth) and send it back here so we can complete your verification.",
  },
  {
    label: "Fire exits & safety",
    text: "Please record a walkthrough showing all fire exits, extinguishers, and posted occupancy limits, in addition to the main floor.",
  },
  {
    label: "Capacity & seating",
    text: "Please record a walkthrough showing the seating layout, bar area, and any VIP or reserved sections so we can confirm your listed capacity.",
  },
];
