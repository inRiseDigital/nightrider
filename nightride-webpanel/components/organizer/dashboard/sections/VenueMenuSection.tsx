"use client";

import { Ban, CheckCircle2, GlassWater, ListPlus, Plus, Trash2, Users, X } from "lucide-react";
import { menuItemSlotId, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { MENU_TAGS, NIGHT_INITIALS } from "@/lib/organizer/dashboard/constants";
import type { MenuItem, MenuSection } from "@/lib/organizer/dashboard/types";
import { ImageSlot } from "../ui/ImageSlot";
import { Card, FilledButton, IconButton, TextField } from "../ui/Primitives";

/**
 * The venue's food & drinks menu — sections of priced items, each with its own
 * photo, availability nights, and sold-out switch.
 *
 * Unlike event submissions, menu edits skip platform review and reach the app
 * immediately, which is why there is no save/submit step here: every control
 * writes straight to the store.
 */
export function VenueMenuSection() {
  const { profile, editingVenue, addMenuSection } = useOrganizerDashboard();

  const itemCount = profile.menu.reduce((n, s) => n + s.items.length, 0);
  const soldOutCount = profile.menu.reduce(
    (n, s) => n + s.items.filter((i) => i.soldOut).length,
    0
  );

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center gap-3">
        <span
          className="flex h-8 items-center gap-1.5 rounded-lg px-3 text-xs font-medium tracking-[0.5px]"
          style={{ background: "var(--m3-succ)", color: "var(--m3-onsucc)" }}
        >
          <CheckCircle2 size={14} />
          NO REVIEW
        </span>
        <p className="text-[13px] text-[var(--m3-onv)]">
          Menu changes go live as soon as you save — no review needed · prices in{" "}
          {profile.currency} · {itemCount} {itemCount === 1 ? "item" : "items"} · {soldOutCount}{" "}
          sold out
        </p>
      </div>

      {profile.menu.map((section) => (
        <SectionCard key={section.id} section={section} />
      ))}

      {profile.menu.length === 0 && (
        <p className="text-[13px] text-[var(--m3-outline)]">
          No menu yet — add a section to start listing drinks, food, or table packages.
        </p>
      )}

      <FilledButton
        icon={<ListPlus size={18} />}
        onClick={() => addMenuSection(editingVenue)}
        className="self-start"
      >
        Add menu section
      </FilledButton>
    </div>
  );
}

function SectionCard({ section }: { section: MenuSection }) {
  const { editingVenue, setMenuSectionName, removeMenuSection, addMenuItem } =
    useOrganizerDashboard();

  return (
    <Card className="flex flex-col gap-4">
      <div className="flex items-center gap-3">
        <input
          value={section.name}
          onChange={(e) => setMenuSectionName(editingVenue, section.id, e.target.value)}
          aria-label="Section name"
          className="font-display min-w-0 flex-1 border-b border-transparent bg-transparent py-1 text-xl uppercase tracking-wide text-[var(--m3-on)] outline-none focus:border-[var(--m3-pri)]"
        />
        <span className="shrink-0 font-mono text-xs text-[var(--m3-onv)]">
          {section.items.length} {section.items.length === 1 ? "item" : "items"}
        </span>
        <IconButton
          danger
          onClick={() => removeMenuSection(editingVenue, section.id)}
          aria-label={`Remove section ${section.name}`}
        >
          <Trash2 size={18} />
        </IconButton>
      </div>

      {section.items.map((item) => (
        <ItemCard key={item.id} sectionId={section.id} item={item} />
      ))}

      <button
        onClick={() => addMenuItem(editingVenue, section.id)}
        className="flex h-10 items-center justify-center gap-2 rounded-lg border border-dashed border-[var(--m3-outline)] text-[13px] font-medium text-[var(--m3-onv)] transition-colors hover:border-[var(--m3-pri)] hover:text-[var(--m3-pri)]"
      >
        <Plus size={16} />
        Add item to this section
      </button>
    </Card>
  );
}

