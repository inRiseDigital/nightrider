"use client";

import { X } from "lucide-react";
import { useOrganizerDashboard, type VenueTab } from "@/lib/organizer/dashboard/store";
import {
  AGE_POLICIES,
  AMENITIES,
  DRESS_CODES,
  GENRES,
} from "@/lib/organizer/dashboard/constants";
import { Chip, FieldLabel, SlimInput, SlimTextarea, VenueSwitcher } from "../ui/Primitives";
import { VenueAppPreview } from "./VenueAppPreview";
import { VenueMenuSection } from "./VenueMenuSection";
import { VenueVerifyPending } from "./VenueVerifyPending";

const TABS: { id: VenueTab; label: string }[] = [
  { id: "profile", label: "Profile" },
  { id: "menu", label: "Menu" },
  { id: "hours", label: "Hours" },
  { id: "links", label: "Links" },
];

const SOCIAL_NETWORKS = [
  { value: "instagram", label: "Instagram" },
  { value: "tiktok", label: "TikTok" },
  { value: "facebook", label: "Facebook" },
  { value: "x", label: "X" },
  { value: "youtube", label: "YouTube" },
  { value: "website", label: "Website" },
  { value: "whatsapp", label: "WhatsApp" },
];

export function VenuesSection() {
  const {
    venueOrder,
    venues,
    editingVenue,
    setEditingVenue,
    profile,
    venueTab,
    setVenueTab,
    addingVenue,
    openAddVenue,
    cancelAddVenue,
    newVenueName,
    setNewVenueName,
    newVenueCity,
    setNewVenueCity,
    createVenue,
  } = useOrganizerDashboard();

  return (
    <>
      <VenueSwitcher
        venueOrder={venueOrder}
        venues={venues}
        selected={editingVenue}
        onSelect={setEditingVenue}
        trailing={
          <button
            onClick={openAddVenue}
            className="rounded-lg border border-[var(--m3-outlinev)] px-4 py-2 text-[13px] font-semibold text-[var(--m3-warn)] hover:border-[var(--m3-warn)]/50"
          >
            + Add Venue
          </button>
        }
      />

      {addingVenue && (
        <div className="mb-5 flex max-w-[480px] flex-col gap-3 rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <p className="text-[13px] font-semibold text-[var(--m3-on)]">Add a new venue</p>
          <SlimInput
            value={newVenueName}
            onChange={(e) => setNewVenueName(e.target.value)}
            placeholder="Venue name"
          />
          <SlimInput
            value={newVenueCity}
            onChange={(e) => setNewVenueCity(e.target.value)}
            placeholder="City, Country"
          />
          <div className="flex justify-end gap-2.5">
            <button
              onClick={cancelAddVenue}
              className="rounded-lg px-4 py-2.5 text-xs font-semibold text-[var(--m3-onv)] hover:text-[var(--m3-on)]"
            >
              Cancel
            </button>
            <button
              onClick={createVenue}
              className="rounded-lg bg-[var(--m3-warn)] px-4 py-2.5 text-xs font-semibold text-[var(--m3-onpri)] hover:bg-[var(--m3-warn)]/80"
            >
              Create &amp; Verify
            </button>
          </div>
        </div>
      )}

      {!profile.verified ? (
        <VenueVerifyPending />
      ) : (
        <div className="grid grid-cols-1 items-start gap-5 xl:grid-cols-[1.3fr_1fr]">
          <div className="min-w-0">
            <div className="mb-[18px] flex gap-5 border-b border-[var(--m3-outlinev)]">
              {TABS.map((t) => (
                <button
                  key={t.id}
                  onClick={() => setVenueTab(t.id)}
                  className={`border-b-2 px-0.5 py-2.5 text-[13px] font-semibold transition-colors ${
                    venueTab === t.id
                      ? "border-[var(--m3-pri)] text-[var(--m3-on)]"
                      : "border-transparent text-[var(--m3-onv)] hover:text-[var(--m3-on)]"
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            {venueTab === "profile" && <ProfileTab />}
            {venueTab === "menu" && <VenueMenuSection />}
            {venueTab === "hours" && <HoursTab />}
            {venueTab === "links" && <LinksTab />}
          </div>

          <VenueAppPreview />
        </div>
      )}
    </>
  );
}

function ProfileTab() {
  const {
    profile,
    editingVenue,
    toggleVenueSetValue,
    setVenueField,
    addSocialLink,
    removeSocialLink,
    setSocialLinkField,
  } = useOrganizerDashboard();

  return (
    <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
      <div className="flex flex-col gap-4 rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <div>
          <FieldLabel className="mb-1.5">Venue name</FieldLabel>
          <SlimInput
            value={profile.name}
            onChange={(e) => setVenueField(editingVenue, "name", e.target.value)}
            className="w-full"
          />
        </div>
        <div>
          <FieldLabel className="mb-1.5">Address</FieldLabel>
          <SlimInput
            value={profile.address}
            onChange={(e) => setVenueField(editingVenue, "address", e.target.value)}
            className="w-full"
          />
        </div>
        <div className="grid grid-cols-2 gap-3.5">
          <div>
            <FieldLabel className="mb-1.5">Capacity</FieldLabel>
            <SlimInput
              type="number"
              mono
              value={profile.capacity}
              onChange={(e) => setVenueField(editingVenue, "capacity", Number(e.target.value) || 0)}
              className="w-full"
            />
          </div>
          <div>
            <FieldLabel className="mb-1.5">Dress code</FieldLabel>
            <select
              value={profile.dressCode}
              onChange={(e) => setVenueField(editingVenue, "dressCode", e.target.value)}
              className="w-full rounded-md border px-3 py-2.5 text-sm outline-none"
              style={{
                borderColor: "var(--m3-outline)",
                background: "var(--m3-surf2)",
                color: "var(--m3-on)",
              }}
            >
              {DRESS_CODES.map((d) => (
                <option key={d} value={d}>
                  {d}
                </option>
              ))}
            </select>
          </div>
        </div>
        <div>
          <FieldLabel className="mb-1.5">About this venue</FieldLabel>
          <SlimTextarea
            rows={4}
            value={profile.about}
            onChange={(e) => setVenueField(editingVenue, "about", e.target.value)}
            className="w-full"
          />
        </div>

        <div>
          <div className="mb-2.5 flex items-baseline justify-between">
            <FieldLabel>Social links</FieldLabel>
            <span className="text-[11px] text-[var(--m3-outline)]">Handle or full URL</span>
          </div>
          <div className="flex flex-col gap-2.5">
            {profile.socialLinks.map((link, i) => (
              <div key={i} className="flex items-center gap-2">
                <select
                  value={link.network}
                  onChange={(e) => setSocialLinkField(editingVenue, i, "network", e.target.value)}
                  className="w-[110px] shrink-0 rounded-md border px-2 py-2 text-xs outline-none"
                  style={{
                    borderColor: "var(--m3-outline)",
                    background: "var(--m3-surf2)",
                    color: "var(--m3-onv)",
                  }}
                >
                  {SOCIAL_NETWORKS.map((n) => (
                    <option key={n.value} value={n.value}>
                      {n.label}
                    </option>
                  ))}
                </select>
                <SlimInput
                  value={link.value}
                  onChange={(e) => setSocialLinkField(editingVenue, i, "value", e.target.value)}
                  placeholder="@handle or https://..."
                  className="min-w-0 flex-1 py-2 text-xs"
                />
                <button
                  onClick={() => removeSocialLink(editingVenue, i)}
                  className="shrink-0 text-[var(--m3-outline)] hover:text-red-400"
                  aria-label="Remove social link"
                >
                  <X size={16} />
                </button>
              </div>
            ))}
            <button
              onClick={() => addSocialLink(editingVenue)}
              className="self-start rounded-full px-3.5 py-1.5 text-xs font-semibold"
              style={{ background: "var(--m3-pric)", color: "var(--m3-onpric)" }}
            >
              + Add link
            </button>
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-5">
        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <ChipGroup
            label="Music genres"
            options={GENRES}
            isActive={(g) => profile.genres.includes(g)}
            onToggle={(g) => toggleVenueSetValue(editingVenue, "genres", g)}
          />
        </div>

        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <ChipGroup
            label="Age policy"
            options={AGE_POLICIES}
            isActive={(a) => profile.agePolicy === a}
            onToggle={(a) => setVenueField(editingVenue, "agePolicy", a)}
          />
        </div>

        <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <ChipGroup
            label="Amenities"
            options={AMENITIES}
            isActive={(a) => profile.amenities.includes(a)}
            onToggle={(a) => toggleVenueSetValue(editingVenue, "amenities", a)}
          />
        </div>

        <div className="grid grid-cols-2 gap-3.5 rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
          <div>
            <FieldLabel className="mb-1.5">Cover min ({profile.currency})</FieldLabel>
            <SlimInput
              type="number"
              mono
              value={profile.coverMin}
              onChange={(e) => setVenueField(editingVenue, "coverMin", Number(e.target.value) || 0)}
              className="w-full py-2"
            />
          </div>
          <div>
            <FieldLabel className="mb-1.5">Cover max ({profile.currency})</FieldLabel>
            <SlimInput
              type="number"
              mono
              value={profile.coverMax}
              onChange={(e) => setVenueField(editingVenue, "coverMax", Number(e.target.value) || 0)}
              className="w-full py-2"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

function ChipGroup({
  label,
  options,
  isActive,
  onToggle,
}: {
  label: string;
  options: string[];
  isActive: (o: string) => boolean;
  onToggle: (o: string) => void;
}) {
  return (
    <div>
      <FieldLabel className="mb-2.5">{label}</FieldLabel>
      <div className="flex flex-wrap gap-2">
        {options.map((o) => (
          <Chip key={o} label={o} active={isActive(o)} onClick={() => onToggle(o)} />
        ))}
      </div>
    </div>
  );
}

function HoursTab() {
  const {
    profile,
    editingVenue,
    setHourField,
    toggleDayClosed,
    addException,
    removeException,
    setExceptionField,
    toggleExceptionClosed,
  } = useOrganizerDashboard();

  const closedPill = (closed: boolean) =>
    closed
      ? "border-red-500/30 bg-red-500/10 text-red-400"
      : "border-emerald-500/30 bg-emerald-500/10 text-emerald-400";

  return (
    <>
      <div className="mb-4 rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <FieldLabel className="mb-3">Regular opening hours</FieldLabel>
        {profile.hours.map((h, i) => (
          <div
            key={h.day}
            className="flex flex-wrap items-center gap-3 border-b border-[var(--m3-outlinev)] py-2.5 last:border-b-0"
          >
            <span className="w-[38px] text-[13px] font-semibold text-[var(--m3-on)]">{h.day}</span>
            <button
              onClick={() => toggleDayClosed(editingVenue, i)}
              className={`w-16 rounded-full border px-2.5 py-1 text-center font-mono text-[11px] font-semibold ${closedPill(
                h.closed
              )}`}
            >
              {h.closed ? "CLOSED" : "OPEN"}
            </button>
            {!h.closed && (
              <>
                <SlimInput
                  type="time"
                  mono
                  value={h.open}
                  onChange={(e) => setHourField(editingVenue, i, "open", e.target.value)}
                  className="py-1.5 text-xs"
                />
                <span className="text-xs text-[var(--m3-outline)]">to</span>
                <SlimInput
                  type="time"
                  mono
                  value={h.close}
                  onChange={(e) => setHourField(editingVenue, i, "close", e.target.value)}
                  className="py-1.5 text-xs"
                />
              </>
            )}
          </div>
        ))}
      </div>

      <div className="rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
        <div className="mb-3 flex items-center justify-between">
          <FieldLabel>Exceptions — holidays, private hire, closures</FieldLabel>
          <button
            onClick={() => addException(editingVenue)}
            className="text-xs font-semibold text-[var(--m3-pri)] hover:text-[var(--m3-pric)]"
          >
            + Add exception
          </button>
        </div>
        {profile.exceptions.length === 0 ? (
          <p className="py-2 text-xs text-[var(--m3-outline)]">
            No exceptions set — regular hours apply every week.
          </p>
        ) : (
          profile.exceptions.map((ex, i) => (
            <div
              key={i}
              className="flex flex-wrap items-center gap-2.5 border-b border-[var(--m3-outlinev)] py-2.5 last:border-b-0"
            >
              <SlimInput
                value={ex.label}
                onChange={(e) => setExceptionField(editingVenue, i, "label", e.target.value)}
                placeholder="Reason"
                className="min-w-0 flex-1 py-2 text-xs"
              />
              <SlimInput
                type="date"
                mono
                value={ex.date}
                onChange={(e) => setExceptionField(editingVenue, i, "date", e.target.value)}
                className="py-2 text-xs"
              />
              <button
                onClick={() => toggleExceptionClosed(editingVenue, i)}
                className={`whitespace-nowrap rounded-full border px-2.5 py-1 font-mono text-[11px] font-semibold ${closedPill(
                  ex.closed
                )}`}
              >
                {ex.closed ? "CLOSED" : "OPEN"}
              </button>
              <button
                onClick={() => removeException(editingVenue, i)}
                className="px-1 text-[var(--m3-outline)] hover:text-red-400"
                aria-label={`Remove exception ${ex.label}`}
              >
                <X size={14} />
              </button>
            </div>
          ))
        )}
      </div>
    </>
  );
}

function LinksTab() {
  const { profile, editingVenue, setVenueField } = useOrganizerDashboard();
  return (
    <div className="flex flex-col gap-4 rounded-lg border border-[var(--m3-outlinev)] bg-[var(--m3-surf1)] p-[18px]">
      <div>
        <FieldLabel className="mb-1.5">Table / booking link</FieldLabel>
        <SlimInput
          mono
          value={profile.tableLink}
          onChange={(e) => setVenueField(editingVenue, "tableLink", e.target.value)}
          placeholder="https://..."
          className="w-full"
        />
      </div>
    </div>
  );
}
