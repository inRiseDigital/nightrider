import { Icon } from "./Icon";
import { Hoverable } from "./Hoverable";

export function Topbar({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <div
      style={{
        height: 72,
        flexShrink: 0,
        display: "flex",
        alignItems: "center",
        gap: 16,
        padding: "0 24px",
        background: "#141114",
      }}
    >
      <div style={{ minWidth: 0, flex: 1 }}>
        <div
          style={{
            fontSize: 22,
            fontWeight: 400,
            letterSpacing: 0,
            lineHeight: 1.2,
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}
        >
          {title}
        </div>
        <div
          style={{
            fontSize: 13,
            color: "#CFC0C5",
            marginTop: 2,
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}
        >
          {subtitle}
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 8,
            height: 44,
            padding: "0 16px",
            borderRadius: 22,
            background: "#2A252A",
            color: "#CFC0C5",
            fontSize: 14,
            minWidth: 0,
          }}
        >
          <Icon name="search" size={20} />
          <span style={{ whiteSpace: "nowrap" }}>Search console</span>
        </div>
        <Hoverable
          as="button"
          style={{
            width: 44,
            height: 44,
            borderRadius: "50%",
            background: "transparent",
            border: "none",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            position: "relative",
            color: "#CFC0C5",
            cursor: "pointer",
          }}
          hoverStyle={{ background: "#2A252A" }}
        >
          <Icon name="notifications" size={22} />
          <div
            style={{
              position: "absolute",
              top: 10,
              right: 11,
              width: 8,
              height: 8,
              borderRadius: "50%",
              background: "#FFB1C4",
              boxShadow: "0 0 0 2px #141114",
            }}
          />
        </Hoverable>
      </div>
    </div>
  );
}
