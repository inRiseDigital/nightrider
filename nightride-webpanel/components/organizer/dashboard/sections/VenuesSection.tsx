"use client";

import { Plus, X } from "lucide-react";
import { useOrganizerDashboard, type VenueTab } from "@/lib/organizer/dashboard/store";
import {
  AGE_POLICIES,
  AMENITIES,
  DRESS_CODES,
  GENRES,
} from "@/lib/organizer/dashboard/constants";
import {
  Card,
  Chip,
  FilledButton,
  IconButton,
  SectionLabel,
  Select,
  TextArea,
  TextButton,
  TextField,
  VenueSwitcher,
} from "../ui/Primitives";
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
            className="flex h-8 items-center gap-1.5 rounded-lg border border-dashed border-[var(--m3-outline)] pl-2.5 pr-3.5 text-[13px] font-medium text-[var(--m3-onv)] transition-colors hover:border-[var(--m3-pri)] hover:text-[var(--m3-pri)]"
          >
            <Plus size={16} />
            Add venue
          </button>
        }
      />

      {addingVenue && (
        <Card className="mb-6 flex max-w-[480px] flex-col gap-6">
          <SectionLabel>Add a new venue</SectionLabel>
          <TextField
            label="Venue name"
            value={newVenueName}
            onChange={(e) => setNewVenueName(e.target.value)}
          />
          <TextField
            label="City, country"
            value={newVenueCity}
            onChange={(e) => setNewVenueCity(e.target.value)}
          />
          <div className="flex justify-end gap-2">
            <TextButton onClick={cancelAddVenue}>Cancel</TextButton>
            <FilledButton onClick={createVenue}>Create &amp; verify</FilledButton>
          </div>
        </Card>
      )}

      {!profile.verified ? (
        <VenueVerifyPending />
      ) : (
        <div className="grid grid-cols-1 items-start gap-6 xl:grid-cols-[1.3fr_1fr]">
          <div className="min-w-0">
            <div className="mb-6 flex gap-5 border-b border-[var(--m3-outlinev)]">
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
    <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-2">
      <Card className="flex flex-col gap-6">
        <TextField
          label="Venue name"
          value={profile.name}
          onChange={(e) => setVenueField(editingVenue, "name", e.target.value)}
        />
        <TextField
          label="Address"
          value={profile.address}
          onChange={(e) => setVenueField(editingVenue, "address", e.target.value)}
        />
        <div className="grid grid-cols-2 gap-4">
          <TextField
            label="Capacity"
            type="number"
            mono
            value={profile.capacity}
            onChange={(e) => setVenueField(editingVenue, "capacity", Number(e.target.value) || 0)}
          />
          <Select
            label="Dress code"
            value={profile.dressCode}
            onChange={(e) => setVenueField(editingVenue, "dressCode", e.target.value)}
            options={DRESS_CODES}
          />
        </div>
        <TextArea
          label="About this venue"
          rows={4}
          value={profile.about}
          onChange={(e) => setVenueField(editingVenue, "about", e.target.value)}
        />

        <div>
          <SectionLabel
            className="mb-4"
            trailing={
              <span className="text-xs text-[var(--m3-outline)]">Handle or full URL</span>
            }
          >
            Social links
          </SectionLabel>
          <div className="flex flex-col gap-3">
            {profile.socialLinks.map((link, i) => (
              <div key={i} className="flex items-center gap-2">
                <Select
                  dense
                  aria-label="Network"
                  value={link.network}
                  onChange={(e) => setSocialLinkField(editingVenue, i, "network", e.target.value)}
                  options={SOCIAL_NETWORKS}
                  wrapperClassName="w-[132px] shrink-0"
                />
                <TextField
                  dense
                  aria-label="Handle or URL"
                  value={link.value}
                  onChange={(e) => setSocialLinkField(editingVenue, i, "value", e.target.value)}
                  placeholder="@handle or https://..."
                  wrapperClassName="min-w-0 flex-1"
                />
                <IconButton
                  danger
                  onClick={() => removeSocialLink(editingVenue, i)}
                  aria-label="Remove social link"
                >
                  <X size={18} />
                </IconButton>
              </div>
            ))}
            <FilledButton
              tonal
              icon={<Plus size={18} />}
              onClick={() => addSocialLink(editingVenue)}
              className="self-start"
            >
              Add link
            </FilledButton>
          </div>
        </div>
      </Card>

      <div className="flex flex-col gap-6">
        <ChipGroupCard
          label="Music genres"
          options={GENRES}
          isActive={(g) => profile.genres.includes(g)}
          onToggle={(g) => toggleVenueSetValue(editingVenue, "genres", g)}
        />

        <ChipGroupCard
          label="Age policy"
          options={AGE_POLICIES}
          isActive={(a) => profile.agePolicy === a}
          onToggle={(a) => setVenueField(editingVenue, "agePolicy", a)}
        />

        <ChipGroupCard
          label="Amenities"
          options={AMENITIES}
          isActive={(a) => profile.amenities.includes(a)}
          onToggle={(a) => toggleVenueSetValue(editingVenue, "amenities", a)}
        />

        <Card>
          <SectionLabel className="mb-5">Cover charge ({profile.currency})</SectionLabel>
          <div className="grid grid-cols-2 gap-4">
            <TextField
              label="Minimum"
              type="number"
              mono
              value={profile.coverMin}
              onChange={(e) => setVenueField(editingVenue, "coverMin", Number(e.target.value) || 0)}
            />
            <TextField
              label="Maximum"
              type="number"
              mono
              value={profile.coverMax}
              onChange={(e) => setVenueField(editingVenue, "coverMax", Number(e.target.value) || 0)}
            />
          </div>
        </Card>
      </div>
    </div>
  );
}