function ItemCard({ sectionId, item }: { sectionId: string; item: MenuItem }) {
  const {
    profile,
    editingVenue,
    setMenuItemField,
    removeMenuItem,
    toggleMenuItemSoldOut,
    toggleMenuItemTag,
    toggleMenuItemNight,
  } = useOrganizerDashboard();

  const set = <K extends keyof MenuItem>(field: K, value: MenuItem[K]) =>
    setMenuItemField(editingVenue, sectionId, item.id, field, value);

  /** Inline affordances all sit on the same 40px row height as a dense field. */
  const boxed =
    "flex h-10 items-center gap-1.5 rounded border border-[var(--m3-outline)] px-3 focus-within:border-[var(--m3-pri)]";
  const bare = "bg-transparent text-[13px] text-[var(--m3-on)] outline-none";

  return (
    <div
      className="flex gap-4 rounded-xl bg-[var(--m3-surf2)] p-4"
      style={{ opacity: item.soldOut ? 0.55 : 1 }}
    >
      {/* ImageSlot fills its parent, so the size lives on the wrapper. */}
      <div className="h-[76px] w-[76px] shrink-0">
        <ImageSlot
          slotId={menuItemSlotId(editingVenue, item.id)}
          placeholder="Item photo"
          rounded="rounded-[10px]"
          compact
        />
      </div>

      <div className="flex min-w-0 flex-1 flex-col gap-3">
        <div className="flex flex-wrap items-center gap-2">
          <TextField
            dense
            surface="var(--m3-surf2)"
            value={item.name}
            onChange={(e) => set("name", e.target.value)}
            placeholder="Item name"
            aria-label="Item name"
            className="font-medium"
            wrapperClassName="min-w-[160px] flex-[1_1_200px]"
          />
          <div className={`${boxed} shrink-0`}>
            <span className="font-mono text-xs text-[var(--m3-onv)]">{profile.currency}</span>
            <input
              value={item.price}
              onChange={(e) => set("price", Number(e.target.value) || 0)}
              type="number"
              min={0}
              placeholder="0"
              aria-label="Price"
              className={`w-[72px] font-mono ${bare}`}
            />
          </div>
          <button
            onClick={() => toggleMenuItemSoldOut(editingVenue, sectionId, item.id)}
            className="flex h-10 shrink-0 items-center gap-1.5 rounded-lg px-3.5 text-[13px] font-medium transition-opacity hover:opacity-85"
            style={
              item.soldOut
                ? { background: "var(--m3-errc)", color: "var(--m3-onerrc)" }
                : { background: "var(--m3-succ)", color: "var(--m3-onsucc)" }
            }
          >
            {item.soldOut ? <Ban size={15} /> : <CheckCircle2 size={15} />}
            {item.soldOut ? "Sold out" : "Available"}
          </button>
          <IconButton
            danger
            onClick={() => removeMenuItem(editingVenue, sectionId, item.id)}
            aria-label={`Remove ${item.name || "item"}`}
          >
            <X size={18} />
          </IconButton>
        </div>

        <TextField
          dense
          surface="var(--m3-surf2)"
          value={item.desc}
          onChange={(e) => set("desc", e.target.value)}
          placeholder="Short description guests see under the name"
          aria-label="Item description"
        />

        <div className="flex flex-wrap items-center gap-2">
          <div className={boxed}>
            <GlassWater size={15} className="text-[var(--m3-onv)]" />
            <input
              value={item.size}
              onChange={(e) => set("size", e.target.value)}
              placeholder="Size"
              aria-label="Serving size"
              className={`w-[92px] ${bare}`}
            />
          </div>
          <div className={boxed}>
            <Users size={15} className="text-[var(--m3-onv)]" />
            <input
              value={item.serves}
              onChange={(e) => set("serves", e.target.value)}
              placeholder="Serves"
              aria-label="Serves"
              className={`w-14 font-mono ${bare}`}
            />
          </div>
          {MENU_TAGS.map((tag) => {
            const on = item.tags.includes(tag);
            return (
              <button
                key={tag}
                onClick={() => toggleMenuItemTag(editingVenue, sectionId, item.id, tag)}
                aria-pressed={on}
                className="h-8 rounded-lg border px-3.5 text-[13px] font-medium transition-colors"
                style={
                  on
                    ? {
                        background: "var(--m3-terc)",
                        color: "var(--m3-onterc)",
                        borderColor: "transparent",
                      }
                    : { color: "var(--m3-onv)", borderColor: "var(--m3-outline)" }
                }
              >
                {tag}
              </button>
            );
          })}
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <span className="w-[120px] text-xs tracking-[0.5px] text-[var(--m3-onv)]">
            {item.nights.length ? "Selected nights" : "Every night"}
          </span>
          {NIGHT_INITIALS.map((initial, i) => {
            const on = item.nights.includes(i);
            return (
              <button
                key={i}
                onClick={() => toggleMenuItemNight(editingVenue, sectionId, item.id, i)}
                aria-pressed={on}
                aria-label={`Night ${i + 1}`}
                className="flex h-8 w-8 items-center justify-center rounded-full border font-mono text-xs transition-colors"
                style={
                  on
                    ? {
                        background: "var(--m3-pric)",
                        color: "var(--m3-onpric)",
                        borderColor: "transparent",
                      }
                    : { color: "var(--m3-onv)", borderColor: "var(--m3-outline)" }
                }
              >
                {initial}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
