import { Hoverable } from "../Hoverable";
import { ACCENT, SURFACE, TEXT } from "@/lib/admin/tokens";
import type { NewAdminDraft } from "@/lib/admin/view-models";

const CITY_OPTIONS = ["All cities", "Dubai", "Tokyo", "London", "Melbourne"];

const inputStyle = {
  flex: 1,
  minWidth: 200,
  height: 48,
  padding: "0 16px",
  borderRadius: 12,
  background: SURFACE.hover,
  border: "none",
  color: TEXT.primary,
  fontSize: 14,
} as const;

/** The inline "Invite a new admin" form shown under the Console access banner when `addAdminOpen` is true. */
export function AddAdminForm({
  draft,
  setDraft,
  onSubmit,
  onCancel,
}: {
  draft: NewAdminDraft;
  setDraft: (draft: Partial<NewAdminDraft>) => void;
  onSubmit: () => void;
  onCancel: () => void;
}) {
  return (
    <div style={{ gridColumn: "1 / -1", background: SURFACE.raised, borderRadius: 16, padding: "20px 24px", display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ fontSize: 15, fontWeight: 500 }}>Invite a new admin</div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
        <input
          value={draft.name}
          onChange={(e) => setDraft({ name: e.target.value })}
          placeholder="Full name"
          style={inputStyle}
        />
        <input
          value={draft.email}
          onChange={(e) => setDraft({ email: e.target.value })}
          placeholder="Work email"
          style={inputStyle}
        />
        <select
          value={draft.cityScope}
          onChange={(e) => setDraft({ cityScope: e.target.value })}
          style={{ height: 48, padding: "0 14px", borderRadius: 12, background: "#141114", border: "1px solid #524549", color: TEXT.primary, fontSize: 14, cursor: "pointer" }}
        >
          {CITY_OPTIONS.map((city) => (
            <option key={city} value={city}>
              {city}
            </option>
          ))}
        </select>
      </div>
      <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
        <Hoverable
          as="button"
          onClick={onSubmit}
          style={{ height: 40, padding: "0 22px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: ACCENT.pink, color: ACCENT.pinkDeep, border: "none", cursor: "pointer" }}
        >
          Send invite
        </Hoverable>
        <Hoverable
          as="button"
          onClick={onCancel}
          style={{ height: 40, padding: "0 18px", borderRadius: 20, fontSize: 14, fontWeight: 500, background: "transparent", color: TEXT.secondary, border: "none", cursor: "pointer" }}
          hoverStyle={{ background: "#FFFFFF14" }}
        >
          Cancel
        </Hoverable>
      </div>
    </div>
  );
}