function ChipGroupCard({
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
    <Card>
      <SectionLabel className="mb-4">{label}</SectionLabel>
      <div className="flex flex-wrap gap-2">
        {options.map((o) => (
          <Chip key={o} label={o} active={isActive(o)} onClick={() => onToggle(o)} />
        ))}
      </div>
    </Card>
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

  /** Open/closed state chip — 32px like every other chip on the page. */
  const StateChip = ({ closed, onClick }: { closed: boolean; onClick: () => void }) => (
    <button
      onClick={onClick}
      className="h-8 w-[84px] shrink-0 rounded-lg border text-center font-mono text-[11px] font-medium tracking-wide transition-colors"
      style={
        closed
          ? { borderColor: "var(--m3-errc)", background: "var(--m3-errc)", color: "var(--m3-onerrc)" }
          : { borderColor: "var(--m3-succ)", background: "var(--m3-succ)", color: "var(--m3-onsucc)" }
      }
    >
      {closed ? "CLOSED" : "OPEN"}
    </button>
  );

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <SectionLabel className="mb-5">Regular opening hours</SectionLabel>
        <div className="flex flex-col">
          {profile.hours.map((h, i) => (
            <div
              key={h.day}
              className="flex min-h-14 flex-wrap items-center gap-3 border-b border-[var(--m3-outlinev)] py-2 last:border-b-0"
            >
              <span className="w-10 shrink-0 text-[13px] font-medium text-[var(--m3-on)]">
                {h.day}
              </span>
              <StateChip closed={h.closed} onClick={() => toggleDayClosed(editingVenue, i)} />
              {!h.closed && (
                <>
                  <TextField
                    dense
                    mono
                    type="time"
                    aria-label={`${h.day} opening time`}
                    value={h.open}
                    onChange={(e) => setHourField(editingVenue, i, "open", e.target.value)}
                    wrapperClassName="w-[130px]"
                  />
                  <span className="text-[13px] text-[var(--m3-onv)]">to</span>
                  <TextField
                    dense
                    mono
                    type="time"
                    aria-label={`${h.day} closing time`}
                    value={h.close}
                    onChange={(e) => setHourField(editingVenue, i, "close", e.target.value)}
                    wrapperClassName="w-[130px]"
                  />
                </>
              )}
            </div>
          ))}
        </div>
      </Card>

      <Card>
        <SectionLabel
          className="mb-5"
          trailing={
            <TextButton
              icon={<Plus size={18} />}
              onClick={() => addException(editingVenue)}
              className="-mr-2"
            >
              Add exception
            </TextButton>
          }
        >
          Exceptions — holidays, private hire, closures
        </SectionLabel>
        {profile.exceptions.length === 0 ? (
          <p className="text-[13px] text-[var(--m3-outline)]">
            No exceptions set — regular hours apply every week.
          </p>
        ) : (
          <div className="flex flex-col">
            {profile.exceptions.map((ex, i) => (
              <div
                key={i}
                className="flex min-h-14 flex-wrap items-center gap-3 border-b border-[var(--m3-outlinev)] py-2 last:border-b-0"
              >
                <TextField
                  dense
                  aria-label="Exception reason"
                  value={ex.label}
                  onChange={(e) => setExceptionField(editingVenue, i, "label", e.target.value)}
                  placeholder="Reason"
                  wrapperClassName="min-w-[160px] flex-1"
                />
                <TextField
                  dense
                  mono
                  type="date"
                  aria-label="Exception date"
                  value={ex.date}
                  onChange={(e) => setExceptionField(editingVenue, i, "date", e.target.value)}
                  wrapperClassName="w-[160px]"
                />
                <StateChip
                  closed={ex.closed}
                  onClick={() => toggleExceptionClosed(editingVenue, i)}
                />
                <IconButton
                  danger
                  onClick={() => removeException(editingVenue, i)}
                  aria-label={`Remove exception ${ex.label}`}
                >
                  <X size={18} />
                </IconButton>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}

function LinksTab() {
  const { profile, editingVenue, setVenueField } = useOrganizerDashboard();
  return (
    <Card className="flex flex-col gap-6">
      <SectionLabel>Booking</SectionLabel>
      <TextField
        label="Table / booking link"
        mono
        value={profile.tableLink}
        onChange={(e) => setVenueField(editingVenue, "tableLink", e.target.value)}
        placeholder="https://..."
      />
    </Card>
  );
}
