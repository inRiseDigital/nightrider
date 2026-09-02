"use client";

import { useCallback, useMemo, useRef, useState, type DragEvent } from "react";
import {
  ArrowLeft,
  AtSign,
  Camera,
  ChevronRight,
  Clock,
  Crown,
  ExternalLink,
  Globe,
  Heart,
  ImagePlus,
  Link2,
  Lock,
  MapPin,
  Martini,
  MessageCircle,
  Music2,
  Sparkle,
  ThumbsUp,
  Users,
  Wifi,
  X as CloseIcon,
} from "lucide-react";
import {
  gallerySlotIds,
  heroSlotId,
  menuItemSlotId,
  useNow,
  useOrganizerDashboard,
} from "@/lib/organizer/dashboard/store";
import { hoursTextFor, isOpenOn, mondayFirstIndex, toISODate } from "@/lib/organizer/dashboard/format";
import type { SocialLink } from "@/lib/organizer/dashboard/types";
import { SectionEyebrow } from "../ui/Primitives";

const PINK = "#FF3D73";
const LIME = "#DFFF2F";
const CREAM = "#FAF5EF";
const INK = "#191519";
const MUTED = "#6E6469";
const HAIRLINE = "#EFE4DA";

/** Shown only while the venue has no menu of its own. */
const FOOD_CARDS = [
  { key: "f1", title: "Signature Drinks", body: "Creative cocktails, premium spirits & local beers." },
  { key: "f2", title: "Bar Bites", body: "Tasty bites to keep you going all night." },
  { key: "f3", title: "Bottle Service", body: "Premium bottles & VIP packages available." },
  { key: "f4", title: "Late Night Menu", body: "Kitchen open until 3AM every night." },
];

function priceTier(coverMin: number, currency: string) {
  const cheapMax = currency === "¥" ? 1500 : 60;
  const moderateMax = currency === "¥" ? 3500 : 150;
  if (coverMin <= cheapMax) return { glyphs: "$", word: "Cheap" };
  if (coverMin <= moderateMax) return { glyphs: "$$", word: "Moderate" };
  return { glyphs: "$$$", word: "Premium" };
}

function socialIconFor(network: string) {
  switch (network) {
    case "instagram":
      return AtSign;
    case "tiktok":
      return Music2;
    case "facebook":
      return ThumbsUp;
    case "x":
      return Music2;
    case "youtube":
      return ExternalLink;
    case "website":
      return Globe;
    case "whatsapp":
      return MessageCircle;
    default:
      return Link2;
  }
}

function networkLabel(link: SocialLink) {
  return link.network.toUpperCase();
}

/**
 * Click-to-browse / drag-and-drop upload for one image slot, styled for the
 * cream preview rather than the M3 editor. This is the venue's only image
 * upload surface — the Profile tab just displays what's set here.
 */
function useImageUpload(slotId: string) {
  const { setImage } = useOrganizerDashboard();
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const readFile = useCallback(
    (file: File | undefined) => {
      if (!file || !file.type.startsWith("image/")) return;
      const reader = new FileReader();
      reader.onload = () => {
        if (typeof reader.result === "string") setImage(slotId, reader.result);
      };
      reader.readAsDataURL(file);
    },
    [slotId, setImage]
  );

  const openPicker = useCallback(() => inputRef.current?.click(), []);

  const onDrop = useCallback(
    (e: DragEvent<HTMLDivElement>) => {
      e.preventDefault();
      e.stopPropagation();
      setDragging(false);
      readFile(e.dataTransfer.files?.[0]);
    },
    [readFile]
  );

  const onDragOver = useCallback((e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();
    setDragging(true);
  }, []);

  const onDragLeave = useCallback(() => setDragging(false), []);

  const input = (
    <input
      ref={inputRef}
      type="file"
      accept="image/*"
      className="sr-only"
      onChange={(e) => {
        readFile(e.target.files?.[0]);
        e.target.value = "";
      }}
    />
  );

  return { dragging, openPicker, onDrop, onDragOver, onDragLeave, input };
}

function RemoveButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
      title="Remove image"
      aria-label="Remove image"
      className="absolute right-2 top-2 z-10 flex h-6 w-6 items-center justify-center rounded-full border border-white/20 bg-black/50 text-white opacity-0 backdrop-blur transition-opacity group-hover:opacity-100"
    >
      <CloseIcon size={12} />
    </button>
  );
}

/**
 * Faithful phone-frame render of the consumer app's Venue Detail screen,
 * matching `Venue Detail.dc.html` — the cream/pink/lime consumer brand, not
 * the M3 organizer chrome. This is deliberately a different visual system:
 * it's "the phone", not another dashboard panel.
 */
export function VenueAppPreview() {
  const { profile, editingVenue, events, images, requestRemoveImage } = useOrganizerDashboard();
  const now = useNow();
  const [liked, setLiked] = useState(false);
  const [sheetOpen, setSheetOpen] = useState(false);

  const hero = heroSlotId(editingVenue);
  const gallery = gallerySlotIds(editingVenue);
  const heroUpload = useImageUpload(hero);

  const dayIdx = now ? mondayFirstIndex(now) : 0;
  const todayISO = now ? toISODate(now) : "";
  const openToday = now ? isOpenOn(profile, todayISO, dayIdx) : true;

  const tier = priceTier(profile.coverMin, profile.currency);

  const ageBadge = profile.agePolicy.match(/\d+/)?.[0];

  /** Real menu items, sold-out ones hidden — guests only see what they can order. */
  const menuCards = useMemo(() => {
    const cards = profile.menu.flatMap((section) =>
      section.items
        .filter((item) => !item.soldOut && item.name.trim())
        .map((item) => ({
          key: item.id,
          title: item.name,
          body: item.desc || section.name,
          price: item.price ? `${profile.currency}${item.price.toLocaleString()}` : "",
          photo: images[menuItemSlotId(editingVenue, item.id)],
        }))
    );

    if (cards.length) return cards;
    return FOOD_CARDS.map((c) => ({ ...c, price: "", photo: undefined as string | undefined }));
  }, [profile.menu, profile.currency, images, editingVenue]);

  const highlights = useMemo(() => {
    const upcoming = events
      .filter((e) => e.venue === editingVenue && (e.status === "scheduled" || e.status === "live"))
      .sort((a, b) => a.date.localeCompare(b.date))
      .slice(0, 4)
      .map((e) => {
        const d = new Date(`${e.date}T00:00:00`);
        return {
          key: e.id,
          title: e.name,
          day: d.toLocaleDateString("en-US", { weekday: "short" }).toUpperCase(),
          meta: `${e.startTime}–${e.endTime}`,
        };
      });

    if (upcoming.length) return upcoming;
    return [
      { key: "h1", title: "Techno After Hours", day: "TONIGHT", meta: "Rooftop • 11PM" },
      { key: "h2", title: "Ladies Night", day: "FRI", meta: "Free entry before 12AM" },
      { key: "h3", title: "Cocktail Hour", day: "SAT", meta: "2-for-1 cocktails" },
    ];
  }, [events, editingVenue]);

  return (
    <div className="flex flex-col gap-3.5 lg:sticky lg:top-0">
      <SectionEyebrow>Live preview — how it appears in the app</SectionEyebrow>

      <div
        className="mx-auto w-full max-w-[340px] overflow-hidden rounded-[28px] shadow-[0_30px_80px_rgba(0,0,0,0.6)]"
        style={{ background: CREAM, color: INK, fontFamily: "var(--font-sans), sans-serif" }}
      >
        <div className="nr-phone-scroll max-h-[720px] overflow-y-auto overflow-x-hidden">
          {/* Hero — click, drop, or drag an image here to set it; this is the only
              place to change the hero photo, the Profile tab just displays it. */}
          <div
            role="button"
            tabIndex={0}
            onClick={heroUpload.openPicker}
            onKeyDown={(e) => e.key === "Enter" && heroUpload.openPicker()}
            onDrop={heroUpload.onDrop}
            onDragOver={heroUpload.onDragOver}
            onDragLeave={heroUpload.onDragLeave}
            aria-label={images[hero] ? "Replace hero photo" : "Add hero photo"}
            className="group relative h-[220px] cursor-pointer"
            style={{
              background:
                "radial-gradient(120% 90% at 20% 20%, #3B1C6B 0%, transparent 60%), radial-gradient(110% 80% at 78% 12%, #1E4FA8 0%, transparent 58%), radial-gradient(90% 70% at 55% 45%, #C2277E 0%, transparent 62%), linear-gradient(180deg, #1A0A22 0%, #0B0510 100%)",
            }}
          >
            {heroUpload.input}
            {images[hero] ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={images[hero]} alt="" className="absolute inset-0 h-full w-full object-cover" />
            ) : (
              <div className="absolute inset-0 flex flex-col items-center justify-center gap-1.5 text-white/70">
                <ImagePlus size={22} />
                <span className="text-[11px]">Drop your hero photo</span>
              </div>
            )}
            <div
              className={`pointer-events-none absolute inset-0 flex items-center justify-center bg-black/50 opacity-0 transition-opacity group-hover:opacity-100 ${
                heroUpload.dragging ? "opacity-100" : ""
              }`}
            >
              <span className="flex items-center gap-1.5 text-xs font-semibold text-white">
                <Camera size={15} />
                {images[hero] ? "Replace photo" : "Add photo"}
              </span>
            </div>
            <div
              className="pointer-events-none absolute inset-0"
              style={{
                background:
                  "linear-gradient(180deg, rgba(6,4,10,0.55) 0%, rgba(6,4,10,0) 34%, rgba(6,4,10,0.82) 100%)",
              }}
            />

            <div className="pointer-events-none absolute left-0 right-0 top-0 flex h-9 items-end justify-between px-4 pb-1 text-white">
              <span className="text-xs font-semibold">10:05</span>
              <Wifi size={13} />
            </div>

            <button
              onClick={(e) => {
                e.stopPropagation();
                setLiked((v) => !v);
              }}
              aria-label="Toggle favorite"
              className="absolute right-3 top-11 flex h-9 w-9 items-center justify-center rounded-full border border-white/15 bg-black/40 text-white backdrop-blur"
            >
              <Heart size={17} fill={liked ? PINK : "none"} color={liked ? PINK : "#fff"} />
            </button>
            <div className="absolute left-3 top-11 flex h-9 w-9 items-center justify-center rounded-full border border-white/15 bg-black/40 text-white backdrop-blur">
              <ArrowLeft size={17} />
            </div>
            {images[hero] && <RemoveButton onClick={() => requestRemoveImage(hero)} />}

            <div
              className="pointer-events-none absolute left-4 bottom-14 rounded-full px-3 py-1 text-[10px] font-bold tracking-widest text-white"
              style={{ background: PINK }}
            >
              CLUB
            </div>
            <div
              className="pointer-events-none absolute left-4 right-16 bottom-4 font-display text-[26px] uppercase leading-none tracking-wide text-white"
            >
              {profile.name}
            </div>
            <div className="pointer-events-none absolute right-4 bottom-4 rounded-full border border-white/15 bg-black/40 px-2.5 py-1 font-mono text-[10px] text-white">
              1/{Math.max(gallery.length, 1)}
            </div>
          </div>

          {/* Info sheet */}
          <div className="relative -mt-4 rounded-t-[20px] pb-6" style={{ background: CREAM }}>
            <div className="nr-phone-scroll flex gap-2 overflow-x-auto px-4 pb-1 pt-4">
              <Chip bg="#FF3D73" fg="#fff">
                CLUB • NIGHTLIFE
              </Chip>
              <Chip bg="#EAE7FB" fg="#2C2550" icon={<Users size={12} />}>
                Busy Tonight
              </Chip>
              <Chip bg="#EFE3DA" fg="#3A2A24">
                <span style={{ color: PINK, fontWeight: 700 }}>{tier.glyphs}</span> {tier.word}
              </Chip>
              {profile.genres.map((g) => (
                <Chip key={g} bg="#F1E3EA" fg="#5A2740">
                  {g}
                </Chip>
              ))}
            </div>

            <div className="flex items-start justify-between gap-3 px-4 pt-3">
              <div className="flex flex-col gap-2.5 pt-1">
                <div className="flex items-center gap-2.5 text-[13px]">
                  <Clock size={16} color={PINK} />
                  <span>{openToday ? `Open • ${hoursTextFor(profile, dayIdx)}` : "Closed today"}</span>
                </div>
                <div className="flex items-center gap-2.5 text-[13px]">
                  <MapPin size={16} color={PINK} />
                  <span>{profile.address || profile.city}</span>
                </div>
              </div>
              <div className="flex shrink-0 flex-col items-end gap-2">
                <div
                  className="flex items-center gap-1.5 rounded-lg border-2 px-2.5 py-1.5"
                  style={{ background: "#170A11", borderColor: PINK }}
                >
                  <Crown size={14} color="#FF6B95" />
                  <span className="font-display text-[11px] tracking-wide" style={{ color: "#FF6B95" }}>
                    TOP SPOT
                  </span>
                </div>
                <div
                  className="rounded-full px-3.5 py-1.5 text-[11px] font-semibold"
                  style={{ background: LIME, color: "#141400" }}
                >
                  From {profile.currency}
                  {profile.coverMin}
                </div>
              </div>
            </div>

            <Section title="ABOUT">
              <p className="text-[12px] leading-relaxed" style={{ color: "#3A3438" }}>
                {profile.about || "No description yet."}
              </p>
            </Section>

            <Section title="WHAT TO EXPECT">
              <div className="grid grid-cols-5 gap-1">
                <Expect Icon={Music2} label="House Music" color="#3FB8AC" />
                <Expect Icon={Users} label="Busy Tonight" color={PINK} />
                <Expect
                  label={ageBadge ? `${ageBadge}+` : "All ages"}
                  color={PINK}
                  circleLabel={ageBadge ? `${ageBadge}+` : undefined}
                />
                <Expect
                  Icon={Crown}
                  label={profile.amenities.includes("VIP Tables") ? "VIP Tables" : profile.amenities[0] ?? "Amenities"}
                  color="#3FB8AC"
                />
                <Expect Icon={Martini} label="Cocktails" color={PINK} />
              </div>
            </Section>

            <Section title="FOOD & DRINKS" action="View menu">
              <div className="nr-phone-scroll flex gap-3 overflow-x-auto pb-1">
                {menuCards.map((card) => (
                  <div
                    key={card.key}
                    className="flex w-[200px] shrink-0 overflow-hidden rounded-xl border"
                    style={{ background: "#FFFDFA", borderColor: HAIRLINE }}
                  >
                    <div className="w-20 shrink-0 overflow-hidden" style={{ background: "#2A1A10" }}>
                      {card.photo && (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={card.photo} alt="" className="h-full w-full object-cover" />
                      )}
                    </div>
                    <div className="flex min-w-0 flex-col gap-1 px-3 py-2.5">
                      <p className="text-[12px] font-semibold leading-tight">{card.title}</p>
                      <p className="text-[10px] leading-snug" style={{ color: MUTED }}>
                        {card.body}
                      </p>
                      {card.price && (
                        <p className="text-[10px] font-semibold" style={{ color: PINK }}>
                          {card.price}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </Section>

            <Section title="TONIGHT'S HIGHLIGHTS">
              <div className="nr-phone-scroll flex gap-3 overflow-x-auto pb-1">
                {highlights.map((h) => (
                  <div
                    key={h.key}
                    className="w-[170px] shrink-0 overflow-hidden rounded-xl border"
                    style={{ background: "#FFFDFA", borderColor: HAIRLINE }}
                  >
                    <div
                      className="relative h-[76px] p-2.5"
                      style={{
                        background:
                          "radial-gradient(100% 80% at 30% 25%, #7B2AA8 0%, transparent 62%), radial-gradient(90% 70% at 80% 60%, #C2277E 0%, transparent 60%), linear-gradient(160deg, #1B0A24 0%, #0A040E 100%)",
                      }}
                    >
                      <p className="font-display text-[15px] uppercase leading-tight text-white">{h.title}</p>
                      <div
                        className="absolute bottom-2 left-2.5 rounded px-1.5 py-0.5 text-[8px] font-bold tracking-wide"
                        style={{ background: LIME, color: "#141400" }}
                      >
                        {h.day}
                      </div>
                    </div>
                    <p className="px-2.5 py-2 text-[10px]" style={{ color: MUTED }}>
                      {h.meta}
                    </p>
                  </div>
                ))}
              </div>
            </Section>

            {profile.socialLinks.length > 0 && (
              <Section title="SOCIALS">
                <div className="flex flex-col gap-2">
                  {profile.socialLinks.map((link, i) => {
                    const Icon = socialIconFor(link.network);
                    return (
                      <div
                        key={i}
                        className="flex items-center gap-2.5 rounded-lg border px-2.5 py-2"
                        style={{ background: "#FFFDFA", borderColor: HAIRLINE }}
                      >
                        <Icon size={17} color={PINK} />
                        <div className="min-w-0 flex-1">
                          <p className="text-[9px] font-bold tracking-wide">{networkLabel(link)}</p>
                          <p className="truncate text-[9.5px]" style={{ color: MUTED }}>
                            {link.value || "—"}
                          </p>
                        </div>
                        <ExternalLink size={13} color="#4A4247" />
                      </div>
                    );
                  })}
                </div>
              </Section>
            )}

            <Section title="GALLERY">
              <div className="nr-phone-scroll flex gap-2 overflow-x-auto pb-1">
                {gallery.map((slotId) => (
                  <GalleryTile key={slotId} slotId={slotId} src={images[slotId]} onRemove={requestRemoveImage} />
                ))}
              </div>
            </Section>

            <Section title="LOCATION">
              <div
                className="flex overflow-hidden rounded-xl border"
                style={{ background: "#FFFDFA", borderColor: HAIRLINE }}
              >
                <div
                  className="relative h-24 w-[160px] shrink-0"
                  style={{ background: "linear-gradient(160deg, #1B1D20 0%, #0B0C0E 100%)" }}
                >
                  <MapPin
                    size={26}
                    color={PINK}
                    className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2"
                  />
                </div>
                <div className="flex flex-1 items-start justify-between gap-2 px-3 py-2.5">
                  <div>
                    <p className="text-[11px] font-semibold">{profile.name}</p>
                    <p className="mt-0.5 text-[10px] leading-relaxed" style={{ color: MUTED }}>
                      {profile.address}
                      <br />
                      {profile.city}
                    </p>
                  </div>
                  <ExternalLink size={15} color={PINK} />
                </div>
              </div>
            </Section>
          </div>
        </div>

        {/* Sticky CTA */}
        <div
          className="p-3.5"
          style={{ background: `linear-gradient(180deg, rgba(250,245,239,0) 0%, ${CREAM} 42%)` }}
        >
          <button
            onClick={() => setSheetOpen(true)}
            className="flex h-12 w-full items-center justify-center gap-2.5 rounded-xl"
            style={{ background: LIME }}
          >
            <Lock size={17} color="#141400" />
            <span className="font-display text-[16px] uppercase tracking-wide" style={{ color: "#141400" }}>
              Plan My Night Out
            </span>
          </button>
        </div>

        {sheetOpen && (
          <div className="absolute inset-0 z-10">
            <div className="absolute inset-0 bg-black/60" onClick={() => setSheetOpen(false)} />
            <div
              className="absolute inset-x-0 bottom-0 rounded-t-[20px] p-4 pb-5"
              style={{ background: CREAM }}
            >
              <div className="mx-auto mb-3.5 h-1 w-11 rounded-full" style={{ background: "#E0D6CB" }} />
              <div className="flex items-center justify-between">
                <p className="font-display text-lg uppercase tracking-wide">Plan My Night Out</p>
                <button onClick={() => setSheetOpen(false)} aria-label="Close">
                  <CloseIcon size={18} color={MUTED} />
                </button>
              </div>
              <div className="mt-3.5 flex flex-col gap-2">
                <SheetRow icon={<Users size={17} color={PINK} />} title="Group size" sub="4 people" />
                <SheetRow icon={<Clock size={17} color={PINK} />} title="Arrival" sub="11:30PM • before cover" />
                <SheetRow icon={<Crown size={17} color={PINK} />} title="VIP table" sub="Optional" />
              </div>
              <button
                onClick={() => setSheetOpen(false)}
                className="mt-3.5 h-11 w-full rounded-xl"
                style={{ background: PINK }}
              >
                <span className="font-display text-[14px] uppercase tracking-wide text-white">Build My Night</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function Section({
  title,
  action,
  children,
}: {
  title: string;
  action?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="px-4 pt-5">
      <div className="mb-2.5 flex items-center justify-between">
        <div className="flex items-center gap-1.5">
          <span className="text-[10.5px] font-bold tracking-widest">{title}</span>
          <Sparkle size={11} color={PINK} />
        </div>
        {action && (
          <div className="flex items-center gap-1 text-[11px] font-medium" style={{ color: PINK }}>
            {action}
            <ChevronRight size={12} />
          </div>
        )}
      </div>
      {children}
    </div>
  );
}

function Chip({
  bg,
  fg,
  icon,
  children,
}: {
  bg: string;
  fg: string;
  icon?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div
      className="flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full px-3.5 py-2 text-[11px] font-medium"
      style={{ background: bg, color: fg }}
    >
      {icon}
      {children}
    </div>
  );
}

function Expect({
  Icon,
  label,
  color,
  circleLabel,
}: {
  Icon?: typeof Music2;
  label: string;
  color: string;
  circleLabel?: string;
}) {
  return (
    <div className="flex flex-col items-center gap-1.5">
      {circleLabel ? (
        <span
          className="flex h-6 w-6 items-center justify-center rounded-full border text-[9px] font-semibold"
          style={{ borderColor: color, color }}
        >
          {circleLabel}
        </span>
      ) : Icon ? (
        <Icon size={22} color={color} />
      ) : null}
      <span className="text-center text-[9.5px] leading-tight" style={{ color: "#3A3438" }}>
        {label}
      </span>
    </div>
  );
}

function GalleryTile({
  slotId,
  src,
  onRemove,
}: {
  slotId: string;
  src: string | undefined;
  onRemove: (slotId: string) => void;
}) {
  const upload = useImageUpload(slotId);

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={upload.openPicker}
      onKeyDown={(e) => e.key === "Enter" && upload.openPicker()}
      onDrop={upload.onDrop}
      onDragOver={upload.onDragOver}
      onDragLeave={upload.onDragLeave}
      aria-label={src ? "Replace gallery photo" : "Add gallery photo"}
      className="group relative h-[92px] w-[74px] shrink-0 cursor-pointer overflow-hidden rounded-lg border border-dashed"
      style={{
        borderColor: upload.dragging ? PINK : HAIRLINE,
        background: src ? "transparent" : "#FFFDFA",
      }}
    >
      {upload.input}
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt="" className="h-full w-full object-cover" />
      ) : (
        <div className="flex h-full w-full items-center justify-center" style={{ color: MUTED }}>
          <ImagePlus size={16} />
        </div>
      )}
      <div
        className={`pointer-events-none absolute inset-0 flex items-center justify-center bg-black/45 opacity-0 transition-opacity group-hover:opacity-100 ${
          upload.dragging ? "opacity-100" : ""
        }`}
      >
        <Camera size={14} color="#fff" />
      </div>
      {src && <RemoveButton onClick={() => onRemove(slotId)} />}
    </div>
  );
}

function SheetRow({ icon, title, sub }: { icon: React.ReactNode; title: string; sub: string }) {
  return (
    <div
      className="flex items-center gap-2.5 rounded-lg border px-3 py-3"
      style={{ background: "#FFFDFA", borderColor: HAIRLINE }}
    >
      {icon}
      <div className="flex-1">
        <p className="text-[12px] font-semibold">{title}</p>
        <p className="text-[10px]" style={{ color: MUTED }}>
          {sub}
        </p>
      </div>
      <ChevronRight size={14} color={MUTED} />
    </div>
  );
}
