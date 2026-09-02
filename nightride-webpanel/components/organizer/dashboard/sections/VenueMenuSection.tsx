"use client";

import { Ban, CheckCircle2, GlassWater, ListPlus, Plus, Trash2, Users, X } from "lucide-react";
import { menuItemSlotId, useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { MENU_TAGS, NIGHT_INITIALS } from "@/lib/organizer/dashboard/constants";
import type { MenuItem, MenuSection } from "@/lib/organizer/dashboard/types";
import { ImageSlot } from "../ui/ImageSlot";

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
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center gap-3">
        <span
          className="flex items-center gap-1.5 rounded-lg px-3 py-1 text-[12px] font-medium tracking-wide"
          style={{ background: "var(--m3-succ)", color: "var(--m3-onsucc)" }}
        >
          <CheckCircle2 size={14} />
          LIVE INSTANTLY
        </span>
        <p className="text-[13px] text-[var(--m3-onv)]">
          Menu edits skip review and update in the app straight away · prices in{" "}
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

      <button
        onClick={() => addMenuSection(editingVenue)}
        className="flex h-11 items-center gap-2 self-start rounded-full px-5 text-sm font-medium transition-opacity hover:opacity-90"
        style={{ background: "var(--m3-pri)", color: "var(--m3-onpri)" }}
      >
        <ListPlus size={18} />
        Add menu section
      </button>
    </div>
  );
}

function SectionCard({ section }: { section: MenuSection }) {
  const { editingVenue, setMenuSectionName, removeMenuSection, addMenuItem } =
    useOrganizerDashboard();

  return (
    <div className="flex flex-col gap-3.5 rounded-2xl bg-[var(--m3-surf1)] p-5">
      <div className="flex items-center gap-3">
        <input
          value={section.name}
          onChange={(e) => setMenuSectionName(editingVenue, section.id, e.target.value)}
          aria-label="Section name"
          className="font-display min-w-0 flex-1 border-b border-transparent bg-transparent py-0.5 text-xl uppercase tracking-wide text-[var(--m3-on)] outline-none focus:border-[var(--m3-pri)]"
        />
        <span className="shrink-0 font-mono text-xs text-[var(--m3-onv)]">
          {section.items.length} {section.items.length === 1 ? "item" : "items"}
        </span>
        <button
          onClick={() => removeMenuSection(editingVenue, section.id)}
          aria-label={`Remove section ${section.name}`}
          className="shrink-0 text-[var(--m3-onv)] transition-colors hover:text-[var(--m3-err)]"
        >
          <Trash2 size={18} />
        </button>
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
    </div>
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

  const boxed =
    "flex items-center gap-1.5 rounded border border-[var(--m3-outline)] px-2.5";
  const bare = "bg-transparent py-2 text-[13px] text-[var(--m3-on)] outline-none";

  return (
    <div
      className="flex gap-3.5 rounded-xl bg-[var(--m3-surf2)] p-3.5"
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

      <div className="flex min-w-0 flex-1 flex-col gap-2.5">
        <div className="flex flex-wrap items-start gap-2.5">
          <input
            value={item.name}
            onChange={(e) => set("name", e.target.value)}
            placeholder="Item name"
            aria-label="Item name"
            className="min-w-[160px] flex-[1_1_200px] rounded border border-[var(--m3-outline)] bg-transparent px-2.5 py-2 text-[15px] font-medium text-[var(--m3-on)] outline-none focus:border-[var(--m3-pri)]"
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
              className={`w-[72px] font-mono text-[15px] ${bare}`}
            />
          </div>
          <button
            onClick={() => toggleMenuItemSoldOut(editingVenue, sectionId, item.id)}
            className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg px-3 text-[13px] font-medium transition-opacity hover:opacity-85"
            style={
              item.soldOut
                ? { background: "var(--m3-errc)", color: "var(--m3-onerrc)" }
                : { background: "var(--m3-succ)", color: "var(--m3-onsucc)" }
            }
          >
            {item.soldOut ? <Ban size={15} /> : <CheckCircle2 size={15} />}
            {item.soldOut ? "Sold out" : "Available"}
          </button>
          <button
            onClick={() => removeMenuItem(editingVenue, sectionId, item.id)}
            aria-label={`Remove ${item.name || "item"}`}
            className="shrink-0 self-center text-[var(--m3-onv)] transition-colors hover:text-[var(--m3-err)]"
          >
            <X size={18} />
          </button>
        </div>

        <input
          value={item.desc}
          onChange={(e) => set("desc", e.target.value)}
          placeholder="Short description guests see under the name"
          aria-label="Item description"
          className="w-full rounded border border-[var(--m3-outline)] bg-transparent px-2.5 py-2 text-[13px] text-[var(--m3-onv)] outline-none focus:border-[var(--m3-pri)] focus:text-[var(--m3-on)]"
        />

        <div className="flex flex-wrap items-center gap-2.5">
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
                className="h-[30px] rounded-lg border px-3 text-xs font-medium transition-colors"
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
          <span className="w-[120px] text-xs tracking-wide text-[var(--m3-onv)]">
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
                className="flex h-[30px] w-[30px] items-center justify-center rounded-full border font-mono text-xs transition-colors"
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
