import { describe, expect, it } from "vitest";
import { Timestamp } from "firebase/firestore";
import { hasUnread, orderInbox, orderReviews, parseInboxMessage, parseVenueReview, shortDate } from "./engagement";

const ts = (ms: number) => Timestamp.fromMillis(ms);

describe("parseVenueReview", () => {
  it("maps a report with no reply", () => {
    const raw = {
      username: "@mira_k",
      vibeRating: 5,
      comment: "Great night.",
      flaggedByOwner: false,
      reply: null,
      createdAt: ts(1000),
    };
    const r = parseVenueReview("r1", raw, { draft: "", editing: false });
    expect(r).toEqual({
      id: "r1",
      author: "@mira_k",
      rating: 5,
      text: "Great night.",
      reply: "",
      posted: "",
      postedWhen: "",
      flagged: false,
    });
  });

  it("surfaces a posted reply's text and formatted date", () => {
    const raw = {
      username: "@mira_k",
      vibeRating: 4,
      comment: "Solid.",
      flaggedByOwner: true,
      reply: { text: "Thanks!", byUid: "u1", byName: "Venue", at: ts(Date.UTC(2026, 7, 6, 12)) },
    };
    const r = parseVenueReview("r2", raw, { draft: "draft text", editing: false });
    expect(r.posted).toBe("Thanks!");
    expect(r.postedWhen).toBe("Aug 6");
    expect(r.flagged).toBe(true);
    // The composer draft is always the overlay's value, independent of the posted reply.
    expect(r.reply).toBe("draft text");
  });

  it("blanks the posted reply while editing, without touching the raw doc", () => {
    const raw = { reply: { text: "Original reply", at: ts(1000) } };
    const r = parseVenueReview("r3", raw, { draft: "Original reply", editing: true });
    expect(r.posted).toBe("");
    expect(r.postedWhen).toBe("");
    expect(r.reply).toBe("Original reply");
  });

  it("defaults every field for a missing/legacy document", () => {
    const r = parseVenueReview("r4", undefined, { draft: "", editing: false });
    expect(r).toEqual({
      id: "r4",
      author: "Guest",
      rating: 0,
      text: "",
      reply: "",
      posted: "",
      postedWhen: "",
      flagged: false,
    });
  });
});

describe("orderReviews", () => {
  it("sorts newest createdAt first, undated docs last", () => {
    const rawDocs = {
      old: { createdAt: ts(1000) },
      newest: { createdAt: ts(3000) },
      undated: {},
      mid: { createdAt: ts(2000) },
    };
    expect(orderReviews(rawDocs)).toEqual(["newest", "mid", "old", "undated"]);
  });
});

describe("parseInboxMessage", () => {
  it("maps a policy message and honours the passed-in open state", () => {
    const raw = {
      subject: "Photo policy reminder",
      from: "Trust & Safety",
      type: "policy",
      body: "Hero images must show the actual venue.",
      at: ts(Date.UTC(2026, 7, 3, 12)),
      readAt: null,
    };
    expect(parseInboxMessage("m1", raw, false)).toEqual({
      id: "m1",
      subject: "Photo policy reminder",
      from: "Trust & Safety",
      date: "Aug 3",
      type: "policy",
      body: "Hero images must show the actual venue.",
      open: false,
    });
    expect(parseInboxMessage("m1", raw, true).open).toBe(true);
  });

  it("falls back to 'policy' for an unrecognised type, and blanks for a missing document", () => {
    expect(parseInboxMessage("m2", { type: "not-a-real-type" }, false).type).toBe("policy");
    expect(parseInboxMessage("m3", undefined, false)).toEqual({
      id: "m3",
      subject: "",
      from: "",
      date: "",
      type: "policy",
      body: "",
      open: false,
    });
  });
});

describe("orderInbox / hasUnread", () => {
  it("orders newest-at first", () => {
    const rawDocs = { a: { at: ts(1000) }, b: { at: ts(3000) }, c: { at: ts(2000) } };
    expect(orderInbox(rawDocs)).toEqual(["b", "c", "a"]);
  });

  it("is true while any message has no readAt, false once every message is read", () => {
    const unread = { a: { readAt: ts(1) }, b: { readAt: null } };
    const allRead = { a: { readAt: ts(1) }, b: { readAt: ts(2) } };
    expect(hasUnread(unread)).toBe(true);
    expect(hasUnread(allRead)).toBe(false);
    expect(hasUnread({})).toBe(false);
  });

  it("stays false across what a reload looks like: fresh raw docs sourced with readAt already set", () => {
    // Simulates the acceptance criterion at the data layer: once `readAt` has
    // landed in Firestore, a fresh snapshot (as if freshly loaded after a
    // reload) must derive hasUnread === false — a dot that comes back would
    // mean the write never actually persisted.
    const afterReload = { m1: { readAt: ts(555) } };
    expect(hasUnread(afterReload)).toBe(false);
  });
});

describe("shortDate", () => {
  it("formats a Timestamp as 'MMM d' and returns '' for anything else", () => {
    expect(shortDate(ts(Date.UTC(2026, 0, 9, 12)))).toBe("Jan 9");
    expect(shortDate(null)).toBe("");
    expect(shortDate(undefined)).toBe("");
    expect(shortDate("not a timestamp")).toBe("");
  });
});
