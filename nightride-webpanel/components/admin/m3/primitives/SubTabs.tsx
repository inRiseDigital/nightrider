import { ACCENT, BORDER, TEXT } from "@/lib/admin/tokens";
import { Icon } from "../Icon";
import { Hoverable } from "../Hoverable";

export type SubTab = { id: string; label: string; icon?: string };

/**
 * Underline tab row used inside drawers/detail cards — e.g. Profile/Activity
 * on the user drawer, Events/Review history on the venue detail card.
 */
export function SubTabs({ tabs, activeId, onSelect }: { tabs: SubTab[]; activeId: string; onSelect: (id: string) => void }) {
  return (
    <div style={{ display: "flex", gap: 0, padding: "0 12px", borderBottom: `1px solid ${BORDER.default}`, flexShrink: 0 }}>
      {tabs.map((tab) => {
        const active = tab.id === activeId;
        return (
          <Hoverable
            key={tab.id}
            onClick={() => onSelect(tab.id)}
            style={{
              height: 48,
              display: "flex",
              alignItems: "center",
              gap: 8,
              padding: "0 16px",
              cursor: "pointer",
              fontSize: 14,
              fontWeight: 500,
              color: active ? ACCENT.pink : TEXT.secondary,
              borderBottom: `3px solid ${active ? ACCENT.pink : "transparent"}`,
              borderRadius: "8px 8px 0 0",
              transition: "color 120ms linear",
            }}
            hoverStyle={active ? undefined : { background: "#FFFFFF0A", color: TEXT.primary }}
          >
            {tab.icon ? <Icon name={tab.icon} size={18} /> : null}
            {tab.label}
          </Hoverable>
        );
      })}
    </div>
  );
}
